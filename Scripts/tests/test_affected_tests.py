"""Tests for Scripts/affected-tests.py: the split between offscreen and real UI tests, the lane plan
and the reading of an offscreen run summary.

Run: python3 -m unittest discover -s Scripts/tests -v
"""
import importlib.util
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
