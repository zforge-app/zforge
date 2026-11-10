#!/usr/bin/env python3
"""Provides the official 7-Zip console binary (`7zz`) as a development reference.

The app never ships or runs `7zz`: the engine is the static library built from
`Vendor/7zip`. The binary is only a reference for benchmarks and for generating
or comparing archives during development, so it is not tracked in Git. This
script downloads the macOS release asset recorded under `reference_cli` in
`Vendor/7zip-provenance.json`, verifies its SHA-256 and its reported version, and
caches it per checksum. It prints the path of the binary, so callers can run:

    "$(Scripts/fetch-7zz.py)" i

`Scripts/update-7zip.py` records the asset for each engine version, keeping the
reference binary and the vendored sources on the same release.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import lzma
import os
import re
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PROVENANCE = REPO / "Vendor" / "7zip-provenance.json"
CACHE = Path.home() / "Library" / "Caches" / "dev.zforge" / "7zz"
BINARY_NAME = "7zz"
USER_AGENT = "zforge-build-scripts"


class FetchError(Exception):
    pass


def release_asset_url(repository: str, version: str) -> str:
    """The macOS asset of an upstream GitHub release: `26.06` -> `.../26.06/7z2606-mac.tar.xz`."""
    if not re.fullmatch(r"\d+\.\d+", version):
        raise FetchError(f"not a 7-Zip version: {version!r}")
    compact = version.replace(".", "")
    return f"{repository.rstrip('/')}/releases/download/{version}/7z{compact}-mac.tar.xz"


def download(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.read()
    except OSError as error:
        raise FetchError(f"download failed: {url}: {error}") from error


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def extract_binary(archive: bytes) -> bytes:
    """Returns the `7zz` member of the release tarball; other members are ignored."""
    try:
        with tarfile.open(fileobj=io.BytesIO(archive), mode="r:xz") as tar:
            for member in tar.getmembers():
                if Path(member.name).name == BINARY_NAME and member.isfile():
                    handle = tar.extractfile(member)
                    if handle is not None:
                        return handle.read()
    except (tarfile.TarError, lzma.LZMAError) as error:
        raise FetchError(f"unreadable release archive: {error}") from error
    raise FetchError(f"the release archive has no {BINARY_NAME} file")


def reported_version(binary: Path) -> str:
    """The version `7zz` prints in its banner, such as `26.06`."""
    output = subprocess.run([str(binary)], capture_output=True, text=True, timeout=30).stdout
    match = re.search(r"7-Zip \(z\) (\d+\.\d+)", output)
    if not match:
        raise FetchError(f"{binary} printed no 7-Zip version banner")
    return match.group(1)


def install(binary: bytes, expected_version: str, directory: Path) -> Path:
    """Writes the binary atomically into `directory` after checking the version it reports."""
    directory.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=directory, prefix=".7zz-", delete=False) as handle:
        handle.write(binary)
        staged = Path(handle.name)
    try:
        staged.chmod(0o755)
        version = reported_version(staged)
        if version != expected_version:
            raise FetchError(f"the binary reports 7-Zip {version}, expected {expected_version}")
        target = directory / BINARY_NAME
        os.replace(staged, target)
        return target
    finally:
        staged.unlink(missing_ok=True)


def fetch(reference: dict, version: str, cache: Path = CACHE) -> Path:
    """Returns the cached binary for `reference`, downloading and verifying it when missing."""
    digest = reference["sha256"]
    target = cache / digest / BINARY_NAME
    if target.is_file() and os.access(target, os.X_OK):
        return target
    archive = download(reference["url"])
    actual = sha256(archive)
    if actual != digest:
        raise FetchError(f"checksum mismatch for {reference['url']}: {actual}, expected {digest}")
    return install(extract_binary(archive), version, cache / digest)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.parse_args(argv)
    provenance = json.loads(PROVENANCE.read_text())
    reference = provenance.get("reference_cli")
    if not reference:
        print(f"{PROVENANCE.relative_to(REPO)} records no reference_cli", file=sys.stderr)
        return 1
    try:
        print(fetch(reference, provenance["version"]))
    except FetchError as error:
        print(f"fetch-7zz: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
