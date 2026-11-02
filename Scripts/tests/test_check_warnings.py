"""Tests for Scripts/check-warnings.py: which commits need a build, the reading of the build's
diagnostics, the incremental mirror of the git index and the invalidation that keeps a cached
build from hiding a warning.

Run: python3 -m unittest discover -s Scripts/tests -v
"""
import importlib.util
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "check-warnings.py"
spec = importlib.util.spec_from_file_location("check_warnings", SCRIPT)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class NeedsBuildTests(unittest.TestCase):
    def test_documentation_only_commits_skip_the_build(self):
        self.assertFalse(gate.needs_build(["TASKS.md", "Documentation/Requirements/CURRENT-STATE.md",
                                           "Documentation/SwiftUI/INDEX.json"]))
        self.assertFalse(gate.needs_build([]))

    def test_any_other_path_needs_the_build(self):
        for path in ["Zforge/Views/IconPreviewView.swift", "Zforge.xcodeproj/project.pbxproj",
                     "TestPlans/Unit.xctestplan", "Zforge/Localizable.xcstrings", "Scripts/check-warnings.py"]:
            self.assertTrue(gate.needs_build(["README.md", path]), path)


class DiagnosticsTests(unittest.TestCase):
    mirror = Path("/gate/src")

    def test_source_warnings_block_with_a_repository_relative_location_once(self):
        line = "/gate/src/Zforge/A.swift:46:24: warning: 'init(cString:)' is deprecated"
        blocking, third_party, errors = gate.parse_diagnostics(f"{line}\n{line}\n", self.mirror)
        self.assertEqual(blocking, {"Zforge/A.swift:46:24: warning: 'init(cString:)' is deprecated": "Zforge/A.swift"})
        self.assertEqual((third_party, errors), ([], []))

    def test_warnings_without_a_source_location_block_without_a_file(self):
        output = "ld: warning: duplicate -rpath ignored\nwarning: Run script build phase 'X' will be run during every build\n"
        blocking, _, _ = gate.parse_diagnostics(output, self.mirror)
        self.assertEqual(list(blocking.values()), [None, None])
        self.assertEqual(len(blocking), 2)

    def test_third_party_package_warnings_do_not_block(self):
        line = "/gate/DerivedData/SourcePackages/checkouts/pkg/Sources/X.swift:3:1: warning: unused"
        blocking, third_party, _ = gate.parse_diagnostics(line, self.mirror)
        self.assertEqual(blocking, {})
        self.assertEqual(third_party, [line])

    def test_errors_are_collected_and_xcodebuild_notices_are_not_warnings(self):
        output = ("--- xcodebuild: WARNING: Using the first of multiple matching destinations\n"
                  "/gate/src/Zforge/B.swift:1:1: error: cannot find 'x' in scope\n"
                  "note: Building targets in dependency order\n** BUILD FAILED **\n")
        blocking, third_party, errors = gate.parse_diagnostics(output, self.mirror)
        self.assertEqual((blocking, third_party), ({}, []))
        self.assertEqual(errors, ["Zforge/B.swift:1:1: error: cannot find 'x' in scope"])


class MirrorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        base = Path(self.temp.name)
        self.repo, self.mirror, self.manifest = base / "repo", base / "mirror", base / "manifest.json"
        self.repo.mkdir()
        self.mirror.mkdir()
        self.git("init", "-q")
        self.write("Zforge/A.swift", "let a = 1\n")
        self.write("Zforge/Nested/B.swift", "let b = 2\n")
        self.write("Scripts/run.sh", "#!/bin/sh\n")
        (self.repo / "Scripts/run.sh").chmod(0o755)
        os.symlink("A.swift", self.repo / "Zforge/Link.swift")
        self.git("add", "-A")

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        subprocess.run(["git", *args], cwd=self.repo, check=True, capture_output=True)

    def write(self, path, text):
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    def sync(self):
        return gate.sync_mirror(self.repo, gate.index_entries(self.repo), self.mirror, self.manifest)

    def test_first_sync_reproduces_the_index_with_modes_and_symlinks(self):
        self.assertEqual(self.sync(), (4, 0))
        self.assertEqual((self.mirror / "Zforge/Nested/B.swift").read_text(), "let b = 2\n")
        self.assertTrue(os.access(self.mirror / "Scripts/run.sh", os.X_OK))
        self.assertFalse(os.access(self.mirror / "Zforge/A.swift", os.X_OK))
        self.assertEqual(os.readlink(self.mirror / "Zforge/Link.swift"), "A.swift")

    def test_later_syncs_write_only_changed_entries_and_keep_other_dates(self):
        self.sync()
        old = 1_000_000_000
        os.utime(self.mirror / "Zforge/A.swift", (old, old))
        self.write("Zforge/Nested/B.swift", "let b = 3\n")
        self.git("add", "-A")
        self.assertEqual(self.sync(), (1, 0))
        self.assertEqual((self.mirror / "Zforge/Nested/B.swift").read_text(), "let b = 3\n")
        self.assertEqual((self.mirror / "Zforge/A.swift").stat().st_mtime, old)

    def test_the_mirror_follows_the_index_not_the_working_tree(self):
        self.sync()
        self.write("Zforge/A.swift", "let a = String(cString: p)\n")
        self.assertEqual(self.sync(), (0, 0))
        self.assertEqual((self.mirror / "Zforge/A.swift").read_text(), "let a = 1\n")

    def test_paths_that_leave_the_index_are_removed_with_their_empty_folders(self):
        self.sync()
        self.git("rm", "-q", "--cached", "Zforge/Nested/B.swift")
        self.assertEqual(self.sync(), (0, 1))
        self.assertFalse((self.mirror / "Zforge/Nested").exists())
        self.assertTrue((self.mirror / "Zforge/A.swift").exists())

    def test_a_missing_mirror_file_is_restored_even_if_the_manifest_lists_it(self):
        self.sync()
        (self.mirror / "Zforge/A.swift").unlink()
        self.assertEqual(self.sync(), (1, 0))
        self.assertEqual((self.mirror / "Zforge/A.swift").read_text(), "let a = 1\n")


class InvalidationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        base = Path(self.temp.name)
        self.mirror, self.derived = base / "src", base / "DerivedData"
        (self.mirror / "Zforge").mkdir(parents=True)
        (self.derived / "Build").mkdir(parents=True)
        (self.derived / "SourcePackages").mkdir()
        self.file = self.mirror / "Zforge/A.swift"
        self.file.write_text("let a = 1\n")
        os.utime(self.file, (1_000_000_000, 1_000_000_000))

    def tearDown(self):
        self.temp.cleanup()

    def test_files_with_located_warnings_are_marked_changed_and_the_cache_is_kept(self):
        gate.invalidate(self.mirror, self.derived, {"Zforge/A.swift:1:1: warning: x": "Zforge/A.swift"})
        self.assertGreater(self.file.stat().st_mtime, 1_000_000_000)
        self.assertTrue((self.derived / "Build").exists())

    def test_a_warning_without_a_location_discards_the_build_products_only(self):
        gate.invalidate(self.mirror, self.derived, {"ld: warning: x": None})
        self.assertFalse((self.derived / "Build").exists())
        self.assertTrue((self.derived / "SourcePackages").exists())


if __name__ == "__main__":
    unittest.main()
