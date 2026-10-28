#!/usr/bin/env python3
"""Selects and runs the tests a change can affect.

The unit plan (`TestPlans/Unit.xctestplan`) always runs in full: it is fast and
runs offscreen. UI tests take over the screen, so only the ones mapped to the
changed paths in `TestPlans/ui-impact.json` run. A changed source file that no
rule maps selects the UI smoke plan and is reported, so the map gets updated.

Usage:
  Scripts/affected-tests.py                 # list the selection for uncommitted changes
  Scripts/affected-tests.py --base main     # ...for changes since a ref (plus uncommitted)
  Scripts/affected-tests.py --files A B     # ...for explicit paths
  Scripts/affected-tests.py --run           # run the unit plan, then the selected UI tests
  Scripts/affected-tests.py --run --no-ui   # run only the unit plan
  Scripts/affected-tests.py --check         # validate the map against the sources and UI tests
"""

import argparse
import fnmatch
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAP = ROOT / "TestPlans" / "ui-impact.json"
SMOKE_PLAN = ROOT / "TestPlans" / "UI-Smoke.xctestplan"
UI_DIR = ROOT / "ZforgeUITests"
SOURCE_DIRS = ["Zforge", "Shared", "ZforgeFinderExtension"]


def load_map():
    return json.loads(MAP.read_text())


def matches(path, patterns):
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns)


def ui_tests():
    """Every UI test as `ZforgeUITests/Class/testMethod`."""
    found = {}
    for file in sorted(UI_DIR.glob("*.swift")):
        current = None
        for line in file.read_text().splitlines():
            declared = re.match(r"\s*(?:final\s+)?class\s+(\w+)\s*:\s*XCTestCase", line)
            if declared:
                current = declared.group(1)
            method = re.match(r"\s*func\s+(test\w*)\s*\(", line)
            if method and current:
                found[f"ZforgeUITests/{current}/{method.group(1)}"] = file.relative_to(ROOT).as_posix()
    return found


def smoke_tests():
    plan = json.loads(SMOKE_PLAN.read_text())
    selected = plan["testTargets"][0].get("selectedTests", [])
    return [f"ZforgeUITests/{name.replace('()', '')}" for name in selected]


def changed_files(base):
    def git(*args):
        return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout.split("\n")
    files = set(git("diff", "--name-only", "HEAD"))
    files |= set(git("ls-files", "--others", "--exclude-standard"))
    if base:
        files |= set(git("diff", "--name-only", f"{base}...HEAD"))
    return sorted(f for f in files if f)


def select(files):
    impact = load_map()
    tests = ui_tests()
    selected, unmapped = set(), []
    for path in files:
        if matches(path, impact["ignore"]):
            continue
        if path.startswith("ZforgeUITests/"):
            # A changed UI test file reruns the tests it declares.
            selected |= {test for test, file in tests.items() if file == path}
            continue
        if path.startswith("ZforgeTests/") or path.startswith("ZforgeSnapshots/"):
            continue  # Covered by the full unit plan.
        rules = [rule for rule in impact["rules"] if matches(path, rule["paths"])]
        if not rules:
            unmapped.append(path)
        for rule in rules:
            selected |= set(rule["tests"])
    if unmapped:
        selected |= set(smoke_tests())
    return sorted(selected), unmapped


def check():
    impact = load_map()
    tests = ui_tests()
    problems = []
    referenced = set(smoke_tests())
    for rule in impact["rules"]:
        referenced |= set(rule["tests"])
        for test in rule["tests"]:
            if test not in tests:
                problems.append(f"Rule '{rule['name']}' names a missing UI test: {test}")
        for pattern in rule["paths"]:
            if not any(fnmatch.fnmatchcase(p.relative_to(ROOT).as_posix(), pattern) for p in ROOT.rglob("*") if p.is_file()):
                problems.append(f"Rule '{rule['name']}' path matches no file: {pattern}")
    for test in smoke_tests():
        if test not in tests:
            problems.append(f"UI-Smoke names a missing UI test: {test}")
    for test in sorted(set(tests) - referenced):
        problems.append(f"UI test reached by no rule: {test}")
    for directory in SOURCE_DIRS:
        for file in sorted((ROOT / directory).rglob("*")):
            if not file.is_file():
                continue
            path = file.relative_to(ROOT).as_posix()
            if not matches(path, impact["ignore"]) and not any(matches(path, r["paths"]) for r in impact["rules"]):
                problems.append(f"Source file mapped by no rule: {path}")
    for problem in problems:
        print(problem)
    print(f"{len(tests)} UI tests, {len(impact['rules'])} rules, {len(problems)} problems")
    return 1 if problems else 0


def xcodebuild(plan, only=()):
    command = ["xcodebuild", "test", "-project", "Zforge.xcodeproj", "-scheme", "Zforge",
               "-destination", "platform=macOS", "-testPlan", plan]
    command += [f"-only-testing:{test}" for test in only]
    print("$ " + " ".join(command), flush=True)
    return subprocess.run(command, cwd=ROOT).returncode


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base", help="also include changes since this ref")
    parser.add_argument("--files", nargs="+", help="explicit changed paths, relative to the project root")
    parser.add_argument("--run", action="store_true", help="run the unit plan and the selected UI tests")
    parser.add_argument("--no-ui", action="store_true", help="with --run, skip the UI tests")
    parser.add_argument("--check", action="store_true", help="validate the impact map")
    args = parser.parse_args()
    if args.check:
        return check()
    files = args.files or changed_files(args.base)
    selected, unmapped = select(files)
    print(f"Changed files: {len(files)}")
    for path in unmapped:
        print(f"warning: no UI impact rule maps {path}; selecting UI-Smoke. Update TestPlans/ui-impact.json.")
    print("Unit plan: all tests")
    print(f"UI tests ({len(selected)}):" + ("" if selected else " none"))
    for test in selected:
        print(f"  {test}")
    if not args.run:
        return 0
    status = xcodebuild("Unit")
    if status != 0 or args.no_ui or not selected:
        return status
    print("Running UI tests: they take over the screen until they finish.", flush=True)
    return xcodebuild("UI-Full", selected)


if __name__ == "__main__":
    sys.exit(main())
