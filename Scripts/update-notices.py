#!/usr/bin/env python3
"""Writes the license notices the app ships for itself and the components it contains.

Zforge is under the MIT License (`LICENSE`). The app also contains 7-Zip, built
from `Vendor/7zip`, and the Swift packages linked into the app target. Their
licenses require their notices to travel with the app, and the app shows them in
its Acknowledgments window. This script copies those texts into
`Zforge/Resources/ThirdPartyLicenses/` and writes `Acknowledgments.json`, the
list the window reads (component, version, license, website, and each text's
resource name and upstream file):

    Scripts/update-notices.py            write the notices
    Scripts/update-notices.py --check    fail if they are out of date

Swift package texts come from the resolved checkouts of the build
(`<DerivedData>/SourcePackages/checkouts`, the newest Zforge one unless
`--checkouts` names it); each checkout must be at the revision pinned in
`Package.resolved`. Every pinned package must be listed below as shipped or as
used only by tests, so a new dependency cannot ship without its notice.
`Scripts/update-7zip.py` refreshes the 7-Zip notices when it imports a release.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUTPUT = REPO / "Zforge" / "Resources" / "ThirdPartyLicenses"
MANIFEST = OUTPUT / "Acknowledgments.json"
RESOLVED = REPO / "Zforge.xcodeproj" / "project.xcworkspace" / "xcshareddata" / "swiftpm" / "Package.resolved"
PROVENANCE = REPO / "Vendor" / "7zip-provenance.json"
SEVENZIP_DOC = REPO / "Vendor" / "7zip" / "DOC"
DERIVED_DATA = Path.home() / "Library" / "Developer" / "Xcode" / "DerivedData"

ZFORGE = {"id": "zforge", "name": "Zforge", "license": "MIT License",
          "url": "https://github.com/zforge-app/zforge", "sources": {"Zforge-LICENSE.txt": REPO / "LICENSE"}}
SEVENZIP = {"id": "7zip", "name": "7-Zip", "url": "https://www.7-zip.org/",
            "license": "GNU LGPL 2.1 with the unRAR license restriction; BSD 3-clause and 2-clause licenses for some code",
            "sources": {"7-Zip-License.txt": SEVENZIP_DOC / "License.txt",
                        "7-Zip-LGPL.txt": SEVENZIP_DOC / "copying.txt",
                        "7-Zip-unRAR.txt": SEVENZIP_DOC / "unRarLicense.txt"}}
# Packages linked into the app target (the MCP product and its dependencies), in display order.
SHIPPED = [
    {"id": "eventsource", "name": "EventSource", "license": "MIT License",
     "url": "https://github.com/mattt/eventsource", "files": ["LICENSE.md"]},
    {"id": "swift-sdk", "name": "MCP Swift SDK", "license": "Apache License 2.0; MIT License for earlier contributions",
     "url": "https://github.com/modelcontextprotocol/swift-sdk", "files": ["LICENSE"]},
    {"id": "swift-log", "name": "Swift Logging API", "license": "Apache License 2.0",
     "url": "https://github.com/apple/swift-log", "files": ["LICENSE.txt", "NOTICE.txt"]},
    {"id": "swift-system", "name": "Swift System", "license": "Apache License 2.0",
     "url": "https://github.com/apple/swift-system", "files": ["LICENSE.txt"]},
]
# Pinned only for tests or for packages the app does not link.
NOT_SHIPPED = {"swift-snapshot-testing", "swift-custom-dump", "swift-issue-reporting", "swift-syntax",
               "swift-nio", "swift-atomics", "swift-collections"}


class NoticeError(Exception):
    pass


def output_name(component_id: str, file: str) -> str:
    """Resource name in the flat app bundle: `swift-log` + `NOTICE.txt` -> `swift-log-NOTICE.txt`."""
    stem = Path(file).stem
    return f"{component_id}-{stem}.txt"


def pins() -> dict:
    return {pin["identity"]: pin["state"] for pin in json.loads(RESOLVED.read_text())["pins"]}


def unclassified(identities) -> list[str]:
    known = {package["id"] for package in SHIPPED} | NOT_SHIPPED
    return sorted(set(identities) - known)


def find_checkouts() -> Path:
    candidates = sorted(DERIVED_DATA.glob("Zforge-*/SourcePackages/checkouts"),
                        key=lambda path: path.stat().st_mtime, reverse=True)
    for candidate in candidates:
        if all((candidate / package["id"]).is_dir() for package in SHIPPED):
            return candidate
    raise NoticeError("no resolved Swift package checkouts; build the app once or pass --checkouts")


def checkout_revision(path: Path) -> str:
    result = subprocess.run(["git", "-C", str(path), "rev-parse", "HEAD"], capture_output=True, text=True)
    if result.returncode != 0:
        raise NoticeError(f"{path} is not a Git checkout")
    return result.stdout.strip()


def sevenzip_entry() -> tuple[dict, dict[str, bytes]]:
    version = json.loads(PROVENANCE.read_text())["version"]
    files = {name: source.read_bytes() for name, source in SEVENZIP["sources"].items()}
    entry = {key: SEVENZIP[key] for key in ("id", "name", "license", "url")}
    listed = [{"name": name, "source": source.relative_to(SEVENZIP_DOC.parent).as_posix()}
              for name, source in SEVENZIP["sources"].items()]
    return {**entry, "version": version, "files": listed}, files


def expected(checkouts: Path) -> tuple[list[dict], dict[str, bytes]]:
    """The manifest entries and the files they name, in display order."""
    pinned = pins()
    missing = unclassified(pinned)
    if missing:
        raise NoticeError("classify these packages as shipped or not shipped in Scripts/update-notices.py: "
                          + ", ".join(missing))
    entries, files = [], {}
    if not ZFORGE["sources"]["Zforge-LICENSE.txt"].is_file():
        raise NoticeError("LICENSE is missing at the repository root")
    files["Zforge-LICENSE.txt"] = ZFORGE["sources"]["Zforge-LICENSE.txt"].read_bytes()
    entries.append({key: ZFORGE[key] for key in ("id", "name", "license", "url")} | {"version": None,
                   "files": [{"name": "Zforge-LICENSE.txt", "source": "LICENSE"}]})
    entry, sevenzip_files = sevenzip_entry()
    entries.append(entry)
    files.update(sevenzip_files)
    for package in SHIPPED:
        state = pinned.get(package["id"])
        if state is None:
            raise NoticeError(f"{package['id']} is listed as shipped but not pinned in Package.resolved")
        checkout = checkouts / package["id"]
        revision = checkout_revision(checkout)
        if revision != state["revision"]:
            raise NoticeError(f"{checkout} is at {revision}, Package.resolved pins {state['revision']}; "
                              "resolve the packages again")
        names = []
        for file in package["files"]:
            name = output_name(package["id"], file)
            files[name] = (checkout / file).read_bytes()
            names.append({"name": name, "source": file})
        entries.append({"id": package["id"], "name": package["name"], "license": package["license"],
                        "url": package["url"], "version": state.get("version"), "files": names})
    return entries, files


def render_manifest(entries: list[dict]) -> str:
    return json.dumps({"components": entries}, indent=2, ensure_ascii=False) + "\n"


def write(entries: list[dict], files: dict[str, bytes]) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, data in files.items():
        (OUTPUT / name).write_bytes(data)
    stale = {path.name for path in OUTPUT.iterdir()} - set(files) - {MANIFEST.name}
    for name in stale:
        (OUTPUT / name).unlink()
    MANIFEST.write_text(render_manifest(entries))


def refresh_sevenzip() -> None:
    """Called by `Scripts/update-7zip.py`: copies the 7-Zip notices and records its version."""
    entry, files = sevenzip_entry()
    for name, data in files.items():
        (OUTPUT / name).write_bytes(data)
    manifest = json.loads(MANIFEST.read_text())
    manifest["components"] = [entry if item["id"] == entry["id"] else item for item in manifest["components"]]
    MANIFEST.write_text(render_manifest(manifest["components"]))


def shown(path: Path) -> str:
    try:
        return str(path.relative_to(REPO))
    except ValueError:
        return str(path)


def check(entries: list[dict], files: dict[str, bytes]) -> list[str]:
    problems = []
    if not MANIFEST.is_file() or MANIFEST.read_text() != render_manifest(entries):
        problems.append(f"{shown(MANIFEST)} is out of date")
    for name, data in files.items():
        path = OUTPUT / name
        if not path.is_file() or path.read_bytes() != data:
            problems.append(f"{shown(path)} is missing or out of date")
    stale = {path.name for path in OUTPUT.iterdir()} - set(files) - {MANIFEST.name} if OUTPUT.is_dir() else set()
    problems += [f"{shown(OUTPUT / name)} is not a current notice" for name in sorted(stale)]
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--check", action="store_true", help="fail if the notices are out of date")
    parser.add_argument("--checkouts", type=Path, help="resolved Swift package checkouts directory")
    args = parser.parse_args(argv)
    try:
        entries, files = expected(args.checkouts or find_checkouts())
    except (NoticeError, OSError) as error:
        print(f"update-notices: {error}", file=sys.stderr)
        return 1
    if args.check:
        problems = check(entries, files)
        for problem in problems:
            print(problem, file=sys.stderr)
        print(f"Notices: {'OK' if not problems else f'{len(problems)} problem(s)'}")
        return 1 if problems else 0
    write(entries, files)
    print(f"Wrote {len(files)} notices for {len(entries)} components to {OUTPUT.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
