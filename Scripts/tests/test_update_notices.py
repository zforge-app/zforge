"""Tests for Scripts/update-notices.py: every pinned package is classified, shipped package
notices come from checkouts at the pinned revision, and --check reports stale notices.

Run: python3 -m unittest discover -s Scripts/tests -v
"""
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).resolve().parent.parent / "update-notices.py"
spec = importlib.util.spec_from_file_location("update_notices", SCRIPT)
notices = importlib.util.module_from_spec(spec)
spec.loader.exec_module(notices)


def git(cwd, *args):
    return subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True, text=True).stdout.strip()


class ClassificationTests(unittest.TestCase):
    def test_resource_names_are_unique_in_the_flat_bundle(self):
        self.assertEqual(notices.output_name("swift-log", "NOTICE.txt"), "swift-log-NOTICE.txt")
        self.assertEqual(notices.output_name("eventsource", "LICENSE.md"), "eventsource-LICENSE.txt")
        names = [notices.output_name(p["id"], f) for p in notices.SHIPPED for f in p["files"]]
        names += list(notices.SEVENZIP["sources"]) + list(notices.ZFORGE["sources"])
        self.assertEqual(len(names), len(set(names)))

    def test_an_unclassified_package_is_reported(self):
        self.assertEqual(notices.unclassified(["swift-log", "swift-nio", "new-package"]), ["new-package"])

    def test_every_pinned_package_is_classified(self):
        self.assertEqual(notices.unclassified(notices.pins()), [])


class GenerationTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        self.checkouts = self.root / "checkouts"
        pins = []
        for package in notices.SHIPPED:
            checkout = self.checkouts / package["id"]
            checkout.mkdir(parents=True)
            for file in package["files"]:
                (checkout / file).write_text(f"{package['id']} {file}\n")
            git(checkout, "init", "-q")
            git(checkout, "add", ".")
            git(checkout, "-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qm", "pin")
            pins.append({"identity": package["id"], "state": {"revision": git(checkout, "rev-parse", "HEAD"),
                                                               "version": "1.0.0"}})
        pins += [{"identity": name, "state": {"revision": "0" * 40}} for name in notices.NOT_SHIPPED]
        self.resolved = self.root / "Package.resolved"
        self.resolved.write_text(json.dumps({"pins": pins}))
        self.output = self.root / "ThirdPartyLicenses"
        patches = [mock.patch.object(notices, "RESOLVED", self.resolved),
                   mock.patch.object(notices, "OUTPUT", self.output),
                   mock.patch.object(notices, "MANIFEST", self.output / "Acknowledgments.json")]
        for patch in patches:
            patch.start()
            self.addCleanup(patch.stop)

    def test_writes_every_notice_and_check_passes(self):
        entries, files = notices.expected(self.checkouts)
        self.assertEqual([entry["id"] for entry in entries][:2], ["zforge", "7zip"])
        notices.write(entries, files)
        self.assertEqual((self.output / "swift-log-NOTICE.txt").read_text(), "swift-log NOTICE.txt\n")
        self.assertEqual(notices.check(entries, files), [])

    def test_check_reports_edited_and_stale_notices(self):
        entries, files = notices.expected(self.checkouts)
        notices.write(entries, files)
        (self.output / "swift-system-LICENSE.txt").write_text("edited")
        (self.output / "old-package-LICENSE.txt").write_text("stale")
        problems = notices.check(entries, files)
        self.assertEqual(len(problems), 2, problems)

    def test_a_checkout_at_another_revision_is_refused(self):
        checkout = self.checkouts / "swift-log"
        (checkout / "LICENSE.txt").write_text("changed\n")
        git(checkout, "-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qam", "newer")
        with self.assertRaises(notices.NoticeError):
            notices.expected(self.checkouts)


class ShippedNoticesTests(unittest.TestCase):
    def test_the_committed_seven_zip_notices_match_the_vendored_sources(self):
        _, files = notices.sevenzip_entry()
        for name, data in files.items():
            self.assertEqual((notices.OUTPUT / name).read_bytes(), data, name)

    def test_the_committed_zforge_license_matches_the_repository_license(self):
        self.assertEqual((notices.OUTPUT / "Zforge-LICENSE.txt").read_bytes(), (notices.REPO / "LICENSE").read_bytes())


if __name__ == "__main__":
    unittest.main()
