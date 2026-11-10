"""Tests for Scripts/update-7zip.py and Scripts/fetch-7zz.py: release selection, the snapshot's
file list, the history excerpt, the archive safety checks, an import that keeps upstream blobs
byte for byte and applies patches, and the verified download of the reference 7zz.

Run: python3 -m unittest discover -s Scripts/tests -v
"""
import importlib.util
import io
import os
import subprocess
import tarfile
import tempfile
import time
import unittest
from pathlib import Path
from unittest import mock

SCRIPTS = Path(__file__).resolve().parent.parent


def load(name, file):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


update = load("update_7zip", "update-7zip.py")
fetch = load("fetch_7zz", "fetch-7zz.py")


def git(cwd, *args):
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True)


class ReleaseSelectionTests(unittest.TestCase):
    def test_latest_compares_versions_numerically_and_ignores_other_tags(self):
        self.assertEqual(update.latest_version(["26.02", "26.10", "26.9", "build-1", "v27.0"]), "26.10")
        self.assertIsNone(update.latest_version(["nightly"]))

    def test_ls_remote_tags_skip_peeled_references(self):
        output = "abc\trefs/tags/26.05\nabd\trefs/tags/26.05^{}\nabe\trefs/heads/main\n"
        self.assertEqual(update.tags_from_ls_remote(output), ["26.05"])

    def test_release_asset_url_uses_the_compact_version(self):
        self.assertEqual(fetch.release_asset_url("https://github.com/ip7z/7zip", "26.06"),
                         "https://github.com/ip7z/7zip/releases/download/26.06/7z2606-mac.tar.xz")
        with self.assertRaises(fetch.FetchError):
            fetch.release_asset_url("https://github.com/ip7z/7zip", "26.06; rm")


class FileListTests(unittest.TestCase):
    def test_files_sort_in_byte_order_and_build_files_come_last(self):
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            for name in ["C/b.c", "C/B.h", "Asm/x.S", "DOC/readme.txt"]:
                (root / name).parent.mkdir(parents=True, exist_ok=True)
                (root / name).write_text("x")
            files = update.snapshot_files(root)
        self.assertEqual(files, ["Asm/x.S", "C/B.h", "C/b.c", "DOC/readme.txt"])
        self.assertEqual(update.xcfilelist(files).splitlines(), [
            "$(SRCROOT)/Vendor/7zip/Asm/x.S", "$(SRCROOT)/Vendor/7zip/C/B.h",
            "$(SRCROOT)/Vendor/7zip/C/b.c", "$(SRCROOT)/Vendor/7zip/DOC/readme.txt",
            "$(SRCROOT)/BuildSupport/SevenZip/build.sh", "$(SRCROOT)/BuildSupport/SevenZip/static.mk"])

    def test_the_committed_list_matches_the_vendored_snapshot(self):
        self.assertEqual(update.INPUTS.read_text(), update.xcfilelist(update.snapshot_files(update.SNAPSHOT)))


class HistoryTests(unittest.TestCase):
    HISTORY = ("HISTORY of the 7-Zip source code\n--------------------------------\n\n"
               "26.10          2026-12-01\n-------------------------\n- Ten.\n\n\n"
               "26.03          2026-09-03\n-------------------------\n- Three.\n\n\n"
               "26.02          2026-06-25\n-------------------------\n- Two.\n")

    def test_only_entries_newer_than_the_previous_version(self):
        excerpt = update.history_since(self.HISTORY, "26.02")
        self.assertIn("26.10", excerpt)
        self.assertIn("- Three.", excerpt)
        self.assertNotIn("- Two.", excerpt)
        self.assertEqual(update.history_since(self.HISTORY, "26.10"), "")


class ArchiveSafetyTests(unittest.TestCase):
    def archive(self, *members):
        buffer = io.BytesIO()
        with tarfile.open(fileobj=buffer, mode="w") as tar:
            for info in members:
                tar.addfile(info, io.BytesIO(b"") if info.isfile() else None)
        buffer.seek(0)
        return tarfile.open(fileobj=buffer, mode="r:")

    def test_rejects_paths_outside_the_snapshot_paths(self):
        for name in ["../escape.c", "/abs/file.c", "Other/file.c"]:
            with self.subTest(name=name), self.assertRaises(update.UpdateError):
                update.safe_members(self.archive(tarfile.TarInfo(name)), ["C", "CPP"])

    def test_rejects_links(self):
        link = tarfile.TarInfo("C/link.c")
        link.type, link.linkname = tarfile.SYMTYPE, "/etc/passwd"
        with self.assertRaises(update.UpdateError):
            update.safe_members(self.archive(link), ["C"])

    def test_accepts_files_and_directories(self):
        folder = tarfile.TarInfo("C")
        folder.type = tarfile.DIRTYPE
        self.assertEqual(len(update.safe_members(self.archive(folder, tarfile.TarInfo("C/a.c")), ["C"])), 2)


class ImportTests(unittest.TestCase):
    """An upstream fixture whose attributes would rewrite or drop files on export."""

    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        upstream = self.root / "upstream"
        (upstream / "C").mkdir(parents=True)
        (upstream / "C" / "a.c").write_bytes(b"int a;\n")
        (upstream / "C" / "p.dsp").write_bytes(b"line one\nline two\n")
        (upstream / "C" / "ignored.txt").write_bytes(b"kept\n")
        (upstream / "Other.txt").write_bytes(b"outside\n")
        (upstream / ".gitattributes").write_text("*.dsp text eol=crlf\nignored.txt export-ignore\n")
        git(upstream, "init", "-q")
        git(upstream, "add", ".")
        subprocess.run(["git", "-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qm", "26.06"],
                       cwd=upstream, check=True, capture_output=True,
                       env={**os.environ, "GIT_AUTHOR_DATE": "2020-01-01T00:00:00Z",
                            "GIT_COMMITTER_DATE": "2020-01-01T00:00:00Z"})
        git(upstream, "tag", "26.06")
        self.upstream = upstream

    def test_snapshot_keeps_committed_blobs_and_only_the_snapshot_paths(self):
        work = self.root / "work"
        work.mkdir()
        revision, archive = update.fetch_archive(str(self.upstream), "26.06", ["C"], work)
        self.assertEqual(len(revision), 40)
        target = self.root / "snapshot"
        update.build_snapshot(archive, ["C"], [], target)
        self.assertEqual(update.snapshot_files(target), ["C/a.c", "C/ignored.txt", "C/p.dsp"])
        self.assertEqual((target / "C" / "p.dsp").read_bytes(), b"line one\nline two\n")

    def test_snapshot_files_carry_the_import_time_not_the_upstream_commit_time(self):
        # The fixture commit is dated 2020; objects built from an earlier snapshot are newer,
        # so files stamped with the commit time would not make `make` rebuild them.
        work = self.root / "work"
        work.mkdir()
        _, archive = update.fetch_archive(str(self.upstream), "26.06", ["C"], work)
        started = time.time() - 1
        target = self.root / "snapshot"
        update.build_snapshot(archive, ["C"], [], target)
        for path in target.rglob("*"):
            self.assertGreaterEqual(path.stat().st_mtime, started, path)

    def test_patches_apply_in_order_and_a_missing_patch_fails(self):
        work = self.root / "work"
        work.mkdir()
        _, archive = update.fetch_archive(str(self.upstream), "26.06", ["C"], work)
        patches = self.root / "patches"
        patches.mkdir()
        (patches / "0001.patch").write_text(
            "--- a/C/a.c\n+++ b/C/a.c\n@@ -1 +1 @@\n-int a;\n+int a = 1;\n")
        with mock.patch.object(update, "PATCHES", patches):
            target = self.root / "patched"
            update.build_snapshot(archive, ["C"], ["0001.patch"], target)
            self.assertEqual((target / "C" / "a.c").read_bytes(), b"int a = 1;\n")
            with self.assertRaises(update.UpdateError):
                update.build_snapshot(archive, ["C"], ["0002.patch"], self.root / "missing")

    def test_differing_files_reports_changed_added_and_missing_files(self):
        left, right = self.root / "left", self.root / "right"
        for side in (left, right):
            (side / "C").mkdir(parents=True)
            (side / "C" / "same.c").write_text("same")
        (left / "C" / "edit.c").write_text("one")
        (right / "C" / "edit.c").write_text("two")
        (left / "C" / "only-left.c").write_text("x")
        self.assertEqual(update.differing_files(left, right), ["C/only-left.c", "C/edit.c"])


class ReferenceCliTests(unittest.TestCase):
    def tarball(self, binary):
        buffer = io.BytesIO()
        with tarfile.open(fileobj=buffer, mode="w:xz") as tar:
            info = tarfile.TarInfo("7zz")
            info.size = len(binary)
            tar.addfile(info, io.BytesIO(binary))
        return buffer.getvalue()

    def fake_binary(self, version):
        return f"#!/bin/sh\necho '7-Zip (z) {version} (arm64) : Copyright (c) 1999-2026 Igor Pavlov'\n".encode()

    def test_downloads_verifies_and_caches_the_binary(self):
        archive = self.tarball(self.fake_binary("26.06"))
        reference = {"url": "https://example.invalid/7z2606-mac.tar.xz", "sha256": fetch.sha256(archive)}
        with tempfile.TemporaryDirectory() as cache, \
                mock.patch.object(fetch, "download", return_value=archive) as download:
            path = fetch.fetch(reference, "26.06", Path(cache))
            self.assertEqual(path, Path(cache) / reference["sha256"] / "7zz")
            self.assertEqual(fetch.reported_version(path), "26.06")
            self.assertEqual(fetch.fetch(reference, "26.06", Path(cache)), path)
            self.assertEqual(download.call_count, 1)

    def test_a_checksum_mismatch_installs_nothing(self):
        archive = self.tarball(self.fake_binary("26.06"))
        reference = {"url": "https://example.invalid/7z2606-mac.tar.xz", "sha256": "0" * 64}
        with tempfile.TemporaryDirectory() as cache, mock.patch.object(fetch, "download", return_value=archive):
            with self.assertRaises(fetch.FetchError):
                fetch.fetch(reference, "26.06", Path(cache))
            self.assertEqual(list(Path(cache).rglob("*")), [])

    def test_a_binary_reporting_another_version_installs_nothing(self):
        archive = self.tarball(self.fake_binary("26.05"))
        reference = {"url": "https://example.invalid/7z2606-mac.tar.xz", "sha256": fetch.sha256(archive)}
        with tempfile.TemporaryDirectory() as cache, mock.patch.object(fetch, "download", return_value=archive):
            with self.assertRaises(fetch.FetchError):
                fetch.fetch(reference, "26.06", Path(cache))
            self.assertEqual([p for p in Path(cache).rglob("*") if p.is_file()], [])


if __name__ == "__main__":
    unittest.main()
