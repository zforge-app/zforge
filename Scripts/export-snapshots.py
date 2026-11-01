#!/usr/bin/env python3
"""Copies snapshot references recorded as test attachments into the project.

The unit test host is isolated from the user's preferences and grants (ZF-54), so it
cannot write into the project. `ZforgeSnapshot` attaches each reference it records under
its project path (`ZforgeSnapshots__<test file>__<name>.png`, "__" for "/"); this script exports those
attachments from a result bundle and copies them there. Review every copied image
before committing it.

Usage:
  Scripts/export-snapshots.py path/to/Result.xcresult
"""

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# xcresulttool appends "_<index>_<UUID>" to a suggested name before its extension.
SUFFIX = re.compile(r"_\d+_[0-9A-Fa-f-]{36}(?=\.[^.]+$)")


def main():
    if len(sys.argv) != 2:
        print(__doc__.strip())
        return 2
    bundle = Path(sys.argv[1])
    with tempfile.TemporaryDirectory() as temporary:
        subprocess.run(["xcrun", "xcresulttool", "export", "attachments", "--path", str(bundle),
                        "--output-path", temporary], check=True, capture_output=True)
        manifest = json.loads((Path(temporary) / "manifest.json").read_text())
        copied = []
        for test in manifest:
            for attachment in test.get("attachments", []):
                # Result bundles drop "/" from attachment names, so ZforgeSnapshot uses "__".
                name = SUFFIX.sub("", attachment.get("suggestedHumanReadableName", "")).replace("__", "/")
                if not name.startswith("ZforgeSnapshots/") or ".." in Path(name).parts:
                    continue
                destination = ROOT / name
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(Path(temporary) / attachment["exportedFileName"], destination)
                copied.append(name)
    for name in copied:
        print(f"copied {name}")
    print(f"{len(copied)} snapshot reference(s) copied; review them before committing.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
