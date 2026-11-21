#!/usr/bin/env python3
"""Creates the sample "Documentos" folder of the website's feature captures.

The website (zforge-website, "O que mais o Zforge faz") shows real captures of
Zforge and Finder. They all browse the same fictional folder, the one the
website's animated demonstration draws (zforge-website/src/content/story.tsx):

    Documentos/
        Projetos/                 Projeto.7z.001, .002, .003 (one 7z in volumes)
        Backup.zip
        Capa.png
        Fotos-2025.7z             retratos/ (3 pictures), viagem/ (2), leia-me.txt
        Notas.txt
        Orçamento.pdf
        Relatório.pdf
        Site.zip
        Tarefas.txt

Every file is generated (draw_fixture_media.swift draws the pictures and PDFs),
with fixed modification dates, so a run gives the same folder. Archives are made
with the official 7-Zip console binary that Scripts/fetch-7zz.py provides (the
app does not ship it) and with /usr/bin/zip. Three files carry Finder colour
tags, so the sidebar's Tags section lists the fixture's own tags.

    Scripts/website-captures/make_fixtures.py <parent folder>

creates <parent folder>/Documentos, replacing an older one made by this script.

    Scripts/website-captures/make_fixtures.py --lang de <parent folder>

makes the same folder in another app language: its names, Finder tag names and the
short texts inside the files come from fixture_names.json (keys are English ids of the
items; Brazilian Portuguese is the default and gives the folder
above). The translations other than Brazilian Portuguese await the owner's review.
"""
from __future__ import annotations

import argparse
import json
import os
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unicodedata
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
MEDIA = HERE / "draw_fixture_media.swift"
MARKER = ".zforge-website-fixture"
TABLE = HERE / "fixture_names.json"
DEFAULT_LANGUAGE = "pt-BR"


def languages() -> list[str]:
    return list(json.loads(TABLE.read_text(encoding="utf-8"))["languages"])


class Strings:
    """One language of fixture_names.json: `name("cover")`, `tag("blue")`, `text("readme")`."""

    def __init__(self, language: str) -> None:
        table = json.loads(TABLE.read_text(encoding="utf-8"))["languages"]
        if language not in table:
            sys.exit(f"unknown language {language!r}; fixture_names.json has {', '.join(table)}")
        self.language = language
        self._entry = table[language]

    def name(self, key: str) -> str:
        return unicodedata.normalize("NFC", self._entry["names"][key])

    def tag(self, key: str) -> str:
        return self._entry["tags"][key]

    def text(self, key: str) -> str:
        return self._entry["texts"][key]


def stamp(path: Path, when: str) -> None:
    moment = datetime.strptime(when, "%Y-%m-%d %H:%M").timestamp()
    os.utime(path, (moment, moment), follow_symlinks=False)


def write_text(path: Path, text: str, when: str) -> None:
    path.write_text(text, encoding="utf-8")
    stamp(path, when)


def media(*arguments: str) -> None:
    subprocess.run(["xcrun", "swift", str(MEDIA), *arguments], check=True)


def seven_zip() -> str:
    return subprocess.run([sys.executable, str(REPO / "Scripts" / "fetch-7zz.py")], check=True,
                          capture_output=True, text=True).stdout.strip().splitlines()[-1]


def tag(path: Path, *tags: tuple[str, int]) -> None:
    """Finder colour tags, as Finder stores them ("name\\ncolour index")."""
    value = plistlib.dumps([f"{name}\n{index}" for name, index in tags], fmt=plistlib.FMT_BINARY)
    subprocess.run(["xattr", "-wx", "com.apple.metadata:_kMDItemUserTags", value.hex(), str(path)], check=True)


def build(parent: Path, language: str = DEFAULT_LANGUAGE) -> Path:
    t = Strings(language)
    n = t.name
    root = parent / n("documents")
    if root.exists():
        if not (root / MARKER).exists():
            sys.exit(f"{root} exists and was not made by this script; remove it or choose another folder")
        shutil.rmtree(root)
    root.mkdir(parents=True)
    (root / MARKER).touch()
    sevenzz = seven_zip()

    with tempfile.TemporaryDirectory(prefix="zforge-fixture-") as scratch_name:
        scratch = Path(scratch_name)

        # Fotos-2025.7z: the archive the captures open, browse and validate.
        photos = scratch / "photos"
        portraits, trip = photos / n("portraits"), photos / n("trip")
        portraits.mkdir(parents=True)
        trip.mkdir()
        for index, (name, when) in enumerate([(n("portrait1"), "2026-09-21 15:12"),
                                              (n("portrait2"), "2026-09-21 15:14"),
                                              (n("groupPhoto"), "2026-09-21 15:40")]):
            media("photo", str(portraits / name), str(index))
            stamp(portraits / name, when)
        for index, (name, when) in enumerate([(n("beachPhoto"), "2026-08-02 10:20"),
                                              (n("trailPhoto"), "2026-08-03 08:45")]):
            media("photo", str(trip / name), str(index + 3))
            stamp(trip / name, when)
        write_text(photos / n("readme"), t.text("readme") + "\n", "2026-09-28 16:30")
        stamp(portraits, "2026-09-28 16:04")
        stamp(trip, "2026-09-28 16:11")
        subprocess.run([sevenzz, "a", "-t7z", "-bso0", "-bsp0", str(root / n("photosArchive")),
                        n("portraits"), n("trip"), n("readme")], cwd=photos, check=True)
        stamp(root / n("photosArchive"), "2026-09-30 18:20")

        # Projetos/Projeto.7z.001-.003: one 7z in three volumes.
        project = scratch / "project" / "Project"
        images, plans = project / n("images"), project / n("plans")
        images.mkdir(parents=True)
        media("pdf", str(project / n("brief")), t.text("briefTitle"), t.text("briefBody"), "",
              t.text("briefDeadline"))
        stamp(project / n("brief"), "2026-10-20 14:00")
        write_text(project / n("schedule"),
                   "".join(t.text(f"schedule{week}") + "\n" for week in (1, 2, 3)), "2026-10-22 09:10")
        media("pdf", str(project / n("contract")), t.text("contractTitle"), t.text("contractBody"))
        stamp(project / n("contract"), "2026-10-21 16:40")
        plans.mkdir()
        media("pdf", str(plans / n("floorPlan")), t.text("planTitle"), t.text("planScale"))
        stamp(plans / n("floorPlan"), "2026-10-25 10:15")
        stamp(plans, "2026-10-25 10:15")
        for index, name in enumerate([n("facade"), n("interior")]):
            media("noise", str(images / name), str(index + 7), "640")
            stamp(images / name, "2026-10-28 17:30")
        stamp(images, "2026-10-28 17:30")
        stamp(project, "2026-11-03 11:00")
        projects = root / n("projects")
        projects.mkdir()
        subprocess.run([sevenzz, "a", "-t7z", "-mx=1", "-v800k", "-bso0", "-bsp0", str(projects / n("projectArchive")),
                        n("brief"), n("contract"), n("schedule"), n("images"), n("plans")],
                       cwd=project, check=True)
        for volume in sorted(projects.iterdir()):
            stamp(volume, "2026-11-04 09:15")
        stamp(projects, "2026-10-12 17:08")
        tag(projects, (t.tag("blue"), 4))

        # Backup.zip and Site.zip.
        backup = scratch / "backup" / n("backupFolder")
        backup.mkdir(parents=True)
        write_text(backup / n("contacts"), t.text("contactsHeader") + "\n" + t.text("contactsRow") + "\n",
                   "2026-09-01 20:00")
        write_text(backup / n("receipts"), t.text("receipts") + "\n", "2026-09-01 20:05")
        stamp(backup, "2026-09-02 21:20")
        subprocess.run(["zip", "-qrX", str(root / n("backupZip")), n("backupFolder")], cwd=backup.parent, check=True)
        stamp(root / n("backupZip"), "2026-09-02 21:30")

        site = scratch / "site" / n("siteFolder")
        site.mkdir(parents=True)
        shop = t.text("siteTitle")
        write_text(site / n("indexPage"), f"<!doctype html>\n<title>{shop}</title>\n<h1>{shop}</h1>\n",
                   "2026-08-18 18:00")
        write_text(site / n("stylesheet"), "body { font-family: system-ui; }\n", "2026-08-18 18:02")
        stamp(site, "2026-08-19 10:00")
        subprocess.run(["zip", "-qrX", str(root / n("siteZip")), n("siteFolder")], cwd=site.parent, check=True)
        stamp(root / n("siteZip"), "2026-08-19 10:03")

    # Loose files.
    media("cover", str(root / n("cover")))
    stamp(root / n("cover"), "2026-10-08 14:12")
    write_text(root / n("notes"), t.text("notes1") + "\n" + t.text("notes2") + "\n", "2026-10-11 09:33")
    write_text(root / n("tasks"), "- " + t.text("tasks1") + "\n- " + t.text("tasks2") + "\n",
               "2026-11-09 18:51")
    budget = root / n("budget")
    media("pdf", str(budget), t.text("budgetTitle"), t.text("budgetSubtitle"), "", t.text("budgetMaterial"),
          t.text("budgetLabor"), "", t.text("budgetTotal"))
    stamp(budget, "2026-10-06 16:25")
    report = root / n("report")
    media("pdf", str(report), t.text("reportTitle"), t.text("reportSubtitle"), "", t.text("reportBody"))
    stamp(report, "2026-10-10 11:47")
    tag(report, (t.tag("red"), 6))
    tag(root / n("tasks"), (t.tag("orange"), 7))
    stamp(root / MARKER, "2026-11-10 10:00")
    stamp(root, "2026-11-10 10:00")
    return root


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("parent", type=Path, help="folder that receives Documentos (or its translation)")
    parser.add_argument("--lang", default=DEFAULT_LANGUAGE, choices=languages(),
                        help="app language of the names and texts (fixture_names.json); default pt-BR")
    arguments = parser.parse_args()
    arguments.parent.mkdir(parents=True, exist_ok=True)
    print(build(arguments.parent.resolve(), arguments.lang))


if __name__ == "__main__":
    main()
