#!/usr/bin/env python3
"""Selects and runs the tests a change can affect.

The unit plan (`TestPlans/Unit.xctestplan`) always runs in full: it is fast and
runs offscreen. Only the UI tests mapped to the changed paths in
`TestPlans/ui-impact.json` run. A changed source file that no rule maps selects
the UI smoke plan and is reported, so the map gets updated.

Selected UI tests run offscreen, in parallel lanes, through the sibling
zforge-xcuitest-sim tool (RNF-Q08): it runs the unchanged XCUITests on
throwaway copies of a build without taking over the screen. The tests listed
under `offscreen.realOnly` in the map leave the app process (Finder, drag and
drop through the window server, out-of-process open panels); they run as real
XCUITests afterwards and take over the screen. Without the tool, every UI test
runs real. The tool is looked up next to this checkout, then next to the main
checkout (so linked worktrees, such as ~/.t3/worktrees/..., find it), unless
ZFORGE_XCUISIM names it. Offscreen runs do not use macOS Automation Mode: the
tool answers XCTest's UI-automation requests from inside the app
(--automation-mode goes back to testmanagerd). Each checkout builds into its own
directory in the tool's work directory.

Usage:
  Scripts/affected-tests.py                 # list the selection for uncommitted changes
  Scripts/affected-tests.py --base main     # ...for changes since a ref (plus uncommitted)
  Scripts/affected-tests.py --files A B     # ...for explicit paths
  Scripts/affected-tests.py --run           # run the unit plan, then the selected UI tests
  Scripts/affected-tests.py --run --no-ui   # run only the unit plan
  Scripts/affected-tests.py --run --ui-mode real   # run every selected UI test real
  Scripts/affected-tests.py --run --lanes 2        # offscreen lanes (default 3)
  Scripts/affected-tests.py --run --automation-mode  # offscreen through testmanagerd (Automation Mode on)
  Scripts/affected-tests.py --check         # validate the map against the sources and UI tests
"""

import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAP = ROOT / "TestPlans" / "ui-impact.json"
SMOKE_PLAN = ROOT / "TestPlans" / "UI-Smoke.xctestplan"
UI_DIR = ROOT / "ZforgeUITests"
SOURCE_DIRS = ["Zforge", "Shared", "ZforgeFinderExtension"]
XCUISIM_NAME = "zforge-xcuitest-sim"
XCUISIM_WORK = Path(os.environ.get("XCUISIM_WORK", Path.home() / "Library/Caches/dev.xcuitestsim"))
XCUISIM_BUILT = ["libXCUISimAgent.dylib", "libXCUISimRunnerShim.dylib", "ScreenGuard"]
DEFAULT_DURATION = 30


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


def partition(selected, impact):
    """Splits the selected UI tests into (offscreen, real) keeping the selection order."""
    real_only = impact.get("offscreen", {}).get("realOnly", {})
    return [t for t in selected if t not in real_only], [t for t in selected if t in real_only]


def plan_lanes(tests, lanes, durations):
    """Balances tests over at most `lanes` lanes, longest first, deterministically."""
    count = max(1, min(lanes, len(tests)))
    plan, load = [[] for _ in range(count)], [0.0] * count
    for test in sorted(tests, key=lambda t: (-durations.get(t, DEFAULT_DURATION), t)):
        index = load.index(min(load))
        plan[index].append(test)
        load[index] += durations.get(test, DEFAULT_DURATION)
    return [lane for lane in plan if lane]


def lane_outcomes(summary, plan):
    """Maps every planned test to 'passed', 'failed' or 'not run' from a run-lanes.py summary."""
    outcomes = {test: "not run" for lane in plan for test in lane}
    for result in summary.get("results", []):
        lane = plan[result["lane"] - 1]
        by_method = {test.rsplit("/", 1)[1]: test for test in lane}
        for method, status, _seconds in result.get("cases", []):
            if method in by_method:
                outcomes[by_method[method]] = status
    return outcomes


def xcuisim_candidates(root):
    """Where the offscreen tool may be: next to this checkout, then next to the main checkout.

    A linked worktree (for example one under ~/.t3/worktrees) has no sibling tool of its own;
    the tool sits next to the main checkout, the parent of the shared git directory.
    """
    candidates = [root.parent / XCUISIM_NAME]
    common = subprocess.run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
                            cwd=root, capture_output=True, text=True)
    if common.returncode == 0 and common.stdout.strip():
        main = Path(common.stdout.strip()).resolve().parent
        if main.parent / XCUISIM_NAME not in candidates:
            candidates.append(main.parent / XCUISIM_NAME)
    return candidates


def locate_xcuisim(root, environment):
    """The offscreen tool: `ZFORGE_XCUISIM` when set, else the first candidate that holds it."""
    if environment.get("ZFORGE_XCUISIM"):
        return Path(environment["ZFORGE_XCUISIM"])
    candidates = xcuisim_candidates(root)
    return next((c for c in candidates if (c / "Scripts" / "run-lanes.py").is_file()), candidates[0])


def xcuisim_missing(location, searched=()):
    """Why the offscreen tool cannot run, or None."""
    for script in ("Scripts/run-lanes.py", "Scripts/build-for-testing.sh"):
        if not (location / script).is_file():
            places = ", ".join(str(p) for p in searched) or str(location)
            return f"zforge-xcuitest-sim not found at {places} (set ZFORGE_XCUISIM)"
    for product in XCUISIM_BUILT:
        if not (XCUISIM_WORK / "build" / product).exists():
            return f"{product} is not built; run {location}/Scripts/build-tools.sh"
    return None


def offscreen_build_dir(root, work=None):
    """Each checkout builds into its own directory: concurrent worktrees would otherwise build over each
    other and test each other's code."""
    return Path(work or XCUISIM_WORK) / "builds" / f"zforge-affected-{root.name}"


def lane_command(xcuisim, name, results, products, plan, automation_mode=False):
    """run-lanes.py for the planned lanes. Without Automation Mode (the default), the tool answers
    XCTest's UI-automation requests itself, so macOS never shows "Automation Running" or asks to
    authenticate; `automation_mode` goes back to testmanagerd's accessibility path."""
    command = [sys.executable, str(xcuisim / "Scripts" / "run-lanes.py"), "--name", name, "--results", str(results),
               "--watch", "Zforge", "--watch", "ZforgeUITests-Runner",
               "--products", str(products), "--app-group-suffix",
               "--plist-suffix-key", "ZforgeAppGroupIdentifier"]
    if not automation_mode:
        command += ["--env", "XCUISIM_NO_AUTOMATION_MODE=1"]
    for lane in plan:
        command += ["--lane", ",".join(lane)]
    return command


def run_offscreen(xcuisim, tests, lanes, durations, automation_mode=False):
    """Builds into the tool's work directory and runs the tests in offscreen lanes. Returns failures."""
    derived = offscreen_build_dir(ROOT)
    build = [str(xcuisim / "Scripts" / "build-for-testing.sh"), str(derived), "-project", "Zforge.xcodeproj",
             "-scheme", "Zforge", "-testPlan", "UI-Full", "-configuration", "Debug",
             "-destination", "platform=macOS,arch=arm64"]
    print("$ " + " ".join(build), flush=True)
    if subprocess.run(build, cwd=ROOT).returncode != 0:
        return list(tests)
    plan = plan_lanes(tests, lanes, durations)
    name = time.strftime("affected-%Y%m%d-%H%M%S")
    results = XCUISIM_WORK / "affected-results"
    command = lane_command(xcuisim, name, results, derived / "Build" / "Products", plan, automation_mode)
    print(f"Running {len(tests)} UI tests offscreen in {len(plan)} lanes (the screen stays free).", flush=True)
    status = subprocess.run(command, cwd=ROOT, stdout=subprocess.DEVNULL).returncode
    summary_path = results / f"{name}.json"
    if not summary_path.is_file():
        print(f"error: offscreen run left no summary (exit {status})")
        return list(tests)
    summary = json.loads(summary_path.read_text())
    outcomes = lane_outcomes(summary, plan)
    for test, outcome in outcomes.items():
        print(f"  {outcome:8} {test}")
    for problem in ("error", "interrupted"):
        if problem in summary:
            print(f"error: offscreen run {problem}: {summary[problem]}")
    if summary.get("aborted_for_system_dialog"):
        print("error: a system dialog came to the front; the offscreen run was aborted")
    print(f"Offscreen results: {results}/{name}*  (screen guard: {summary.get('guard', 'n/a')})")
    return [test for test, outcome in outcomes.items() if outcome != "passed"]


def check():
    impact = load_map()
    tests = ui_tests()
    problems = []
    offscreen = impact.get("offscreen", {})
    for test in offscreen.get("realOnly", {}):
        if test not in tests:
            problems.append(f"offscreen.realOnly names a missing UI test: {test}")
    for test in offscreen.get("durations", {}):
        if test not in tests:
            problems.append(f"offscreen.durations names a missing UI test: {test}")
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
    parser.add_argument("--ui-mode", choices=["auto", "offscreen", "real"], default="auto",
                        help="auto: offscreen through zforge-xcuitest-sim when available, real otherwise")
    parser.add_argument("--lanes", type=int, default=3, help="offscreen lanes (default 3)")
    parser.add_argument("--automation-mode", action="store_true",
                        help="offscreen through testmanagerd's accessibility (turns macOS Automation Mode on)")
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
    impact = load_map()
    offscreen, real = partition(selected, impact)
    xcuisim = locate_xcuisim(ROOT, os.environ)
    searched = [] if os.environ.get("ZFORGE_XCUISIM") else xcuisim_candidates(ROOT)
    missing = xcuisim_missing(xcuisim, searched) if args.ui_mode != "real" else "real mode requested"
    if missing and args.ui_mode == "offscreen":
        print(f"error: {missing}")
        return 2
    if missing:
        if selected and args.ui_mode == "auto":
            print(f"note: {missing}; UI tests run real.")
        offscreen, real = [], selected
    if selected:
        print(f"Offscreen: {len(offscreen)}, real (takes over the screen): {len(real)}")
    if not args.run:
        return 0
    status = xcodebuild("Unit")
    if status != 0 or args.no_ui or not selected:
        return status
    failures = run_offscreen(xcuisim, offscreen, args.lanes, impact["offscreen"]["durations"],
                             args.automation_mode) if offscreen else []
    real_status = 0
    if real:
        print(f"Running {len(real)} UI tests real: they take over the screen until they finish.", flush=True)
        real_status = xcodebuild("UI-Full", real)
    if failures:
        print(f"Offscreen failures ({len(failures)}):")
        for test in failures:
            print(f"  {test}")
    return 1 if failures or real_status else 0


if __name__ == "__main__":
    sys.exit(main())
