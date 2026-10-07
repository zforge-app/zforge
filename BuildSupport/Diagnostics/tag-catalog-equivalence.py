#!/usr/bin/env python3
"""Compare native baseline/current catalogs with an independent filesystem oracle."""
import argparse
import ctypes
import datetime
import hashlib
import json
import os
import pathlib
import plistlib
import random
import selectors
import shutil
import stat
import subprocess
import sys

ATTRIBUTE = "com.apple.metadata:_kMDItemUserTags"
HIDDEN = stat.UF_HIDDEN
LIBC = ctypes.CDLL("/usr/lib/libSystem.B.dylib", use_errno=True)
XATTR_ARGUMENTS = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint32, ctypes.c_int]
LIBC.setxattr.argtypes = XATTR_ARGUMENTS
LIBC.setxattr.restype = ctypes.c_int
LIBC.getxattr.argtypes = XATTR_ARGUMENTS
LIBC.getxattr.restype = ctypes.c_ssize_t


def xattr(path, data=None):
    arguments = [os.fsencode(path), ATTRIBUTE.encode()]
    if data is not None:
        buffer = ctypes.create_string_buffer(data)
        value = LIBC.setxattr(*arguments, buffer, len(data), 0, 0)
        if value != 0:
            raise OSError(ctypes.get_errno(), "Fixture xattr write failed", str(path))
        return
    size = LIBC.getxattr(*arguments, None, 0, 0, 0)
    if size < 0:
        raise OSError(ctypes.get_errno(), "Oracle xattr read failed", str(path))
    buffer = ctypes.create_string_buffer(size)
    count = LIBC.getxattr(*arguments, buffer, size, 0, 0)
    if count < 0:
        raise OSError(ctypes.get_errno(), "Oracle xattr read failed", str(path))
    return buffer.raw[:count]


def tags(path, values):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_bytes(b"Equivalence fixture")
    encoded = [name + ("\n" + str(color) if color else "") for name, color in values.items()]
    xattr(path, plistlib.dumps(encoded, fmt=plistlib.FMT_BINARY))


def oracle(root, grants):
    """Read plist xattrs via Python/POSIX; no production scanner/policy imports."""
    records = {}

    def visit(path):
        info = path.lstat()
        if path.name.startswith(".") or info.st_flags & HIDDEN:
            return
        try:
            raw = xattr(path)
        except OSError as error:
            # Missing xattr is untagged; any other read error invalidates oracle.
            import errno
            if error.errno != errno.ENOATTR:
                raise
        else:
            decoded = {}
            for value in plistlib.loads(raw):
                name, separator, suffix = value.rpartition("\n")
                if separator and suffix.isdecimal() and 0 <= int(suffix) <= 7:
                    decoded[name] = int(suffix)
                else:
                    decoded[value] = 0
            if decoded:
                records[str(path.relative_to(root))] = decoded
        # Fixture package extensions are known in advance, independent of the
        # production URL resource reader. Include their tags, exclude contents.
        if stat.S_ISDIR(info.st_mode) and path.suffix not in {".app", ".bundle"}:
            for child in sorted(path.iterdir()):
                visit(child)

    for grant in grants:
        visit(root / grant)
    return records


class Worker:
    def __init__(self, executable, root, checkpoint, log):
        self.log = log.open("w")
        self.process = subprocess.Popen([str(executable), str(root), str(checkpoint)],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=self.log, text=True, bufsize=1)
        self.selector = selectors.DefaultSelector()
        self.selector.register(self.process.stdout, selectors.EVENT_READ)

    def command(self, operation, **kwargs):
        request = dict(operation=operation, grants=[], markers=[], expected={})
        request.update(kwargs)
        self.process.stdin.write(json.dumps(request) + "\n")
        self.process.stdin.flush()
        if not self.selector.select(timeout=15):
            raise RuntimeError(f"Worker failed to complete {operation}; inspect native stderr log")
        line = self.process.stdout.readline()
        if not line:
            raise RuntimeError(f"Worker exited during {operation}; inspect native stderr log")
        return json.loads(line)

    def close(self):
        if self.process.poll() is None:
            self.process.stdin.close()
            try:
                self.process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        self.selector.close()
        self.log.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--baseline-ref", default="fd1bacc")
    parser.add_argument("--reuse-builds", type=pathlib.Path, help="Reuse compiler outputs only after verifying all source/harness hashes")
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        parser.error("Use a fresh output directory")
    output.mkdir(parents=True)
    repo = pathlib.Path(__file__).resolve().parents[2]
    fixture = pathlib.Path(os.environ["TMPDIR"]) / ("ZforgeEquivalence-" + output.name)
    if fixture.exists():
        parser.error("Fixture already exists; use a fresh output directory name")
    fixture.mkdir()
    build_recipe = repo / "BuildSupport/Diagnostics/tag-index-scale-benchmark.py"
    harness = repo / "BuildSupport/Diagnostics/TagCatalogEquivalence.swift"
    provenance = {}
    for variant in ["baseline", "combined"]:
        command = [sys.executable, str(build_recipe), "--configuration", "Release", "--compile-only",
            "--harness-file", str(harness), "--fixture", str(fixture), "--output", str(output / variant)]
        if variant == "baseline":
            command += ["--source-ref", args.baseline_ref, "--source-override", "Zforge/Services/TagJournal.swift"]
        if args.reuse_builds:
            origin = args.reuse_builds / variant
            manifest = json.loads((origin / "build.json").read_text())
            expected_ref = subprocess.check_output(["git", "rev-parse", args.baseline_ref + "^{commit}"], cwd=repo, text=True).strip() if variant == "baseline" else None
            assert manifest["source_commit"] == expected_ref and manifest["configuration"] == "Release"
            assert manifest.get("source_overrides", []) == (["Zforge/Services/TagJournal.swift"] if variant == "baseline" else [])
            assert manifest["diagnostic_harness_sha256"] == hashlib.sha256(harness.read_bytes()).hexdigest()
            assert manifest["harness_sha256"] == hashlib.sha256((origin / "measure.swift").read_bytes()).hexdigest()
            for name, digest in manifest["source_sha256"].items():
                data = subprocess.check_output(["git", "show", expected_ref + ":" + name], cwd=repo) if expected_ref and name not in manifest["source_overrides"] else (repo / name).read_bytes()
                assert hashlib.sha256(data).hexdigest() == digest, name
            destination = output / variant
            destination.mkdir()
            shutil.copy2(origin / "measure", destination / "measure")
            manifest["binary_sha256"] = hashlib.sha256((destination / "measure").read_bytes()).hexdigest()
            manifest["reused_from"] = str(origin)
            (destination / "build.json").write_text(json.dumps(manifest, indent=2) + "\n")
        else:
            with (output / (variant + "-compile.log")).open("w") as log:
                subprocess.run(command, check=True, stdout=log, stderr=log)
        provenance[variant] = json.loads((output / variant / "build.json").read_text())
    for directory in ["A", "B", "External", "AB", "A/.hidden", "B/flagged", "B/Fixture.app"]:
        (fixture / directory).mkdir(parents=True, exist_ok=True)
    for path, value in {
        "A/first.txt": {"EQ Shared": 6, "EQ Plain": 0},
        "B/second.txt": {"EQ Shared": 4},
        "A/clear.txt": {"EQ Clear": 2},
        "A/delete.txt": {"EQ Delete": 5},
        "A/.hidden/child.txt": {"EQ Excluded": 6},
        "B/flagged/\u0301child.txt": {"EQ Excluded": 6},
        "B/Fixture.app/child.txt": {"EQ Excluded": 6},
        "B/Fixture.app": {"EQ Package": 1},
        "A/\u0301accent.txt": {"EQ Unicode": 3},
        "B/line\nbreak.txt": {"EQ Long": 7},
        "B/" + "long-" + "x" * 180 + ".txt": {"EQ Long": 7},
        "External/target.txt": {"EQ Link": 6},
        "AB/outside.txt": {"EQ Outside": 6},
    }.items():
        tags(fixture / path, value)
    os.chflags(fixture / "B/flagged", HIDDEN)
    os.symlink(fixture / "External/target.txt", fixture / "A/symbolic.txt")
    os.link(fixture / "External/target.txt", fixture / "B/hard.txt")
    workers = {v: Worker(output / v / "measure", fixture, output / v / "checkpoint.json",
                        output / (v + "-native.log")) for v in provenance}
    result = dict(started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
        configuration="Release", baseline_ref=args.baseline_ref, provenance=provenance,
        coordinator_sha256=hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest(),
        oracle="Independent Python POSIX traversal and plist xattr decoding",
        shared_reference_repair="Physical event mapping in TagJournal.swift is identical in both builds; original immutable baseline failures are retained separately",
        baseline_known_contract_violation=dict(path="A/\u0301accent.txt",
            reason="Immutable baseline excludes a visible leading combining filename at its scope boundary; current must retain it"),
        passed=False, checkpoints=[], mutations=[])
    grants = ["A", "B"]
    fence_number = 0

    def save():
        (output / "results.json").write_text(json.dumps(result, indent=2) + "\n")

    def both(operation, **kwargs):
        return {v: w.command(operation, **kwargs) for v, w in workers.items()}

    def fence_begin():
        both("fence_start")

    def fence_end():
        nonlocal fence_number
        fence_number += 1
        markers = [f"{scope}/.fence-{fence_number}" for scope in ["A", "B"]]
        for marker in markers:
            (fixture / marker).write_bytes(b"Native journal fence")
        both("fence_finish", markers=markers)

    def validate(stage, responses, cancellation=False):
        expected = oracle(fixture, grants)

        def publication(records):
            published = {}
            palette = {}
            for path, values in records.items():
                for name, color in values.items():
                    published.setdefault(name, []).append(path)
                    palette.setdefault(name, set()).add(color)
            published = {name: sorted(paths) for name, paths in published.items()}
            colors = {name: min(values - {0}) if values - {0} else 0 for name, values in palette.items()}
            return published, colors

        # This exact legacy failure was observed before the fix and is retained
        # as an explicit exception. Never remove it from the current oracle or
        # allow arbitrary differences to satisfy baseline comparison.
        legacy = {path: values for path, values in expected.items() if path != "A/\u0301accent.txt"}
        expected_by_variant = {"baseline": legacy, "combined": expected}
        row = dict(stage=stage, expected=expected, responses=responses, full_rescans={})
        result["checkpoints"].append(row)
        save()  # Preserve failing results before assertions, without retries.
        for variant, response in responses.items():
            wanted = expected_by_variant[variant]
            published, colors = publication(wanted)
            assert response["idle"], (stage, variant, "Catalog not drained")
            if stage in {"quiet_reopen", "external_link_color_edit", "external_link_clear"}:
                assert response["counts"]["scans"] == 0, (stage, variant, "Unnecessary recursive scan")
            if stage == "invalid_obsolete_generation" and variant == "combined":
                assert response["counts"]["scans"] >= 1, "Obsolete checkpoint was reused instead of rebuilt"
            assert response["published"] == published, (stage, variant, "Published results", response["published"], published)
            assert response["colors"] == colors, (stage, variant, "Published colors")
            if cancellation:
                assert response["counts"]["maximum_active"] == 1
                assert response["counts"]["scans"] == 2
            else:
                assert response["records"] == wanted, (stage, variant, "Persisted records", response["records"], wanted)
                assert response["complete"] is True
        scans = both("scan")
        row["full_rescans"] = {v: r["scan"] for v, r in scans.items()}
        for variant, response in scans.items():
            assert response["scan"] == expected, (stage, variant, "Full rescan oracle")
        assert publication(legacy)[0] == responses["baseline"]["published"]
        assert publication(expected)[0] == responses["combined"]["published"]
        row["baseline_oracle_violation"] = {path: values for path, values in expected.items() if path not in legacy}
        row["passed"] = True
        save()
        print(json.dumps(dict(stage=stage, passed=True, records=len(expected))), flush=True)

    def offline(stage, mutation):
        both("stop")
        fence_begin()
        mutation()
        fence_end()
        validate(stage, both("start", grants=grants))

    def live(stage, mutation, dropped=False):
        mutation()
        responses = both("dropped") if dropped else both("sync", expected=oracle(fixture, grants))
        validate(stage, responses)

    try:
        # Native observer fences initial filesystem writes before cold startup.
        fence_begin(); fence_end()
        validate("cold_complete", both("start", grants=grants))
        offline("quiet_reopen", lambda: None)
        # External-link target changes are invisible to lexical watched paths.
        offline("external_link_color_edit", lambda: tags(fixture / "External/target.txt", {"EQ Link Updated": 4, "EQ Plain": 0}))
        offline("external_link_clear", lambda: tags(fixture / "External/target.txt", {}))

        def offline_edits():
            tags(fixture / "A/first.txt", {"EQ Offline": 2, "EQ Plain": 0})
            (fixture / "A/first.txt").rename(fixture / "B/moved.txt")
            (fixture / "A/delete.txt").unlink()
            tags(fixture / "A/clear.txt", {})
            tags(fixture / "A/New/child.txt", {"EQ Added": 5})
            tags(fixture / "A/New", {"EQ Folder": 7})
        offline("offline_edit_move_delete_add_clear", offline_edits)
        offline("unhide_flagged_ancestor", lambda: os.chflags(fixture / "B/flagged", 0))
        offline("hide_flagged_ancestor", lambda: os.chflags(fixture / "B/flagged", HIDDEN))
        offline("hidden_directory_becomes_visible", lambda: (fixture / "A/.hidden").rename(fixture / "A/Revealed"))
        live("live_colors_and_tag_removal", lambda: tags(fixture / "B/second.txt", {"EQ Live": 1}))
        live("live_hidden_root", lambda: os.chflags(fixture / "A", HIDDEN))
        live("live_visible_root", lambda: os.chflags(fixture / "A", 0))
        live("dropped_history_reconciliation", lambda: tags(fixture / "A/Revealed/child.txt", {"EQ Recovery": 6}), dropped=True)

        both("stop")
        grants = ["B"]
        validate("staged_shared_only", both("start", grants=grants))
        grants = ["A", "B"]
        validate("staged_add_home", both("grant", grants=["A"]))
        both("stop")
        grants = ["B"]
        validate("staged_quit_shared_only", both("start", grants=grants))
        both("stop")
        validate("staged_quit_reopen_shared_only", both("start", grants=grants))
        grants = ["A", "B"]
        validate("staged_quit_add_home", both("grant", grants=["A"]))

        for reason in ["schema", "inode", "journal", "future_cursor", "missing_cursor", "corrupt", "obsolete_generation"]:
            def invalidate(reason=reason):
                for variant in workers:
                    path = output / variant / "checkpoint.json"
                    if reason == "corrupt":
                        path.write_text("Invalid checkpoint fixture")
                        continue
                    snapshot = json.loads(path.read_text())
                    if reason == "obsolete_generation":
                        snapshot["version"] = 3
                        if variant == "combined":
                            # Old software can have persisted an incomplete map
                            # as complete. No new filesystem event repairs this.
                            snapshot["records"] = {}
                    elif reason == "schema": snapshot["version"] = 0
                    elif reason == "inode": snapshot["scopes"][0]["inode"] += 1
                    elif reason == "journal": snapshot["scopes"][0]["journal"] = "Invalidated Journal"
                    elif reason == "future_cursor": snapshot["cursors"] = {key: 2**64 - 2 for key in snapshot["cursors"]}
                    elif reason == "missing_cursor": snapshot["cursors"] = {}
                    path.write_text(json.dumps(snapshot))
            offline("invalid_" + reason, invalidate)

        # An obsolete cache must not silently become reusable for an ungranted
        # scope when another scope is rebuilt and saved under the new version.
        both("stop")
        path = output / "combined" / "checkpoint.json"
        snapshot = json.loads(path.read_text())
        snapshot["version"] = 3
        snapshot["records"] = {}
        path.write_text(json.dumps(snapshot))
        grants = ["B"]
        validate("obsolete_staged_shared_only", both("start", grants=grants))
        mixed = json.loads(path.read_text())
        assert mixed["version"] == 4
        assert all(scope["path"].endswith("/B") for scope in mixed["scopes"]), "Obsolete ungranted scope was upgraded as reusable"
        both("stop")
        validate("obsolete_staged_quit_shared_only", both("start", grants=grants))
        grants = ["A", "B"]
        validate("obsolete_staged_later_home", both("grant", grants=["A"]))
        assert result["checkpoints"][-1]["responses"]["combined"]["counts"]["scans"] >= 1

        # Bounded deterministic property traces; every step checks readiness,
        # exact persistence/publication and both fresh production rescans.
        for seed in [7, 19, 43, 101]:
            rng = random.Random(seed)
            for step in range(12):
                slot = rng.randrange(8)
                operation = rng.choice(["set", "clear", "delete", "move", "visibility"])
                scope = rng.choice(["A", "B"])
                path = fixture / scope / f"trace-{slot}.txt"
                values = {f"EQ Trace {rng.randrange(5)}": rng.randrange(8), "EQ Shared": rng.randrange(8)}
                hidden = bool(rng.randrange(2)) if operation == "visibility" else None
                change = dict(seed=seed, step=step, operation=operation, path=str(path.relative_to(fixture)), values=values,
                              hidden=hidden, delivery="offline" if step % 2 == 0 else "live")
                result["mutations"].append(change)

                def mutate():
                    if operation in {"set", "clear", "visibility"}:
                        tags(path, values if operation != "clear" else {})
                        if operation == "visibility": os.chflags(path, HIDDEN if hidden else 0)
                    elif operation == "delete":
                        if path.exists(): path.unlink()
                    else:
                        destination = fixture / ("B" if scope == "A" else "A") / path.name
                        if path.exists():
                            if destination.exists(): destination.unlink()
                            path.rename(destination)
                stage = f"trace_{seed}_{step}_{operation}"
                (offline if step % 2 == 0 else live)(stage, mutate)
        validate("cancel_restart_generation", both("cancel_restart"), cancellation=True)
        result["passed"] = True
        result["completed_utc"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
        result["verified_checkpoints"] = len(result["checkpoints"])
        save()
    except Exception as error:
        result["failure"] = str(error)
        save()
        raise
    finally:
        for worker in workers.values(): worker.close()
    print(json.dumps(dict(passed=True, checkpoints=len(result["checkpoints"]), native_catalog_comparisons=2 * len(result["checkpoints"]))), flush=True)


if __name__ == "__main__":
    main()
