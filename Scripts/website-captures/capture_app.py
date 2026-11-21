#!/usr/bin/env python3
"""Captures the real Zforge window for the website's feature gallery.

The website (../../../zforge-website, section "O que mais o Zforge faz") shows
real captures of the app in the light and dark appearances. This script:

1. creates the sample folder /Users/Shared/Documentos (make_fixtures.py), whose
   path bar reads "Macintosh HD › Usuários › Compartilhado › Documentos", so no
   capture shows the user's home or name;
2. builds the app (Debug, into a temporary DerivedData) unless --app is given;
3. launches a second, isolated copy of Zforge in Brazilian Portuguese. The
   `--ui-window-width` argument makes it a UI-test launch: its preferences and
   folder grants live in the private suite UI tests use, cleared at launch, so
   the user's own preferences, grants and running Zforge are not touched. The
   sidebar hides the computer, the home folder, external disks and servers
   (Settings ▸ Sidebar, passed as launch arguments), and the Tags section lists
   only the fixture's tags, since only the fixture folder is granted;
4. grants the fixture folder through the open panel, then drives the window
   into each scene with GUI scripting and captures it, first in the current
   appearance and then in the other one; the system appearance is restored;
5. quits the copy, removes the fixture folder and the temporary build.

Output: <out>/<id>-light.png and <id>-dark.png at the display's density
(2x on a Retina display), already framed; the website's
scripts/import-feature-captures.mjs scales them to the gallery's tiles and
encodes them as WebP. The Finder scene has its own script in
Documentation/FinderMenuScene (--finder runs it after the app scenes, while the
build and its Finder extension still exist).

Needs: Xcode, an unlocked session, and the Accessibility and Screen Recording
permissions for the terminal. It moves the pointer and brings windows to the
front for about ten minutes: do not use the Mac meanwhile.

    Scripts/website-captures/capture_app.py [--out DIR] [--app Zforge.app] [--finder]
                                             [--scene ID …] [--theme light|dark]
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
import unicodedata
from pathlib import Path

from support import (REPO, THEMES, Process, Rect, ScreenTool, appearance_restored, capture_region,
                     capture_window, capture_window_part, crop_window_capture, dark_mode, set_dark_mode, wait_until)

FIXTURE_PARENT = Path("/Users/Shared")
FIXTURE = FIXTURE_PARENT / "Documentos"
# Top-left corner of the window, away from the menu bar, the Dock and the
# corner where notifications appear.
ORIGIN = (80, 90)

# Settings ▸ Sidebar: only the startup disk stays under Locations.
LAUNCH_ARGUMENTS = [
    "--ui-window-width", "900",
    "-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR",
    "-appLanguagePreference", "system",
    "-browser.hiddenSidebarLocations", "(computer, home, externalDisks, connectedServers)",
]


def build(derived_data: Path) -> Path:
    subprocess.run(["xcodebuild", "-project", str(REPO / "Zforge.xcodeproj"), "-scheme", "Zforge",
                    "-configuration", "Debug", "-destination", "platform=macOS,arch=arm64",
                    "-derivedDataPath", str(derived_data), "-quiet", "build"], check=True)
    return derived_data / "Build" / "Products" / "Debug" / "Zforge.app"


class Zforge(Process):
    def __init__(self, app: Path, screen: ScreenTool) -> None:
        super().__init__()
        self.app = app
        self.screen = screen

    # Keyboard and activation, by pid. System Events activates a process through its bundle
    # identifier, which this copy shares with a Zforge the user may have open: `set frontmost`
    # then brings the user's app forward and its keystrokes reach that app (a run once sent ⌘Q
    # to it). The screen tool activates by pid and posts keys to this copy only.

    def activate(self) -> None:
        wait_until(lambda: subprocess.run([str(self.screen.binary), "activate", str(self.pid)]).returncode == 0,
                   5, what="this copy to come forward")
        time.sleep(0.2)

    @staticmethod
    def _modifiers(modifiers: str) -> str:
        names = {"command down": "cmd", "shift down": "shift", "option down": "alt", "control down": "ctrl"}
        return ",".join(names[part.strip()] for part in modifiers.split(",") if part.strip())

    def _guard(self) -> None:
        """Every key and click is for this copy only: it must be the frontmost app (brought
        forward by pid if it is not), or nothing is sent."""
        front = int(self.screen.run("frontmost").strip() or 0)
        if front != self.pid:
            self.activate()
            front = int(self.screen.run("frontmost").strip() or 0)
        if front != self.pid:
            raise RuntimeError(f"the frontmost app is pid {front}, not this copy ({self.pid}); not sending input")

    def keystroke(self, text: str, modifiers: str = "") -> None:
        self._guard()
        if modifiers:
            codes = {"g": 5, "p": 35, "1": 18, "2": 19, "3": 20, "4": 21}
            self.screen.run("key", self.pid, codes[text], self._modifiers(modifiers))
        else:
            self.screen.run("type", self.pid, text)

    def key(self, code: int, modifiers: str = "") -> None:
        self._guard()
        self.screen.run("key", self.pid, code, self._modifiers(modifiers))

    # Window, texts and menus, by pid (the accessibility API through the screen tool).

    def tell(self, body: str) -> str:
        raise RuntimeError("System Events resolves a pid to the app's bundle identifier and may reach "
                           "the user's own Zforge: use the screen tool's ax commands")

    def ax(self) -> list[dict]:
        return [json.loads(line) for line in self.screen.run("axdump", self.pid).splitlines() if line.strip()]

    def _window(self) -> dict:
        return json.loads(self.screen.run("axwindow", self.pid))

    def window_frame(self, index: int = 1) -> Rect:
        window = self._window()
        return Rect(window["x"], window["y"], window["width"], window["height"])

    def set_window_frame(self, x: float, y: float, width: float, height: float, index: int = 1) -> None:
        self.screen.run("axframe", self.pid, round(x), round(y), round(width), round(height))
        time.sleep(0.5)

    def window_title(self, index: int = 1) -> str:
        try:
            return self._window()["title"]
        except (subprocess.CalledProcessError, ValueError):
            return ""  # No window at this moment (an alert or panel is closing).

    def sheet_count(self) -> int:
        return self._window()["sheets"]

    def sheet_frame(self) -> Rect:
        sheet = next(e for e in self.ax() if e["role"] == "AXSheet")
        return Rect(sheet["x"], sheet["y"], sheet["width"], sheet["height"])

    def texts(self, scope: str = "") -> list[tuple[str, Rect]]:
        # File names come decomposed (NFD) from the file system: compare composed text.
        return [(unicodedata.normalize("NFC", e["value"] or e["title"]),
                 Rect(e["x"], e["y"], e["width"], e["height"]))
                for e in self.ax() if e["role"] == "AXStaticText"]

    def find_text(self, text: str, scope: str = "") -> Rect | None:
        wanted = unicodedata.normalize("NFC", text)
        return next((rect for value, rect in self.texts() if value == wanted and rect.width > 0), None)

    def menu_item_names(self, index: int) -> list[str]:
        return self.screen.run("axmenu", self.pid, index).splitlines()

    def click(self, x: float, y: float, command: bool = False) -> None:
        """A click on this copy's window only: refused when another window is in front there."""
        self._guard()
        self.screen.run("safeclick", self.pid, round(x), round(y), *(["cmd"] if command else []))

    # Launch and quit.

    def launch(self) -> None:
        executable = str(self.app / "Contents" / "MacOS" / "Zforge")
        before = set(self._pids(executable))
        subprocess.run(["open", "-n", "-F", "-a", str(self.app), "--args", *LAUNCH_ARGUMENTS], check=True)
        self.pid = wait_until(lambda: next(iter(set(self._pids(executable)) - before), None), 20,
                              what="Zforge to launch")
        wait_until(lambda: self.screen.windows(self.pid), 20, what="the first window")
        time.sleep(1.5)

    @staticmethod
    def _pids(executable: str) -> list[int]:
        result = subprocess.run(["pgrep", "-f", executable], capture_output=True, text=True)
        return [int(pid) for pid in result.stdout.split()]

    def quit(self) -> None:
        if self.pid is None:
            return
        try:
            # The application menu's last item (Encerrar Zforge), of this copy only (by pid).
            titles = [title for title in self.screen.run("axmenu", self.pid, 1).splitlines() if title]
            self.screen.run("axmenupress", self.pid, 1, titles[-1])
            wait_until(lambda: subprocess.run(["kill", "-0", str(self.pid)], capture_output=True).returncode,
                       20, what="Zforge to quit")
        except Exception:
            subprocess.run(["kill", str(self.pid)], capture_output=True)
        self.pid = None

    def grant_fixture(self) -> None:
        """A fresh suite has no grant: the launch asks for the home folder in an open panel.
        Choosing the fixture there and going to it gives the window access to it. The panel is
        drawn by another process (the open panel service): it gets the keyboard focus by a click
        and the keys are posted to whatever has the focus, after checking that it is this copy
        or the panel service, never another app."""
        try:
            panel = wait_until(lambda: next((w for w in self.screen.windows(self.pid) if "acesse" in w["name"]),
                                            None), 12, what="the open panel")
        except TimeoutError:
            panel = None
        if panel:
            # A point of the panel's title bar where the panel itself is in front: another
            # app's window may cover part of it (the copy is brought forward by pid first).
            candidates = [(round(panel["x"] + panel["width"] * fraction), round(panel["y"] + 22))
                          for fraction in (0.6, 0.5, 0.7, 0.4, 0.8, 0.3, 0.9, 0.2)]
            def panel_point():
                self.activate()
                for candidate in candidates:
                    owner = int(self.screen.run("owner", *candidate).strip() or 0)
                    if owner == self.pid or self._is_panel_service(owner):
                        return candidate, owner
                return None
            try:
                point, owner = wait_until(panel_point, 8, what="a part of the open panel in front")
            except TimeoutError:
                point = candidates[0]
                owner = int(self.screen.run("owner", *point).strip() or 0)
            if owner != self.pid and not self._is_panel_service(owner):
                name = subprocess.run(["ps", "-o", "comm=", "-p", str(owner)], capture_output=True,
                                      text=True).stdout.strip()
                raise RuntimeError(f"another app's window ({owner} {name}) covers the open panel; "
                                   "not clicking there")
            self.screen.click(*point)
            time.sleep(0.6)
            self._check_focus()
            self.screen.run("hidkey", 5, "cmd,shift")  # ⇧⌘G: go to a folder.
            time.sleep(1.2)
            self._check_focus()
            self.screen.run("hidtype", str(FIXTURE))
            time.sleep(0.6)
            self.screen.run("hidkey", 36)  # Return: go there.
            time.sleep(1.5)
            self._check_focus()
            self.screen.run("hidkey", 36)  # Return: Abrir.
            time.sleep(2)
            # The panel asked for the home folder: an alert may say it cannot use the choice.
            if any(w["width"] < 600 and w["layer"] == 0 for w in self.screen.windows(self.pid)):
                self.key(36)
                time.sleep(1)
        self.go_to(FIXTURE)

    @staticmethod
    def _is_panel_service(pid: int) -> bool:
        path = subprocess.run(["ps", "-o", "comm=", "-p", str(pid)], capture_output=True, text=True).stdout
        return "openAndSavePanelService" in path

    def _check_focus(self) -> None:
        front = int(self.screen.run("frontmost").strip() or 0)
        if front != self.pid and not self._is_panel_service(front):
            raise RuntimeError(f"the keyboard focus is in another app (pid {front}); not typing there")

    def go_to(self, folder: Path) -> None:
        self.activate()
        self.keystroke("g", "command down, shift down")
        time.sleep(1)
        self.keystroke(str(folder))
        time.sleep(0.5)
        self.key(36)
        wait_until(lambda: self.window_title() == folder.name, 10, what=f"the window to show {folder.name}")
        time.sleep(1)

    # Driving the window.

    def frame(self, width: float, height: float) -> Rect:
        self.set_window_frame(ORIGIN[0], ORIGIN[1], width, height)
        return self.window_frame()

    def view(self, mode: str) -> None:
        """Icons, list, columns or gallery, from the View menu (⌘1 to ⌘4)."""
        self.activate()
        self.keystroke({"icons": "1", "list": "2", "columns": "3", "gallery": "4"}[mode], "command down")
        time.sleep(0.8)

    def preview(self, visible: bool) -> None:
        # The View menu is the menu bar's fifth item (Apple, Zforge, Arquivo, Editar,
        # Visualizar, index 4); its titles follow the system's languages, not the window's.
        names = self.menu_item_names(4)
        shown = "Ocultar Pré-visualização" in names or "Hide Preview" in names
        if shown != visible:
            self.activate()
            self.keystroke("p", "command down, shift down")
            time.sleep(0.8)

    def click_item(self, name: str) -> Rect:
        rect = wait_until(lambda: self.find_text(name), 8, what=f"the item {name}")
        self.click(*rect.center)
        time.sleep(0.5)
        return rect

    def park_pointer(self) -> None:
        """Out of the window, so no hover highlight shows in a capture."""
        frame = self.window_frame()
        self.screen.move(frame.right + 60, frame.bottom + 40)
        time.sleep(0.4)

    def context_menu(self, item: str) -> None:
        rect = self.click_item(item)
        self._guard()
        self.screen.right_click(*rect.center)
        time.sleep(0.8)

    def menu_area(self) -> Rect:
        """Where a menu opened in the window can be: the window and some room beside it."""
        frame = self.window_frame()
        return Rect(frame.x, frame.y, frame.width + 420, frame.height + 260)

    def choose_menu_item(self, title: str) -> None:
        """Clicks an item of the open menu. SwiftUI's context and toolbar menus are not
        reachable by GUI scripting, so the item is found on the screen by its title."""
        item = wait_until(lambda: self.screen.find(self.menu_area(), title), 5, what=f"the menu item {title}")
        self._guard()
        self.screen.run("safeclick", self.pid, round(item.center[0]), round(item.center[1]))
        time.sleep(0.6)

    def window_id(self) -> int:
        """The browser window: the largest of the process's windows (a toast is a small one)."""
        return max(self.screen.windows(self.pid), key=lambda entry: entry["width"] * entry["height"])["id"]

    def content_part(self, frame: Rect, ratio: float) -> Rect:
        """The content beside the sidebar, toolbar included, `ratio` wide for its height."""
        left = self.content_left()
        width = frame.right - left
        return Rect(left, frame.y, width, width / ratio)

    def capture_content(self, frame: Rect, ratio: float, out: Path) -> Path:
        return capture_window_part(self.window_id(), frame, self.content_part(frame, ratio), out)

    def content_left(self) -> float:
        """The x where the content starts: the sidebar's splitter."""
        splitter = next(e for e in self.ax() if e["role"] == "AXSplitter" and e["window"] == 0)
        return splitter["x"] + splitter["width"]


SCENES = ["manager", "editing", "integrity", "volumes", "password"]


def scene_manager(app: Zforge, out: Path) -> Path:
    """Gerenciador de arquivos completo: the whole window, Icons with the sidebar.
    At 736 × 512 points (the smallest height) the nine items fit in three rows."""
    app.go_to(FIXTURE)
    app.frame(736, 512)
    app.view("icons")
    app.preview(False)
    app.click_item("Capa.png")
    app.park_pointer()
    return capture_window(app.window_id(), out)


def scene_edit(app: Zforge, out: Path) -> Path:
    """Edição sem extrair: the content of Fotos-2025.7z in the List, as a folder's."""
    app.go_to(FIXTURE)
    frame = app.frame(900, 560)
    app.view("list")
    app.preview(False)
    app.click_item("Fotos-2025.7z")
    app.key(125, "command down")  # ⌘↓ opens the selected archive in the window.
    wait_until(lambda: app.window_title() == "Fotos-2025.7z", 10, what="the archive to open")
    time.sleep(1)
    for folder in ["viagem", "retratos"]:
        app.click_item(folder)
        app.key(124)  # → expands the folder in its row.
        time.sleep(1)
    app.click_item("grupo.jpg")
    app.park_pointer()
    return app.capture_content(frame, 16 / 10, out)


def scene_integrity(app: Zforge, out: Path) -> Path:
    """Teste de integridade: the toast after validating Fotos-2025.7z.

    The toast stays two seconds: the window is captured over and over from the click on
    Validar, and the frame kept is one in the middle of those that show the toast."""
    app.go_to(FIXTURE)
    frame = app.frame(900, 560)
    app.view("list")
    app.preview(False)
    part = app.content_part(frame, 16 / 10)
    toast = "Arquivos compactados validados com sucesso."
    window_id = app.window_id()
    with tempfile.TemporaryDirectory(prefix="zforge-toast-") as folder:
        app.context_menu("Fotos-2025.7z")
        app.choose_menu_item("Validar")
        app.park_pointer()
        frames = []
        start = time.monotonic()
        while time.monotonic() - start < 4:
            frames.append(capture_window(window_id, Path(folder) / f"frame-{len(frames):02d}.png"))
        showing = [shot for shot in frames if app.screen.find_in(shot, toast)]
        if not showing:
            raise RuntimeError("no frame shows the validation toast")
        return crop_window_capture(showing[len(showing) // 2], frame, part, out)


def scene_volumes(app: Zforge, out: Path) -> Path:
    """Arquivos divididos em volumes: Columns, Projeto.7z.001 open in the next column."""
    app.go_to(FIXTURE)
    frame = app.frame(1000, 560)
    app.view("columns")
    app.preview(False)
    app.click_item("Projetos")
    time.sleep(1)
    app.click_item("Projeto.7z.001")
    time.sleep(1.5)
    app.park_pointer()
    # The three columns fill the top of the window: the frame is wide (2:1).
    return app.capture_content(frame, 2, out)


def scene_password(app: Zforge, out: Path) -> Path:
    """Proteção por senha: the sheet of Comprimir customizado… with Proteger com senha on
    and both fields filled, framed from the profile section down, with some window around."""
    app.go_to(FIXTURE)
    frame = app.frame(1000, 680)
    app.view("list")
    app.preview(True)
    app.context_menu("Projetos")
    app.choose_menu_item("Comprimir customizado…")
    wait_until(lambda: app.sheet_count() > 0, 10, what="the sheet")
    time.sleep(1)
    checkbox = wait_until(lambda: app.screen.find(frame, "Proteger com senha"), 5, what="the checkbox")
    app.click(checkbox.x - 12, checkbox.y + checkbox.height / 2)
    time.sleep(0.8)
    for field in ["Senha", "Confirmar senha"]:
        placeholder = wait_until(lambda: app.screen.find(frame, field), 5, what=f"the field {field}")
        app.click(*placeholder.center)
        time.sleep(0.3)
        app.keystroke("photos2025")
        time.sleep(0.3)
    app.park_pointer()
    sheet = app.sheet_frame()
    profile = wait_until(lambda: app.screen.find(frame, "Perfil de compactação"), 5, what="the profile row")
    # The sheet's divider is about 16 points above the profile row: the frame starts there.
    margin = 16
    top = profile.y - 15
    path = capture_region(Rect(sheet.x - margin, top, sheet.width + 2 * margin, sheet.bottom + margin - top), out)
    app.key(53)  # Escape cancels the sheet.
    time.sleep(0.8)
    return path


RUNNERS = {
    "manager": scene_manager,
    "editing": scene_edit,
    "integrity": scene_integrity,
    "volumes": scene_volumes,
    "password": scene_password,
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", type=Path, default=Path(tempfile.gettempdir()) / "zforge-website-captures")
    parser.add_argument("--app", type=Path, help="an already built Zforge.app (skips the build)")
    parser.add_argument("--scene", action="append", choices=SCENES, help="only these scenes")
    parser.add_argument("--theme", action="append", choices=list(THEMES), help="only these appearances")
    parser.add_argument("--keep", action="store_true", help="leave the copy running and the fixture in place")
    parser.add_argument("--finder", action="store_true",
                        help="then run Documentation/FinderMenuScene/capture_finder_menu.py, while the build "
                             "(and its Finder extension) still exists")
    arguments = parser.parse_args()

    scenes = arguments.scene or SCENES
    out = arguments.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    derived_data = None
    if arguments.app:
        app_path = arguments.app.resolve()
    else:
        derived_data = Path(tempfile.mkdtemp(prefix="zforge-website-build-"))
        app_path = build(derived_data)

    subprocess.run([sys.executable, str(Path(__file__).with_name("make_fixtures.py")), str(FIXTURE_PARENT)],
                   check=True)
    screen = ScreenTool()
    app = Zforge(app_path, screen)
    pointer = screen.pointer()
    try:
        with appearance_restored():
            current = "dark" if dark_mode() else "light"
            themes = arguments.theme or [current, "light" if current == "dark" else "dark"]
            app.launch()
            app.grant_fixture()
            for theme in themes:
                set_dark_mode(theme == "dark")
                for scene in scenes:
                    path = RUNNERS[scene](app, out / f"{scene}-{THEMES[theme]}.png")
                    print(path)
        if not arguments.keep:
            app.quit()
        if arguments.finder:
            finder = REPO / "Documentation" / "FinderMenuScene" / "capture_finder_menu.py"
            command = [sys.executable, str(finder), "--out", str(out)]
            for theme in arguments.theme or []:
                command += ["--theme", theme]
            subprocess.run(command, check=True)
    finally:
        screen.move(*pointer)
        if not arguments.keep:
            app.quit()
            shutil.rmtree(FIXTURE, ignore_errors=True)
        screen.close()
        if derived_data:
            shutil.rmtree(derived_data, ignore_errors=True)


if __name__ == "__main__":
    main()
