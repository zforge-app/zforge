#!/usr/bin/env python3
"""Blocks a commit whose content builds with warnings (RNF-Q07).

Builds exactly what the commit will contain (the git index, not the working
tree) with `xcodebuild build-for-testing` on the Zforge scheme, Debug: the app,
the Finder extension, the unit tests and the UI tests. Any warning or error
blocks the commit. Warnings located in third-party Swift packages
(SourcePackages) are listed but do not block.

The index is mirrored into a private copy in the checkout's git directory
(`<git dir>/zforge-warning-gate/src`, one per worktree, removed with the
worktree) that only receives the files that changed since the previous check,
so the build stays incremental: the first check builds from scratch (a few
minutes), later checks rebuild what changed. An incremental build does not
repeat the warnings of files it does not recompile, so after a check that
finds a problem, the files it named are marked as changed (or, for a warning
without a source location, the build products are discarded): a file reused
from the cache has always compiled without warnings.

Installed by `git config core.hooksPath .githooks` (shared by every worktree of
the clone): `.githooks/pre-commit` and `.githooks/pre-merge-commit` run this
script with --hook, which skips commits that only touch Markdown files or
`Documentation/`.

Usage:
  Scripts/check-warnings.py           # check the index (what the next commit contains)
  Scripts/check-warnings.py --hook    # as the git hooks run it
  Scripts/check-warnings.py --clean   # discard the cached build first
"""
import argparse
import fcntl
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

GATE_DIR_NAME = "zforge-warning-gate"
THIRD_PARTY_MARKER = "/SourcePackages/"
WARNING = re.compile(r"^(?:(?P<file>/[^:]+?):(?P<line>\d+)(?::(?P<column>\d+))?: )?(?:\S+: )?warning: (?P<message>.+)$")
ERROR = re.compile(r"(?:^|: )error: ")


def git(*args, cwd, capture=True):
    return subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=capture).stdout


def needs_build(paths):
    """Whether a commit touching these paths can change the build's diagnostics."""
    return any(not (path.endswith(".md") or path.startswith("Documentation/")) for path in paths)


def staged_paths(root):
    has_head = subprocess.run(["git", "rev-parse", "--verify", "-q", "HEAD"], cwd=root,
                              capture_output=True).returncode == 0
    args = ["diff", "--cached", "--name-only", "-z", "HEAD"] if has_head else ["ls-files", "-z"]
    return [p for p in git(*args, cwd=root).decode().split("\0") if p]


def index_entries(root):
    """Stage-0 index entries as {path: [mode, blob]}; gitlinks are skipped."""
    entries = {}
    for record in git("ls-files", "-s", "-z", cwd=root).decode().split("\0"):
        if not record:
            continue
        meta, path = record.split("\t", 1)
        mode, blob, stage = meta.split()
        if stage == "0" and mode != "160000":
            entries[path] = [mode, blob]
    return entries


def sync_mirror(root, entries, mirror, manifest_path):
    """Writes into `mirror` the index entries that differ from the previous sync and removes the
    paths that left the index. Unchanged files keep their modification dates, which keeps the
    build incremental. Returns the number of written and removed paths."""
    try:
        previous = json.loads(manifest_path.read_text())
    except (OSError, ValueError):
        previous = {}
    changed = sorted(path for path, entry in entries.items()
                     if previous.get(path) != entry or not os.path.lexists(mirror / path))
    removed = sorted(set(previous) - set(entries))
    for path in removed:
        target = mirror / path
        if target.is_symlink() or target.is_file():
            target.unlink()
        parent = target.parent
        while parent != mirror and parent.is_dir() and not any(parent.iterdir()):
            parent.rmdir()
            parent = parent.parent
    if changed:
        process = subprocess.Popen(["git", "cat-file", "--batch"], cwd=root,
                                   stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        process.stdin.write("".join(entries[path][1] + "\n" for path in changed).encode())
        process.stdin.close()
        for path in changed:
            header = process.stdout.readline().split()
            size = int(header[2])
            data = process.stdout.read(size)
            process.stdout.read(1)  # The newline after each object.
            write_entry(mirror / path, entries[path][0], data)
        if process.wait() != 0:
            raise RuntimeError("git cat-file failed")
    manifest_path.write_text(json.dumps(entries))
    return len(changed), len(removed)


def write_entry(target, mode, data):
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_symlink() or target.is_file():
        target.unlink()
    elif target.is_dir():
        shutil.rmtree(target)
    if mode == "120000":
        target.symlink_to(data.decode())
        return
    target.write_bytes(data)
    target.chmod(0o755 if mode == "100755" else 0o644)


def parse_diagnostics(output, mirror):
    """Splits the build output into blocking warnings, third-party warnings and errors, each
    deduplicated in order of appearance. Paths inside the mirror become repository-relative."""
    prefix = str(mirror) + "/"
    blocking, third_party, errors = {}, {}, {}
    for line in output.splitlines():
        match = WARNING.match(line)
        if match:
            text = line.replace(prefix, "")
            file = match.group("file")
            if file and THIRD_PARTY_MARKER in file:
                third_party.setdefault(text, None)
            else:
                relative = file[len(prefix):] if file and file.startswith(prefix) else None
                blocking.setdefault(text, relative)
        elif ERROR.search(line):
            errors.setdefault(line.replace(prefix, ""), None)
    return blocking, list(third_party), list(errors)


def build(mirror, derived_data, log_path):
    env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
    command = ["xcodebuild", "build-for-testing", "-project", str(mirror / "Zforge.xcodeproj"),
               "-scheme", "Zforge", "-configuration", "Debug", "-destination", "platform=macOS",
               "-derivedDataPath", str(derived_data), "-skipPackagePluginValidation",
               "-skipMacroValidation", "COMPILER_INDEX_STORE_ENABLE=NO"]
    with open(log_path, "w") as log:
        status = subprocess.run(command, cwd=mirror, env=env, stdout=log, stderr=subprocess.STDOUT).returncode
    return status, log_path.read_text(errors="replace")


def invalidate(mirror, derived_data, blocking):
    """Keeps a cached build from hiding the diagnostics found: files with a located warning are
    marked as changed; a warning without a source file discards the build products."""
    if any(relative is None for relative in blocking.values()):
        shutil.rmtree(derived_data / "Build", ignore_errors=True)
        return
    now = time.time()
    for relative in blocking.values():
        target = mirror / relative
        if target.is_file():
            os.utime(target, (now, now))


def check(root, gate, clean):
    mirror, derived_data = gate / "src", gate / "DerivedData"
    mirror.mkdir(parents=True, exist_ok=True)
    if clean:
        shutil.rmtree(derived_data, ignore_errors=True)
    entries = index_entries(root)
    started = time.monotonic()
    written, removed = sync_mirror(root, entries, mirror, gate / "manifest.json")
    first = not (derived_data / "Build").exists()
    print(f"warning gate: building the staged snapshot ({written} files updated, {removed} removed"
          f"{'; first build, a few minutes' if first else ''})...", flush=True)
    status, output = build(mirror, derived_data, gate / "build.log")
    blocking, third_party, errors = parse_diagnostics(output, mirror)
    elapsed = time.monotonic() - started
    for line in third_party:
        print(f"  (third-party, not blocking) {line}")
    if status == 0 and not blocking and not errors:
        print(f"warning gate: no warnings ({elapsed:.0f} s).")
        return 0
    invalidate(mirror, derived_data, blocking)
    for line in errors:
        print(f"  {line}")
    for line in blocking:
        print(f"  {line}")
    if status != 0 and not errors:
        print(f"  xcodebuild exited with status {status}; see the log.")
    problems = []
    if blocking:
        problems.append(f"{len(blocking)} warning{'s' if len(blocking) != 1 else ''}")
    if status != 0:
        problems.append("a failed build")
    print(f"warning gate: commit blocked by {' and '.join(problems)} ({elapsed:.0f} s). "
          f"Fix them and stage the fix (RNF-Q07). Full log: {gate / 'build.log'}")
    return 1


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--hook", action="store_true", help="skip commits that only touch documentation")
    parser.add_argument("--clean", action="store_true", help="discard the cached build before checking")
    args = parser.parse_args()
    root = Path(git("rev-parse", "--show-toplevel", cwd=os.getcwd()).decode().strip())
    if args.hook and not needs_build(staged_paths(root)):
        print("warning gate: documentation-only commit, build skipped.")
        return 0
    gate = Path(git("rev-parse", "--path-format=absolute", "--git-path", GATE_DIR_NAME, cwd=root).decode().strip())
    gate.mkdir(parents=True, exist_ok=True)
    with open(gate / "lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        return check(root, gate, args.clean)


if __name__ == "__main__":
    sys.exit(main())
