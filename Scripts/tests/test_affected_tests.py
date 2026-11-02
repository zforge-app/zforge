"""Tests for Scripts/affected-tests.py: the split between offscreen and real UI tests, the lane plan,
the reading of an offscreen run summary and the location of the offscreen tool.

Run: python3 -m unittest discover -s Scripts/tests -v
"""
import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "affected-tests.py"
spec = importlib.util.spec_from_file_location("affected_tests", SCRIPT)
affected = importlib.util.module_from_spec(spec)
spec.loader.exec_module(affected)

A = "ZforgeUITests/Browser/testA"
B = "ZforgeUITests/Browser/testB"
C = "ZforgeUITests/Browser/testC"
D = "ZforgeUITests/Finder/testD"


class PartitionTests(unittest.TestCase):
    def test_real_only_tests_leave_the_offscreen_group_in_selection_order(self):
        impact = {"offscreen": {"realOnly": {D: "Finder", B: "drag and drop"}}}
        self.assertEqual(affected.partition([A, B, C, D], impact), ([A, C], [B, D]))

    def test_without_an_offscreen_section_every_test_runs_offscreen(self):
        self.assertEqual(affected.partition([A, B], {}), ([A, B], []))


class LanePlanTests(unittest.TestCase):
    def test_longest_tests_spread_over_the_lanes_first(self):
        durations = {A: 80, B: 50, C: 40, D: 10}
        # A, B and C open the three lanes; D joins the least loaded one (C, 40 s).
        self.assertEqual(affected.plan_lanes([D, C, B, A], 3, durations), [[A], [B], [C, D]])

    def test_never_more_lanes_than_tests_and_no_empty_lane(self):
        self.assertEqual(affected.plan_lanes([A, B], 3, {}), [[A], [B]])
        self.assertEqual(affected.plan_lanes([], 3, {}), [])

    def test_unknown_durations_use_the_default_and_ties_sort_by_name(self):
        plan = affected.plan_lanes([C, A, B], 2, {})
        self.assertEqual(plan, [[A, C], [B]])
        self.assertEqual(plan, affected.plan_lanes([B, C, A], 2, {}), "the plan does not depend on input order")

    def test_every_test_is_planned_exactly_once(self):
        tests = [f"ZforgeUITests/Browser/test{i}" for i in range(16)]
        plan = affected.plan_lanes(tests, 3, {t: i for i, t in enumerate(tests)})
        self.assertEqual(sorted(t for lane in plan for t in lane), sorted(tests))
        self.assertEqual(len(plan), 3)


class OutcomeTests(unittest.TestCase):
    def test_cases_map_back_to_their_lane_tests(self):
        plan = [[A, C], [B]]
        summary = {"results": [{"lane": 1, "cases": [["testA", "passed", "3.1"], ["testC", "failed", "9.0"]]},
                               {"lane": 2, "cases": [["testB", "passed", "4.0"]]}]}
        self.assertEqual(affected.lane_outcomes(summary, plan), {A: "passed", C: "failed", B: "passed"})

    def test_a_test_without_a_case_did_not_run(self):
        plan = [[A], [B]]
        summary = {"results": [{"lane": 1, "cases": [["testA", "passed", "3.1"]]}]}
        self.assertEqual(affected.lane_outcomes(summary, plan), {A: "passed", B: "not run"})

    def test_an_aborted_run_leaves_every_test_not_run(self):
        self.assertEqual(affected.lane_outcomes({"error": "screen locked"}, [[A, B]]), {A: "not run", B: "not run"})


class LocateToolTests(unittest.TestCase):
    """The offscreen tool is a sibling of the main checkout; a linked worktree elsewhere still finds it."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        base = Path(self.temp.name).resolve()
        self.main = base / "dev" / "Zforge"
        self.main.mkdir(parents=True)
        self.git("init", "-q")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com",
                 "commit", "-q", "--allow-empty", "-m", "Initial commit")
        self.worktree = base / "worktrees" / "Zforge" / "linked"
        self.git("worktree", "add", "-q", "--detach", str(self.worktree))

    def git(self, *args):
        subprocess.run(["git", *args], cwd=self.main, check=True, capture_output=True)

    def make_tool(self, parent):
        tool = parent / affected.XCUISIM_NAME
        (tool / "Scripts").mkdir(parents=True)
        (tool / "Scripts" / "run-lanes.py").write_text("")
        return tool

    def test_a_linked_worktree_finds_the_tool_next_to_the_main_checkout(self):
        tool = self.make_tool(self.main.parent)
        self.assertEqual(affected.locate_xcuisim(self.worktree, {}), tool)

    def test_the_main_checkout_finds_its_sibling_tool(self):
        tool = self.make_tool(self.main.parent)
        self.assertEqual(affected.locate_xcuisim(self.main, {}), tool)

    def test_a_tool_next_to_the_worktree_comes_before_the_main_checkout_one(self):
        self.make_tool(self.main.parent)
        tool = self.make_tool(self.worktree.parent)
        self.assertEqual(affected.locate_xcuisim(self.worktree, {}), tool)

    def test_the_environment_variable_overrides_every_sibling(self):
        self.make_tool(self.main.parent)
        explicit = Path(self.temp.name) / "elsewhere"
        self.assertEqual(affected.locate_xcuisim(self.worktree, {"ZFORGE_XCUISIM": str(explicit)}), explicit)

    def test_without_a_tool_the_report_names_every_place_searched(self):
        location = affected.locate_xcuisim(self.worktree, {})
        self.assertEqual(location, self.worktree.parent / affected.XCUISIM_NAME)
        message = affected.xcuisim_missing(location, affected.xcuisim_candidates(self.worktree))
        self.assertIn(str(self.worktree.parent / affected.XCUISIM_NAME), message)
        self.assertIn(str(self.main.parent / affected.XCUISIM_NAME), message)

    def test_outside_a_git_checkout_only_the_sibling_is_searched(self):
        plain = Path(self.temp.name).resolve() / "plain" / "Zforge"
        plain.mkdir(parents=True)
        self.assertEqual(affected.xcuisim_candidates(plain), [plain.parent / affected.XCUISIM_NAME])


class MapTests(unittest.TestCase):
    def test_the_versioned_map_is_valid(self):
        self.assertEqual(affected.check(), 0)

    def test_real_only_and_durations_cover_every_ui_test(self):
        offscreen = affected.load_map()["offscreen"]
        tests = set(affected.ui_tests())
        self.assertEqual(set(offscreen["realOnly"]) | set(offscreen["durations"]), tests,
                         "every UI test is either real-only or has a lane duration")
        self.assertFalse(set(offscreen["realOnly"]) & set(offscreen["durations"]))


if __name__ == "__main__":
    unittest.main()
