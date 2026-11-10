#!/usr/bin/env python3
"""Imports an official 7-Zip release into `Vendor/7zip` and records its provenance.

Zforge links 7-Zip statically from a vendored snapshot of the official sources
(`BuildSupport/SevenZip/README.md`). The snapshot stays in the repository so each
Zforge revision carries the exact engine source it builds, as LGPL distribution
requires, and builds without network access. This script is the only way the
snapshot changes:

    Scripts/update-7zip.py 26.06      import a release tag
    Scripts/update-7zip.py --latest   import the newest release tag
    Scripts/update-7zip.py --status   compare the vendored version with upstream
    Scripts/update-7zip.py --verify   check the snapshot against its provenance

An import fetches the tag from the upstream repository recorded in
`Vendor/7zip-provenance.json` (or from `--source`, a local clone), takes the
`snapshot_paths` with `git archive`, applies the patches listed in the
provenance from `Vendor/7zip-patches/` in order, replaces `Vendor/7zip`,
regenerates `BuildSupport/SevenZip/inputs.xcfilelist`, and records the version,
revision, archive checksum and the matching macOS `7zz` release asset
(`Scripts/fetch-7zz.py`). It then reports the files added and removed, license
files that changed, and the upstream history entries since the previous version.

Commit an update on its own, without behavior changes, and validate it as
`Documentation/Requirements/PRODUCT-REQUIREMENTS.md` describes (engine updates).
"""
from __future__ import annotations

import argparse
import filecmp
import hashlib
import importlib.util
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VENDOR = REPO / "Vendor"
SNAPSHOT = VENDOR / "7zip"
PATCHES = VENDOR / "7zip-patches"
PROVENANCE = VENDOR / "7zip-provenance.json"
INPUTS = REPO / "BuildSupport" / "SevenZip" / "inputs.xcfilelist"
# Build files whose changes must also rebuild the engine, listed after the snapshot.
BUILD_INPUTS = ["BuildSupport/SevenZip/build.sh", "BuildSupport/SevenZip/static.mk"]
LICENSE_FILES = ["DOC/License.txt", "DOC/copying.txt", "DOC/unRarLicense.txt"]
HISTORY_FILE = "DOC/src-history.txt"
VERSION = re.compile(r"\d+\.\d+")

_spec = importlib.util.spec_from_file_location("fetch_7zz", Path(__file__).with_name("fetch-7zz.py"))
fetch_7zz = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(fetch_7zz)


class UpdateError(Exception):
    pass


# Pure helpers ----------------------------------------------------------------

def version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def latest_version(tags: list[str]) -> str | None:
    """The highest `major.minor` tag; other tag names are ignored."""
    versions = [tag for tag in tags if VERSION.fullmatch(tag)]
    return max(versions, key=version_key) if versions else None


def tags_from_ls_remote(output: str) -> list[str]:
    tags = []
    for line in output.splitlines():
        ref = line.split("\t")[-1]
        if ref.startswith("refs/tags/") and not ref.endswith("^{}"):
            tags.append(ref[len("refs/tags/"):])
    return tags


def snapshot_files(root: Path) -> list[str]:
    """Every file under `root`, relative and in byte order (as `LC_ALL=C sort`)."""
    return sorted((path.relative_to(root).as_posix() for path in root.rglob("*") if path.is_file()),
                  key=lambda name: name.encode())


def xcfilelist(files: list[str]) -> str:
    """The build phase's input list: the snapshot's files, then the build files."""
    lines = [f"$(SRCROOT)/Vendor/7zip/{name}" for name in files]
    lines += [f"$(SRCROOT)/{name}" for name in BUILD_INPUTS]
    return "\n".join(lines) + "\n"


def history_since(history: str, previous: str) -> str:
    """The entries of `DOC/src-history.txt` newer than `previous`, newest first."""
    entries = re.split(r"\n(?=\d+\.\d+\s+\d{4}-\d{2}-\d{2}\n-+\n)", history)
    newer = []
    for entry in entries:
        match = re.match(r"(\d+\.\d+)\s+\d{4}-\d{2}-\d{2}\n-+\n", entry)
        if match and version_key(match.group(1)) > version_key(previous):
            newer.append(entry.strip())
    return "\n\n".join(newer)


def safe_members(tar: tarfile.TarFile, roots: list[str]) -> list[tarfile.TarInfo]:
    """Regular files and directories inside the snapshot paths; anything else is rejected."""
    members = []
    for member in tar.getmembers():
        path = Path(member.name)
        if path.is_absolute() or ".." in path.parts or path.parts[0] not in roots:
            raise UpdateError(f"unexpected path in the upstream archive: {member.name}")
        if not (member.isfile() or member.isdir()):
            raise UpdateError(f"unexpected non-regular file in the upstream archive: {member.name}")
        members.append(member)
    return members


# Git and filesystem ------------------------------------------------------------

def git(*args: str, cwd: Path, binary: bool = False):
    result = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=not binary)
    if result.returncode != 0:
        error = result.stderr if not binary else result.stderr.decode(errors="replace")
        raise UpdateError(f"git {' '.join(args)} failed: {error.strip()}")
    return result.stdout


def remote_tags(source: str) -> list[str]:
    return tags_from_ls_remote(git("ls-remote", "--tags", source, cwd=REPO))


def fetch_archive(source: str, version: str, paths: list[str], work: Path) -> tuple[str, bytes]:
    """Fetches tag `version` from `source` into a scratch repository; returns (revision, tar)."""
    clone = work / "upstream"
    clone.mkdir()
    git("init", "-q", cwd=clone)
    git("fetch", "-q", "--depth", "1", "--no-tags", source,
        f"refs/tags/{version}:refs/tags/{version}", cwd=clone)
    revision = git("rev-parse", f"refs/tags/{version}^{{commit}}", cwd=clone).strip()
    # Upstream attributes would rewrite the export (26.03 added `*.dsp text eol=crlf`, and
    # export-ignore or export-subst could drop or edit files). The scratch repository's
    # info/attributes outranks the archived tree's .gitattributes, so the archive keeps the
    # committed blobs byte for byte and the snapshot and its checksum follow the repository.
    (clone / ".git" / "info").mkdir(parents=True, exist_ok=True)
    (clone / ".git" / "info" / "attributes").write_text(
        "* -text -eol -crlf -ident -filter -export-ignore -export-subst\n")
    archive = git("archive", "--format=tar", revision, *paths, cwd=clone, binary=True)
    return revision, archive


def build_snapshot(archive: bytes, paths: list[str], patches: list[str], target: Path) -> None:
    target.mkdir()
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:") as tar:
        tar.extractall(target, members=safe_members(tar, paths))
    # The archive carries the upstream commit time, which is older than objects already built
    # from the previous snapshot; make would then keep linking those stale objects against the
    # new headers. Stamp the files with the import time, as a Git checkout would.
    for path in target.rglob("*"):
        os.utime(path)
    for patch in patches:
        patch_file = PATCHES / patch
        if not patch_file.is_file():
            raise UpdateError(f"patch listed in the provenance is missing: Vendor/7zip-patches/{patch}")
        git("apply", "-p1", "--whitespace=nowarn", str(patch_file), cwd=target)


def differing_files(left: Path, right: Path) -> list[str]:
    """Paths that are missing on one side or whose bytes differ."""
    left_files, right_files = set(snapshot_files(left)), set(snapshot_files(right))
    differ = sorted(left_files ^ right_files)
    for name in sorted(left_files & right_files):
        if not filecmp.cmp(left / name, right / name, shallow=False):
            differ.append(name)
    return differ


def reference_cli(repository: str, version: str) -> dict:
    """Downloads the version's macOS release asset and records its URL and checksum."""
    url = fetch_7zz.release_asset_url(repository, version)
    digest = fetch_7zz.sha256(fetch_7zz.download(url))
    return {"url": url, "sha256": digest}


# Commands ----------------------------------------------------------------------

def load_provenance() -> dict:
    return json.loads(PROVENANCE.read_text())


def write_provenance(provenance: dict) -> None:
    PROVENANCE.write_text(json.dumps(provenance, indent=2) + "\n")


def status(provenance: dict, source: str) -> int:
    latest = latest_version(remote_tags(source))
    current = provenance["version"]
    print(f"Vendored: {current}\nUpstream: {latest or 'no release tags'}")
    if latest and version_key(latest) > version_key(current):
        print(f"Update available: Scripts/update-7zip.py {latest}")
    return 0


def verify(provenance: dict, source: str) -> int:
    problems = []
    with tempfile.TemporaryDirectory(prefix="zforge-7zip-") as scratch:
        work = Path(scratch)
        revision, archive = fetch_archive(source, provenance["version"], provenance["snapshot_paths"], work)
        if revision != provenance["revision"]:
            problems.append(f"tag {provenance['version']} is {revision}, provenance records {provenance['revision']}")
        digest = hashlib.sha256(archive).hexdigest()
        if digest != provenance["git_archive_sha256"]:
            problems.append(f"archive checksum is {digest}, provenance records {provenance['git_archive_sha256']}")
        expected = work / "snapshot"
        build_snapshot(archive, provenance["snapshot_paths"], provenance["patches"], expected)
        problems += [f"Vendor/7zip/{name} differs from upstream" for name in differing_files(expected, SNAPSHOT)]
    if INPUTS.read_text() != xcfilelist(snapshot_files(SNAPSHOT)):
        problems.append(f"{INPUTS.relative_to(REPO)} is out of date; rerun the import")
    for problem in problems:
        print(problem, file=sys.stderr)
    print(f"Vendor/7zip {provenance['version']}: {'OK' if not problems else f'{len(problems)} problem(s)'}")
    return 1 if problems else 0


def update(provenance: dict, source: str, version: str) -> int:
    previous = provenance["version"]
    paths, patches = provenance["snapshot_paths"], provenance["patches"]
    # The scratch directory sits next to the snapshot so the swap is a rename on one volume.
    with tempfile.TemporaryDirectory(dir=VENDOR, prefix=".7zip-update-") as scratch:
        work = Path(scratch)
        revision, archive = fetch_archive(source, version, paths, work)
        staged = work / "snapshot"
        build_snapshot(archive, paths, patches, staged)
        cli = reference_cli(provenance["repository"], version)
        old_files, new_files = set(snapshot_files(SNAPSHOT)), set(snapshot_files(staged))
        changed_licenses = [name for name in LICENSE_FILES
                            if name not in old_files or name not in new_files
                            or not filecmp.cmp(SNAPSHOT / name, staged / name, shallow=False)]
        history = history_since((staged / HISTORY_FILE).read_text(errors="replace"), previous)
        retired = work / "previous"
        os.rename(SNAPSHOT, retired)
        try:
            os.rename(staged, SNAPSHOT)
        except OSError:
            os.rename(retired, SNAPSHOT)
            raise
    INPUTS.write_text(xcfilelist(snapshot_files(SNAPSHOT)))
    provenance.update(version=version, revision=revision,
                      git_archive_sha256=hashlib.sha256(archive).hexdigest(), reference_cli=cli)
    write_provenance(provenance)

    added, removed = sorted(new_files - old_files), sorted(old_files - new_files)
    print(f"Vendor/7zip: {previous} -> {version} ({revision})")
    print(f"Files: {len(added)} added, {len(removed)} removed")
    for name in added:
        print(f"  + {name}")
    for name in removed:
        print(f"  - {name}")
    if changed_licenses:
        print("License files changed; review the notices shipped in the app: " + ", ".join(changed_licenses))
    else:
        print("License files: unchanged")
    print(f"Reference 7zz: {cli['url']} (sha256 {cli['sha256']})")
    if history:
        print(f"\nUpstream history since {previous}:\n\n{history}")
    print("\nNext: build, run the Unit plan and the engine benchmarks, then commit the update on its own.")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("version", nargs="?", help="release tag to import, such as 26.06")
    action.add_argument("--latest", action="store_true", help="import the newest release tag")
    action.add_argument("--status", action="store_true", help="compare the vendored and upstream versions")
    action.add_argument("--verify", action="store_true", help="check the snapshot against its provenance")
    parser.add_argument("--source", help="Git repository to fetch from (default: the provenance repository)")
    args = parser.parse_args(argv)

    provenance = load_provenance()
    source = args.source or provenance["repository"]
    try:
        if args.status:
            return status(provenance, source)
        if args.verify:
            return verify(provenance, source)
        version = latest_version(remote_tags(source)) if args.latest else args.version
        if not version or not VERSION.fullmatch(version):
            raise UpdateError(f"not a 7-Zip release tag: {version!r}")
        if version_key(version) < version_key(provenance["version"]):
            raise UpdateError(f"{version} is older than the vendored {provenance['version']}")
        if version == provenance["version"]:
            print(f"Vendor/7zip is already {version}; use --verify to check it")
            return 0
        return update(provenance, source, version)
    except (UpdateError, fetch_7zz.FetchError) as error:
        print(f"update-7zip: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
