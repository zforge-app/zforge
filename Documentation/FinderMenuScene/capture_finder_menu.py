#!/usr/bin/env python3
"""Captures Finder's shortcut menu with the Zforge submenu, for the website.

The website's "Menu no Finder" card shows the real menu: Finder in the page's
language (Brazilian Portuguese today), the sample folder (Documentos, made by
Scripts/website-captures/make_fixtures.py) in Icons, Fotos-2025.7z selected, its
shortcut menu open and the Zforge item's submenu open beside it. With --lang the
same scene is captured in other app languages, with the folder's names translated
(Scripts/website-captures/fixture_names.json).

Finder and its extensions take the user's preferred languages, so for each
capture the script puts the language first in the global AppleLanguages list and
relaunches Finder and the Zforge Finder extension; afterwards it writes the
original list back and relaunches them again. It also switches the system
appearance for the light and dark captures and gives back the one the user had.
Finder reopens its windows after each relaunch. Finder has no Bengali
localization: with --lang bn it falls back to the next preferred language
(English on a Mac set up like the owner's), while the Zforge submenu is Bengali,
which is what a Bengali user sees.

The extension that answers is the Zforge build pluginkit elects (the newest
registered copy, normally the one capture_app.py or Xcode just built); its menu
titles come from ZforgeFinderExtension/Localizable.xcstrings. The script checks
that the running extension carries the catalog's current titles for each
language and that the submenu shows exactly those titles.

The menus are read through the accessibility API (screen_tool.swift axmenus):
Finder's items are identified by their action (cmdArchive: is Compress), not by
their titles, so the frame is the same in every language. Every click and key is
sent only when Finder is the frontmost app and owns the window under the pointer.

Output, for Brazilian Portuguese (the default):
  Captures/finder-menu-<light|dark>.png  the icon view with the menus (raw material)
  <out>/finder-<light|dark>.png        the framed picture the website encodes
for another language:
  Captures/<lang>/finder-menu-<light|dark>.png
  Captures/<lang>/menu.json              the menu titles and frames that were captured
  <out>/<lang>/finder-<light|dark>.png
and <out>/finder-menu-report.json for every language of the run.

Needs the Accessibility and Screen Recording permissions for the terminal; it
moves the pointer and brings Finder to the front: do not use the Mac meanwhile.

    Documentation/FinderMenuScene/capture_finder_menu.py [--out DIR] [--theme light|dark]
        [--lang pt-BR|de|…|all ...]
"""
from __future__ import annotations

import argparse
import json
import plistlib
import shutil
import subprocess
import sys
import tempfile
import time
import unicodedata
from contextlib import contextmanager
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "Scripts" / "website-captures"))

from make_fixtures import DEFAULT_LANGUAGE, Strings, languages  # noqa: E402
from support import (THEMES, Process, Rect, ScreenTool, appearance_restored, capture_region,  # noqa: E402
                     dark_mode, set_dark_mode, wait_until)

FIXTURE_PARENT = HERE
CAPTURES = HERE / "Captures"
MAKE_FIXTURES = REPO / "Scripts" / "website-captures" / "make_fixtures.py"
EXTENSION_CATALOG = REPO / "ZforgeFinderExtension" / "Localizable.xcstrings"
# Large enough to hold the shortcut menu and the submenu over the folder's own icons.
WINDOW = Rect(60, 60, 1400, 960)
# Other languages: wider, as their menus are wider and the archive may sort further right.
WIDE_WINDOW = Rect(20, 60, 1670, 960)
# The submenu's titles, in order, for an archive (FinderMenuPolicy).
SUBMENU_KEYS = ["Open", "Extract Here", 'Extract to "%@"', "Extract…", "Validate", "Add to Archive…"]
# Finder items whose titles show the menu's language (by action).
FINDER_ITEMS = ["cmdOpen:", "cmdMoveToTrash:", "cmdShowStaticInfo:", "cmdRename:", "cmdArchive:", "cmdDuplicate:",
                "cmdMakeAlias:", "cmdQuickLook:", "copy:", "cmdShare:"]


def preferred_languages() -> list[str]:
    data = subprocess.run(["defaults", "export", "-g", "-"], check=True, capture_output=True).stdout
    return list(plistlib.loads(data).get("AppleLanguages", []))


def set_preferred_languages(languages: list[str]) -> None:
    subprocess.run(["defaults", "write", "-g", "AppleLanguages", "-array", *languages], check=True)


def relaunch_finder() -> None:
    """Finder is relaunched by the system when it quits; the extension starts with it."""
    subprocess.run(["pkill", "-f", EXTENSION_EXECUTABLE], capture_output=True)
    subprocess.run(["killall", "Finder"], capture_output=True)
    time.sleep(1)
    wait_until(lambda: subprocess.run(["pgrep", "-x", "Finder"], capture_output=True).returncode == 0, 20,
               what="Finder to come back")
    time.sleep(3)


INSTALLED_EXTENSION = Path("/Applications/Zforge.app/Contents/PlugIns/ZforgeFinderExtension.appex")
EXTENSION_EXECUTABLE = "ZforgeFinderExtension.appex/Contents/MacOS/ZforgeFinderExtension"


def running_extension() -> Path | None:
    result = subprocess.run(["pgrep", "-fl", EXTENSION_EXECUTABLE], capture_output=True, text=True)
    for line in result.stdout.splitlines():
        executable = line.split(" ", 2)[1] if " " in line else ""
        if executable:
            return Path(executable).parents[2]
    return None


def catalog_titles(language: str) -> dict[str, str]:
    """The extension's titles in `language`, from the String Catalog (the current source)."""
    strings = json.loads(EXTENSION_CATALOG.read_text(encoding="utf-8"))["strings"]
    titles = {}
    for key, entry in strings.items():
        unit = entry.get("localizations", {}).get(language, {}).get("stringUnit", {})
        titles[key] = unit.get("value", key)
    return titles


def extension_titles(appex: Path, language: str) -> dict[str, str]:
    strings = appex / "Contents" / "Resources" / f"{language}.lproj" / "Localizable.strings"
    if not strings.exists():
        return {}
    data = subprocess.run(["plutil", "-convert", "json", "-o", "-", str(strings)], capture_output=True, text=True)
    return json.loads(data.stdout or "{}")


def expected_submenu(language: str, archive: str) -> list[str]:
    titles = catalog_titles(language)
    stem = archive.rsplit(".", 1)[0]
    return [titles[key].replace("%@", stem) if "%@" in key else titles[key] for key in SUBMENU_KEYS]


@contextmanager
def finder_session():
    """Finder with a Zforge extension built from the current source; restores the languages,
    the registration and Finder afterwards.

    When Zforge is installed in /Applications, Finder runs that copy's extension even when
    newer builds are registered; its registration is removed for the capture (pluginkit -r)
    and added back afterwards (pluginkit -a), so Finder runs a current build's extension.
    """
    original = preferred_languages()
    print(f"Preferred languages before: {original}")
    unregistered = False
    try:
        if INSTALLED_EXTENSION.exists():
            subprocess.run(["pluginkit", "-r", str(INSTALLED_EXTENSION)], check=True)
            unregistered = True
        yield original
    finally:
        set_preferred_languages(original)
        if unregistered:
            subprocess.run(["pluginkit", "-a", str(INSTALLED_EXTENSION)], check=False)
        relaunch_finder()
        after = preferred_languages()
        print(f"Preferred languages after: {after}")
        if after != original:
            print("WARNING: the preferred languages were not restored", file=sys.stderr)


def use_language(language: str, original: list[str]) -> Path:
    """Puts `language` first, relaunches Finder and checks the extension's titles."""
    set_preferred_languages([language] + [other for other in original if other != language])
    relaunch_finder()
    extension = wait_until(running_extension, 15, what="the Zforge Finder extension to start")
    expected = catalog_titles(language)
    shipped = extension_titles(extension, language)
    stale = [key for key in SUBMENU_KEYS if shipped.get(key) != expected[key]]
    if stale:
        raise RuntimeError(f"Finder runs an outdated Zforge extension ({extension}) for {language}: "
                           f"{stale}; build the app first")
    print(f"[{language}] Finder extension: {extension}")
    return extension


class Finder(Process):
    """Finder, driven only while it is the frontmost app."""

    def __init__(self, screen: ScreenTool) -> None:
        super().__init__(name="Finder")
        self.screen = screen

    @property
    def finder_pid(self) -> int:
        return int(subprocess.run(["pgrep", "-x", "Finder"], capture_output=True, text=True).stdout.split()[0])

    def guard(self) -> int:
        """Finder's pid, once it is the frontmost app; raises (nothing is sent) otherwise."""
        pid = self.finder_pid
        front = int(self.screen.run("frontmost").strip() or 0)
        if front != pid:
            raise RuntimeError(f"the frontmost app is pid {front}, not Finder ({pid}); not sending input")
        return pid

    def press(self, code: int, modifiers: str = "") -> None:
        """A key posted to Finder's process only."""
        pid = self.guard()
        self.screen.run("key", pid, code, modifiers)

    def click(self, x: float, y: float, right: bool = False) -> None:
        pid = self.guard()
        command = "saferightclick" if right else "safeclick"
        subprocess.run([str(self.screen.binary), command, str(pid), str(round(x)), str(round(y))], check=True)

    def open_fixture(self, folder: Path, window: Rect) -> None:
        subprocess.run(["open", str(folder)], check=True)
        wait_until(lambda: self.window_title() == folder.name, 10, what="the Finder window")
        self.activate()
        self.guard()
        self.set_window_frame(window.x, window.y, window.width, window.height)
        self.press(18, "cmd")  # ⌘1, Icons
        time.sleep(1.2)

    def close_window(self, folder: Path) -> None:
        if self.window_title() == folder.name:
            self.activate()
            self.press(13, "cmd")  # ⌘W
            time.sleep(0.5)

    def escape(self) -> None:
        try:
            self.press(53)
            time.sleep(0.15)
            self.press(53)
        except RuntimeError as error:
            print(f"Escape not sent: {error}", file=sys.stderr)

    def icon(self, folder: Path, name: str) -> Rect:
        """The icon of `name` in the window showing `folder` (accessibility, by file name)."""
        wanted = unicodedata.normalize("NFC", name)
        lines = [json.loads(line) for line in self.screen.run("axdump", self.finder_pid).splitlines() if line]
        windows = {line["window"] for line in lines if line["role"] == "AXWindow" and line["title"] == folder.name}
        for line in lines:
            if (line["window"] in windows and line["role"] == "AXImage"
                    and unicodedata.normalize("NFC", line["identifier"]) == wanted):
                return Rect(line["x"], line["y"], line["width"], line["height"])
        raise LookupError(f"{name} is not in the icon view")

    def menus(self) -> list[dict]:
        return [json.loads(line) for line in self.screen.run("axmenus", self.finder_pid).splitlines() if line]


def content_area(finder: Finder) -> Rect:
    """The icon view of the window: no sidebar, toolbar or tab bar."""
    values = finder.tell("set a to scroll area 1 of splitter group 1 of splitter group 1 of window 1 of p\n"
                         "return (position of a) & (size of a)")
    return Rect(*(float(value) for value in values.split(", ")))


def hover(finder: Finder, x: float, y: float) -> None:
    """Moves the pointer in steps, as a hand would, so the menu tracks it."""
    finder.guard()
    screen = finder.screen
    start_x, start_y = screen.pointer()
    for step in range(1, 9):
        screen.move(start_x + (x - start_x) * step / 8, start_y + (y - start_y) * step / 8)
        time.sleep(0.04)


class Scene:
    """One language: its fixture, its raw and framed outputs and the frame shared by both
    appearances (the menu opens at the same place in both, so both pictures have one shape)."""

    def __init__(self, language: str, parent: Path, out: Path) -> None:
        self.language = language
        strings = Strings(language)
        self.parent = parent
        self.folder = parent / strings.name("documents")
        self.archive = strings.name("photosArchive")
        default = language == DEFAULT_LANGUAGE
        self.window = WINDOW if default else WIDE_WINDOW
        self.raw_folder = CAPTURES if default else CAPTURES / language
        self.out = out if default else out / language
        self.frame: Rect | None = None
        self.report: dict = {"language": language, "folder": self.folder.name, "archive": self.archive,
                             "pictures": {}, "issues": []}

    def make_fixture(self) -> None:
        subprocess.run([sys.executable, str(MAKE_FIXTURES), "--lang", self.language, str(self.parent)], check=True)


def capture(finder: Finder, scene: Scene, theme: str) -> Path:
    finder.open_fixture(scene.folder, scene.window)
    area = content_area(finder)
    try:
        return capture_menu(finder, scene, area, theme)
    except Exception:
        # Only the folder's icon view (the fixture), never the rest of the screen.
        debug = capture_region(area, Path(tempfile.gettempdir()) / f"zforge-finder-menu-failure-{scene.language}.png")
        print(f"The capture failed; the icon view is in {debug}", file=sys.stderr)
        finder.escape()
        raise
    finally:
        finder.close_window(scene.folder)


def capture_menu(finder: Finder, scene: Scene, area: Rect, theme: str) -> Path:
    icon = wait_until(lambda: _try(lambda: finder.icon(scene.folder, scene.archive)), 10,
                      what=f"{scene.archive} in Finder")
    finder.click(icon.x + icon.width / 2, icon.y + icon.height / 2)  # selects it
    time.sleep(0.6)
    # On its name, below the icon, as the Brazilian Portuguese picture was made.
    finder.click(icon.x + icon.width / 2, icon.bottom + 14, right=True)
    items = wait_until(lambda: [item for item in finder.menus() if item["width"] > 0] or None, 5,
                       what="the shortcut menu")
    zforge = next((item for item in items if item["level"] == 0 and item["title"] == "Zforge"), None)
    if zforge is None:
        raise RuntimeError("the shortcut menu has no Zforge item")
    hover(finder, zforge["x"] + 30, zforge["y"] + zforge["height"] / 2)
    time.sleep(0.3)

    def submenu_open():
        menus = finder.menus()
        sub_menu, sub_items = zforge_submenu(menus)
        selected = any(item["title"] == "Zforge" and item["selected"] for item in menus if item["level"] == 0)
        return menus if sub_menu and sub_items and selected else None
    wait_until(submenu_open, 5, what="the Zforge submenu")
    time.sleep(0.9)  # The submenu's appearance animation.
    menus = finder.menus()
    main = [item for item in menus if item["level"] == 0 and item["width"] > 0 and item["role"] == "AXMenuItem"]
    sub_menu, sub_items = zforge_submenu(menus)
    if sub_menu is None:
        raise RuntimeError("the Zforge submenu closed before the capture")

    # Titles: the submenu must be the catalog's, in order; Finder's items show its language.
    # Compared in NFC: accessibility may give a title decomposed (Hangul, ó, ğ) that reads the same.
    shown = [unicodedata.normalize("NFC", item["title"]) for item in sub_items]
    expected = [unicodedata.normalize("NFC", title) for title in expected_submenu(scene.language, scene.archive)]
    if shown != expected:
        scene.report["issues"].append({"theme": theme, "submenu": shown, "expected": expected})
        print(f"[{scene.language}] the submenu differs from the catalog: {shown} != {expected}", file=sys.stderr)
    english = catalog_titles("en")
    untranslated = [title for title, key in zip(shown, SUBMENU_KEYS)
                    if scene.language != "en" and title == english[key].replace("%@", scene.archive.rsplit(".", 1)[0])]
    scene.report["submenu"] = shown
    scene.report["untranslatedSubmenu"] = untranslated
    seen = set()
    finder_titles = {}
    for item in main:
        if item["identifier"] in FINDER_ITEMS and item["identifier"] not in seen:
            seen.add(item["identifier"])
            finder_titles[item["identifier"]] = item["title"]
    scene.report["finder"] = finder_titles

    raw = capture_region(area, scene.raw_folder / f"finder-menu-{theme}.png")
    # The picture: the menu from its Compress item down, the highlighted Zforge item and the
    # whole submenu, with some of the folder around. The cut falls between two items (Rename
    # and Compress), never through one; the whole menu, from the selected icon down, would
    # be too small to read in the gallery's tile. Margins as in the Brazilian Portuguese
    # picture of 2026-11-17: 26 points left of the menu, 28 right of the submenu and 26
    # below it.
    if scene.frame is None:
        compress = next(item for item in main if item["identifier"] == "cmdArchive:")
        menu_left = min(item["x"] for item in main)
        if sub_menu["x"] < menu_left:
            raise RuntimeError("the submenu opened on the left of the menu (the archive sorts too far right in "
                               "the folder; give it a name that sorts earlier in fixture_names.json)")
        left = menu_left - 26
        top = compress["y"]
        right = sub_menu["x"] + sub_menu["width"] + 28
        bottom = sub_menu["y"] + sub_menu["height"] + 26
        scene.frame = Rect(round(left), round(top), round(right - left), round(bottom - top))
        # Only the fixture's icon view may appear in the picture.
        if (scene.frame.x < area.x or scene.frame.y < area.y or scene.frame.right > area.right
                or scene.frame.bottom > area.bottom):
            raise RuntimeError(f"the picture {scene.frame} leaves the icon view {area}")
    picture = capture_region(scene.frame, scene.out / f"finder-{THEMES[theme]}.png")
    scene.report["pictures"][theme] = str(picture)
    scene.report["framePoints"] = [scene.frame.x, scene.frame.y, scene.frame.width, scene.frame.height]
    scene.report["menuItems"] = [{key: item[key] for key in ("level", "identifier", "title", "x", "y", "width",
                                                             "height")} for item in main + [sub_menu] + sub_items]
    print(raw)
    finder.escape()
    time.sleep(0.4)
    return picture


def zforge_submenu(menus: list[dict]) -> tuple[dict | None, list[dict]]:
    """The Zforge item's submenu and its items: the records that follow that item in
    axmenus's output (another submenu, such as Open With's, may also report a frame)."""
    menu, items, inside = None, [], False
    for record in menus:
        if record["level"] == 0:
            if inside:
                break
            inside = record["role"] == "AXMenuItem" and record["title"] == "Zforge"
        elif inside and record["level"] == 1:
            if record["role"] == "AXMenu" and menu is None:
                menu = record
            elif record["role"] == "AXMenuItem" and record["width"] > 0:
                items.append(record)
    return (menu if menu and menu["width"] > 0 else None), items


def _try(function):
    try:
        return function()
    except LookupError:
        return None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", type=Path, default=Path(tempfile.gettempdir()) / "zforge-website-captures")
    parser.add_argument("--theme", action="append", choices=list(THEMES), help="only these appearances")
    parser.add_argument("--lang", action="append", choices=languages() + ["all", "others"],
                        help="app languages to capture (repeatable; 'all' is every language of "
                             "fixture_names.json, 'others' every one but pt-BR); default pt-BR")
    arguments = parser.parse_args()
    out = arguments.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    requested = arguments.lang or [DEFAULT_LANGUAGE]
    if "all" in requested:
        requested = languages()
    elif "others" in requested:
        requested = [language for language in languages() if language != DEFAULT_LANGUAGE]

    temporary = Path(tempfile.mkdtemp(prefix="zforge-finder-menu-"))
    scenes = [Scene(language, FIXTURE_PARENT if language == DEFAULT_LANGUAGE else temporary / language, out)
              for language in requested]
    screen = ScreenTool()
    pointer = screen.pointer()
    finder = Finder(screen)
    reports = []
    try:
        with appearance_restored(), finder_session() as original:
            current = "dark" if dark_mode() else "light"
            themes = arguments.theme or [current, "light" if current == "dark" else "dark"]
            for scene in scenes:
                scene.make_fixture()
                scene.report["extension"] = str(use_language(scene.language, original))
                try:
                    for theme in themes:
                        set_dark_mode(theme == "dark")
                        print(capture(finder, scene, theme))
                except Exception as error:  # Another language may still succeed.
                    scene.report["issues"].append({"error": f"{type(error).__name__}: {error}"})
                    print(f"[{scene.language}] failed: {error}", file=sys.stderr)
                    if isinstance(error, RuntimeError) and "frontmost app" in str(error):
                        raise
                finally:
                    reports.append(scene.report)
                    if scene.language != DEFAULT_LANGUAGE:
                        (scene.raw_folder / "menu.json").parent.mkdir(parents=True, exist_ok=True)
                        (scene.raw_folder / "menu.json").write_text(
                            json.dumps(scene.report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
                        shutil.rmtree(scene.parent, ignore_errors=True)
    finally:
        screen.move(*pointer)
        screen.close()
        shutil.rmtree(temporary, ignore_errors=True)
        (out / "finder-menu-report.json").write_text(json.dumps(reports, ensure_ascii=False, indent=2) + "\n",
                                                     encoding="utf-8")
        print(out / "finder-menu-report.json")


if __name__ == "__main__":
    main()
