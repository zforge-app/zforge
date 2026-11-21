#!/usr/bin/env python3
"""Captures the real Zforge window in each frame of the website's demonstration.

The website's animated demonstration (zforge-website, src/content/story.tsx)
draws the Zforge window in HTML (AkariDS FileWindow) at a design size of
1000 × 625 px. To keep that drawing true to the app, this script puts a real
Zforge window of 1000 × 625 points into the state of each frame, on the same
sample folder the demonstration shows (make_fixtures.py, in
/Users/Shared/Documentos), and captures it in the light and dark appearances.
The website's scripts/compare-demo-window.mjs renders the drawing of each frame
at the same size and compares the two.

Like capture_app.py (whose app driver it reuses), it builds the app into a
temporary DerivedData unless --app is given, launches a second, isolated copy
of Zforge in Brazilian Portuguese with its own preferences and grants (a UI-test
launch), grants the fixture folder through the open panel, drives the window
with GUI scripting, mouse events and the keyboard (all addressed to that copy's
process), and afterwards quits the copy, restores the appearance and removes the
fixture and the build. The user's own Zforge, if running, is never addressed.

Frames that only last a moment are caught by capturing the window over and
over: the toasts (two seconds), the progress panels (the operation runs on a
large file: for the extraction, a copy of Fotos-2025.7z whose leia-me.txt ends
in 3 GB of zeros, so the archive's size cell reads about 0.5 MB more than in the
other frames; for the compression, Capa.png followed by 3 GB of zeros after its
end, which the PNG decoder ignores, so the size cell of Capa.png reads 3 GB in
that frame only; both are put back afterwards) and the pressed toolbar button
(the button is pressed and held, captured, then dragged away and released, which
cancels the click).

Every key and click goes to the copy only: keys are posted to its process, and
before each key or click the copy must be the frontmost app (brought forward by
pid, never by bundle identifier, which a Zforge the user has open shares), or the
script stops without sending it. A plain grey window of the screen tool lies under
the copy's window while it runs, and each frame is the screen where the window
is, with the window's own transparent corners: the translucent sidebar and panes
show that grey instead of the user's desktop. In the sheet frames the name the
demonstration shows, Entrega.zip, is typed over the proposed one.

Output, in --out DIR (default $TMPDIR/zforge-demo-frames):
  <frame>-light.png, <frame>-dark.png   the window and what it shows over itself
                                         (sheet, menu, toast), 2000 × 1250 px on
                                         a Retina display, corners transparent
  <frame>.ax.json                        accessibility frames of the window's
                                         elements, in points from its top left
  <frame>.noise.json                     rectangles (points) the comparison
                                         masks: dates of the capture day and the
                                         sizes of a swapped file
<frame> is the demonstration's own id, "<chapter id>-<checkpoint index>", or the name of an
extra scene compared with a drawing of the same state (extra-password-sheet: the compression
sheet with "Proteger com senha" on and a password typed in both fields; only with --frame).

    Scripts/website-captures/capture_demo_frames.py [--out DIR] [--app Zforge.app]
                                                     [--frame ID …] [--theme light|dark]

Needs: Xcode, an unlocked session, the Accessibility and Screen Recording
permissions of the terminal, and about 7 GB free on the startup disk while it
runs. It moves the pointer and brings the copy to the front for several
minutes: do not use the Mac meanwhile.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import unicodedata
from datetime import date
from pathlib import Path

from capture_app import FIXTURE, FIXTURE_PARENT, Zforge, build
from support import (THEMES, Rect, ScreenTool, appearance_restored, capture_region, capture_window,
                     dark_mode, image_size,
                     set_dark_mode, wait_until)

WIDTH, HEIGHT = 1000, 625
SCALE = 2  # pixels per point of the captures (a Retina display)
BACKDROP_GREY = 0.5  # the neutral screen behind the window (0 black, 1 white)
PAD = 3 * 1024 ** 3  # zeros that make an operation last long enough to be seen
SEVEN_ZIP_BUILD = None


class Driver(Zforge):
    """The capture_app driver, with the demonstration's gestures."""

    def main_window(self) -> dict:
        return max(self.screen.windows(self.pid), key=lambda entry: entry["width"] * entry["height"])

    def place(self) -> Rect:
        return self.frame(WIDTH, HEIGHT)

    def ax_elements(self) -> list[dict]:
        """Every element of the copy's windows (sheets included) with its role, names and
        frame, in points from the main window's top left."""
        frame = self.window_frame()
        elements = self.ax()
        for element in elements:
            element["x"] -= frame.x
            element["y"] -= frame.y
        return elements

    def item(self, name: str) -> Rect:
        return wait_until(lambda: self.find_text(name), 8, what=f"the item {name}")

    def select(self, *names: str) -> None:
        """Selects the items named, the first by a click and the others by ⌘-clicks."""
        self.activate()
        for index, name in enumerate(names):
            rect = self.item(name)
            self.click(*rect.center, command=index > 0)
            time.sleep(0.4)

    def deselect(self) -> None:
        """A click on the empty foot of the list (left of the preview pane) clears the
        selection."""
        frame = self.window_frame()
        self.click(self.content_left() + 150, frame.bottom - 90)
        time.sleep(0.4)

    def expand(self, name: str) -> None:
        """→ on the selected row expands it in the List."""
        self.select(name)
        self.key(124)
        time.sleep(1.2)

    def toolbar_button(self, *descriptions: str) -> Rect:
        """A button of the window's toolbar, by its accessibility description or name."""
        def look():
            for element in self.ax_elements():
                if element["role"] in {"AXButton", "AXMenuButton"} and element["y"] < 60 and (
                        element["description"] in descriptions or element["title"] in descriptions
                        or element["help"] in descriptions):
                    frame = self.window_frame()
                    return Rect(element["x"] + frame.x, element["y"] + frame.y, element["width"],
                                element["height"])
            return None
        return wait_until(look, 8, what=f"the toolbar button {descriptions}")

    def burst(self, seconds: float, folder: Path) -> list[Path]:
        """Captures the window over and over for `seconds` (a frame each ~0.2 s)."""
        shots = []
        start = time.monotonic()
        while time.monotonic() - start < seconds:
            shots.append(self.composite(folder / f"burst-{len(shots):03d}.png"))
        return shots

    def composite(self, out: Path) -> Path:
        """The main window with what it shows over itself, cut to the main window. A capture
        of a window by its id holds its child windows too (an open sheet or menu): when a
        child reaches past the window (a menu), the capture covers their union, and the
        window is cut out of it."""
        windows = self.screen.windows(self.pid)
        main = max(windows, key=lambda entry: entry["width"] * entry["height"])
        out.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="zforge-frame-") as folder:
            # The screen where the window is: its translucent sidebar and panes show the
            # neutral backdrop under it (a capture of the window alone blends them with the
            # desktop picture instead); the window's capture gives the transparent corners.
            screen_shot = capture_region(Rect(main["x"], main["y"], main["width"], main["height"]),
                                         Path(folder) / "screen.png")
            base = capture_window(main["id"], Path(folder) / "main.png")
            pixels, height = image_size(base)
            if (pixels, height) == (round(main["width"] * SCALE), round(main["height"] * SCALE)):
                self.screen.run("maskalpha", screen_shot, base, out)
                return out
            children = [w for w in windows if w["id"] != main["id"] and "acesse" not in w["name"]]
            left = min([main["x"]] + [w["x"] for w in children])
            top = min([main["y"]] + [w["y"] for w in children])
            alpha = Path(folder) / "alpha.png"
            self.screen.run("crop", base, alpha, round((main["x"] - left) * SCALE), round((main["y"] - top) * SCALE),
                            round(main["width"] * SCALE), round(main["height"] * SCALE))
            self.screen.run("maskalpha", screen_shot, alpha, out)
        return out


def pick(shots: list[Path], screen: ScreenTool, text: str) -> Path:
    showing = [shot for shot in shots if screen.find_in(shot, text)]
    if not showing:
        raise RuntimeError(f"no capture shows {text!r}")
    return showing[len(showing) // 2]


def keep(shot: Path, out: Path) -> Path:
    out.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(shot, out)
    return out


# The demonstration's documents folder, in the state of each chapter.

def reset_documents() -> None:
    """Removes what the frames add (Fotos-2025, Projetos.zip, the compression sheet's
    archive), so each pass starts from the fixture as the demonstration does."""
    for name in os.listdir(FIXTURE):
        if name in {"Fotos-2025", "Projetos.zip"} or (name.endswith(".zip") and name not in
                                                       {"Backup.zip", "Site.zip"}):
            path = FIXTURE / name
            shutil.rmtree(path) if path.is_dir() else path.unlink()


def padded_photos(seven_zip: str, scratch: Path):
    """A maker of Fotos-2025.7z with leia-me.txt followed by PAD zeros: its extraction lasts
    seconds (the archive itself grows by about half a megabyte)."""
    def make(original: Path, out: Path) -> None:
        work = scratch / "photos"
        shutil.rmtree(work, ignore_errors=True)
        subprocess.run([seven_zip, "x", "-bso0", "-bsp0", f"-o{work}", str(original)], check=True)
        readme = work / "leia-me.txt"
        stat = readme.stat()
        with open(readme, "r+b") as handle:
            handle.truncate(stat.st_size + PAD)
        os.utime(readme, (stat.st_atime, stat.st_mtime))
        archive = scratch / "Fotos-2025.7z"
        archive.unlink(missing_ok=True)
        subprocess.run([seven_zip, "a", "-t7z", "-mx=9", "-bso0", "-bsp0", str(archive), "retratos", "viagem",
                        "leia-me.txt"], cwd=work, check=True)
        shutil.rmtree(work)
        shutil.move(archive, out)
    return make


class Swap:
    """Puts a file made by `make(path)` in place of `target`, with the original's dates, and
    gives the original back afterwards."""

    def __init__(self, target: Path, make) -> None:
        self.target, self.make = target, make

    def __enter__(self):
        stat = self.target.stat()
        self.saved = self.target.with_name("." + self.target.name + ".saved")
        shutil.move(self.target, self.saved)
        partial = self.target.with_name("." + self.target.name + ".new")
        self.make(self.saved, partial)
        os.utime(partial, (stat.st_atime, stat.st_mtime))
        os.rename(partial, self.target)
        return self

    def __exit__(self, *_):
        self.target.unlink(missing_ok=True)
        shutil.move(self.saved, self.target)


def padded_cover(original: Path, out: Path) -> None:
    """Capa.png followed by PAD zeros (sparse) after its end, which a PNG decoder ignores: the
    picture is the same, and compressing it lasts seconds."""
    shutil.copyfile(original, out)
    with open(out, "r+b") as handle:
        handle.truncate(out.stat().st_size + PAD)


FRAMES = [
    "chapter-open-0", "chapter-open-1",
    "chapter-view-0", "chapter-view-1", "chapter-view-2",
    "chapter-view-3",
    "chapter-button-0", "chapter-button-1", "chapter-button-2", "chapter-button-3",
    "chapter-button-4",
    "chapter-compress-0", "chapter-compress-1", "chapter-compress-2", "chapter-compress-3",
]
# Scenes that are not frames of the demonstration but are compared with a drawing of the
# same state (the website's /demo-window draws them after the frames): the compression
# sheet with "Proteger com senha" on and a password typed in both fields.
EXTRAS = ["extra-password-sheet"]
# The windows of the features gallery's drawn cards (the website's Recursos), each the whole
# window at the card's own size, in the state the card shows; the website crops the drawing
# of the same window as the card frames it (src/content/feature-windows.tsx).
CARDS = ["feature-manager", "feature-editing", "feature-integrity", "feature-volumes",
         "feature-password"]
PASSWORD = "password2026"
CHAPTER_4 = ["chapter-compress-0", "chapter-compress-1", "chapter-compress-2",
             "chapter-compress-3", *EXTRAS]


MONTHS = ["jan.", "fev.", "mar.", "abr.", "mai.", "jun.", "jul.", "ago.", "set.", "out.", "nov.", "dez."]


def noise(elements: list[dict], swapped: str | None) -> list[dict]:
    """Rectangles (window points) of what a capture shows only because it was taken today with
    a stand-in file, which the comparison masks in both pictures: dates of today (files the
    frames create, the last opening of a previewed file), and, while a file is swapped for a
    larger one, its size in the List and the pane's subtitle."""
    today = date.today()
    stamp = f"{today.day} de {MONTHS[today.month - 1]} de {today.year}"
    texts = [e for e in elements if e["role"] == "AXStaticText"]
    rects = []
    def add(e: dict) -> None:
        rects.append({key: e[key] for key in ("x", "y", "width", "height")})
    for e in texts:
        if stamp in (e["value"] or ""):
            add(e)
    if swapped:
        rows = [e for e in texts if unicodedata.normalize("NFC", e["value"] or "") == swapped and e["x"] < 450]
        for row in rows:
            for e in texts:
                if abs(e["y"] - row["y"]) < 3 and 584 <= e["x"] < 674:
                    add(e)
        for e in texts:
            if e["x"] >= 700 and " · " in (e["value"] or ""):
                add(e)
    return rects


class CardRun:
    """The cards' windows (CARDS), mixed into Run."""

    def cards(self) -> None:
        app = self.app
        if not self.needs(*CARDS):
            return
        reset_documents()
        if self.needs("feature-manager"):
            # Gerenciador de arquivos completo: the whole window at 736 × 512 (the smallest
            # height), Icons with the sidebar and the path bar, Capa.png selected.
            app.go_to(FIXTURE)
            app.frame(736, 512)
            app.view("icons")
            app.preview(False)
            app.select("Capa.png")
            self.save("feature-manager")
        if self.needs("feature-editing"):
            # Edição sem extrair: the content of Fotos-2025.7z in the List, its two folders
            # expanded, grupo.jpg selected (900 × 560).
            app.go_to(FIXTURE)
            app.frame(900, 560)
            app.view("list")
            app.preview(False)
            app.select("Fotos-2025.7z")
            app.key(125, "command down")  # ⌘↓ opens the selected archive in the window.
            wait_until(lambda: app.window_title() == "Fotos-2025.7z", 10, what="the archive to open")
            time.sleep(1)
            for folder in ["viagem", "retratos"]:
                app.select(folder)
                app.key(124)  # → expands the folder in its row.
                time.sleep(1)
            app.select("grupo.jpg")
            self.save("feature-editing")
        if self.needs("feature-integrity"):
            # Teste de integridade: the toast after Validar on Fotos-2025.7z (900 × 560).
            app.go_to(FIXTURE)
            app.frame(900, 560)
            app.view("list")
            app.preview(False)
            app.context_menu("Fotos-2025.7z")
            app.choose_menu_item("Validar")
            app.park_pointer()
            shots = app.burst(4, self.scratch / "validated")
            self.save("feature-integrity",
                      pick(shots, app.screen, "Arquivos compactados validados com sucesso."))
            time.sleep(2)
        if self.needs("feature-volumes"):
            # Arquivos divididos em volumes: Columns, Projeto.7z.001 open in the next column
            # (1000 × 560).
            app.go_to(FIXTURE)
            app.frame(1000, 560)
            app.view("columns")
            app.preview(False)
            app.select("Projetos")
            time.sleep(1)
            app.select("Projeto.7z.001")
            time.sleep(1.5)
            self.save("feature-volumes")
        if self.needs("feature-password"):
            # Proteção por senha: the sheet of Comprimir customizado… for Projetos, Proteger
            # com senha on and the same password in both fields (1000 × 680, the List with
            # the preview pane).
            app.go_to(FIXTURE)
            frame = app.frame(1000, 680)
            app.view("list")
            app.preview(True)
            app.context_menu("Projetos")
            app.choose_menu_item("Comprimir customizado…")
            wait_until(lambda: app.sheet_count() > 0, 10, what="the sheet")
            time.sleep(1.2)
            box = next(e for e in app.ax_elements() if e["role"] == "AXCheckBox"
                       and e["description"] == "Proteger com senha")
            frame = app.window_frame()
            app._guard()
            app.screen.run("safeclick", app.pid, round(frame.x + box["x"] + 8),
                           round(frame.y + box["y"] + box["height"] / 2))
            time.sleep(1)
            def secure_fields():
                fields = [e for e in app.ax_elements() if e["role"] == "AXTextField"
                          and e["subrole"] == "AXSecureTextField"]
                return sorted(fields, key=lambda e: e["y"]) if len(fields) == 2 else None
            for field in wait_until(secure_fields, 5, what="the password fields"):
                app._guard()
                app.screen.run("safeclick", app.pid, round(frame.x + field["x"] + field["width"] / 2),
                               round(frame.y + field["y"] + field["height"] / 2))
                time.sleep(0.4)
                app.keystroke("photos2025")
                time.sleep(0.4)
            self.save("feature-password")
            app.key(53)  # Escape: Cancelar.
            time.sleep(1)
        reset_documents()


class Run(CardRun):
    def __init__(self, app: Driver, out: Path, theme: str, wanted: set[str], seven_zip: str,
                 scratch: Path, record_ax: bool) -> None:
        self.app, self.out, self.theme, self.wanted = app, out, theme, wanted
        self.seven_zip, self.scratch, self.record_ax = seven_zip, scratch, record_ax
        # The item whose file is swapped for a larger one while a frame is captured.
        self.swapped: str | None = None

    def path(self, frame: str) -> Path:
        return self.out / f"{frame}-{THEMES[self.theme]}.png"

    def save(self, frame: str, shot: Path | None = None) -> None:
        if frame not in self.wanted:
            return
        if shot is None:
            self.app.park_pointer()
            time.sleep(0.4)
            shot = self.app.composite(self.path(frame))
        else:
            keep(shot, self.path(frame))
        if self.record_ax:
            elements = self.app.ax_elements()
            (self.out / f"{frame}.ax.json").write_text(json.dumps(elements, ensure_ascii=False, indent=1))
            (self.out / f"{frame}.noise.json").write_text(json.dumps(noise(elements, self.swapped), indent=1))
        print(self.path(frame), flush=True)

    def needs(self, *frames: str) -> bool:
        return any(frame in self.wanted for frame in frames)

    def documents(self, mode: str, preview: bool = True) -> None:
        app = self.app
        app.go_to(FIXTURE)
        app.place()
        app.view(mode)
        if mode == "list":
            app.preview(preview)

    # Chapter 1: Abrir.
    def open_chapter(self) -> None:
        app = self.app
        if self.needs("chapter-open-0"):
            self.documents("list")
            app.expand("Fotos-2025.7z")
            app.expand("retratos")
            app.select("Fotos-2025.7z")
            self.save("chapter-open-0")
            # Collapse again, so later frames start from closed rows.
            app.key(123)
            time.sleep(0.6)
        if self.needs("chapter-open-1"):
            self.documents("list")
            app.select("Fotos-2025.7z")
            app.key(125, "command down")  # ⌘↓ opens the archive in the window.
            wait_until(lambda: app.window_title() == "Fotos-2025.7z", 10, what="the archive to open")
            wait_until(lambda: not app.find_text("Notas.txt"), 10, what="the archive's content")
            time.sleep(1)
            app.expand("retratos")
            app.deselect()
            self.save("chapter-open-1")

    # Chapter 2: Visualização.
    def view_chapter(self) -> None:
        app = self.app
        for frame, mode, item in [("chapter-view-0", "columns", "Fotos-2025.7z"),
                                  ("chapter-view-1", "gallery", "Capa.png"),
                                  ("chapter-view-2", "icons", "Fotos-2025.7z"),
                                  ("chapter-view-3", "list", "Capa.png")]:
            if not self.needs(frame):
                continue
            self.documents(mode)
            app.select(item)
            time.sleep(1.5)
            self.save(frame)

    # Chapter 3: the contextual archive button.
    def button_chapter(self) -> None:
        app = self.app
        reset_documents()
        if self.needs("chapter-button-0"):
            self.documents("list")
            app.select("Fotos-2025.7z")
            button = app.toolbar_button("Extrair tudo")
            app.park_pointer()
            app.activate()
            app._guard()
            app.screen.run("safedown", app.pid, round(button.center[0]), round(button.center[1]))
            time.sleep(0.6)
            shot = app.composite(self.scratch / "pressed.png")
            frame = app.window_frame()
            app.screen.run("up", round(frame.right + 80), round(frame.bottom + 60))
            time.sleep(0.6)
            self.save("chapter-button-0", shot)
        if self.needs("chapter-button-1"):
            reset_documents()
            self.documents("list")
            self.swapped = "Fotos-2025.7z"
            with Swap(FIXTURE / "Fotos-2025.7z", padded_photos(self.seven_zip, self.scratch)):
                time.sleep(1.5)
                app.select("Fotos-2025.7z")
                button = app.toolbar_button("Extrair tudo")
                app.click(*button.center)
                app.park_pointer()
                shots = app.burst(4, self.scratch / "extract")
                self.save("chapter-button-1", pick(shots, app.screen, "Extraindo arquivos compactados…"))
                self.swapped = None
                wait_until(lambda: not app.screen.find(app.window_frame(), "Cancelar"), 120, 1,
                           what="the extraction to end")
                time.sleep(3)
            reset_documents()
            time.sleep(1)
        # Chapter 4 starts in the folder these steps leave (Fotos-2025 and Projetos.zip):
        # they run for its frames too, and save only the frames asked for.
        if self.needs("chapter-button-2", "chapter-button-3", "chapter-button-4", *CHAPTER_4):
            self.documents("list")
            app.select("Fotos-2025.7z")
            button = app.toolbar_button("Extrair tudo")
            app.click(*button.center)
            app.park_pointer()
            shots = app.burst(3, self.scratch / "extracted")
            self.save("chapter-button-2", pick(shots, app.screen, "Arquivos compactados extraídos com sucesso."))
            time.sleep(2)
            app.select("Projetos")
            button = app.toolbar_button("Comprimir selecionados", "Comprimir")
            if self.needs("chapter-button-3"):
                app.park_pointer()
                app.activate()
                app._guard()
                app.screen.run("safedown", app.pid, round(button.center[0]), round(button.center[1]))
                time.sleep(0.6)
                shot = app.composite(self.scratch / "pressed-compress.png")
                frame = app.window_frame()
                app.screen.run("up", round(frame.right + 80), round(frame.bottom + 60))
                time.sleep(0.6)
                self.save("chapter-button-3", shot)
            app.select("Projetos")
            app.click(*button.center)
            app.park_pointer()
            shots = app.burst(3, self.scratch / "compressed")
            self.save("chapter-button-4", pick(shots, app.screen, "Arquivo compactado criado com sucesso."))
            time.sleep(2)

    # Chapter 4: Comprimir.
    def open_sheet(self, items: tuple[str, ...]) -> None:
        app = self.app
        app.select(*items)
        more = app.toolbar_button("Mais")
        app.click(*more.center)
        time.sleep(1)
        entry = wait_until(lambda: app.screen.find(app.window_frame(), "Comprimir customizado…"), 5,
                           what="the menu entry")
        app._guard()
        app.screen.run("safeclick", app.pid, round(entry.center[0]), round(entry.center[1]))
        wait_until(lambda: app.sheet_count() > 0, 10, what="the sheet")
        time.sleep(1.2)
        # The name the demonstration shows, typed over the proposed one (the app proposes
        # "Archive.zip" for several items).
        app.keystroke("Entrega.zip")
        time.sleep(0.5)
        app.park_pointer()

    def remove_new_archives(self) -> None:
        for name in os.listdir(FIXTURE):
            if name.endswith(".zip") and name not in {"Backup.zip", "Site.zip", "Projetos.zip"}:
                (FIXTURE / name).unlink()

    def compress_chapter(self) -> None:
        app = self.app
        if not self.needs(*CHAPTER_4):
            return
        if not (FIXTURE / "Fotos-2025").exists() or not (FIXTURE / "Projetos.zip").exists():
            raise RuntimeError("chapter 4 starts after chapter 3: run its frames too")
        items = ("Relatório.pdf", "Notas.txt", "Capa.png")
        self.documents("list")
        # The ⋯ menu opens at the button's left edge and runs past the window's right edge;
        # with the window against the screen's right edge, AppKit moves it left, inside the
        # window, which is how the demonstration can show it.
        screen_width = int(app.screen.run("screensize").split()[0])
        app.set_window_frame(screen_width - WIDTH, 90, WIDTH, HEIGHT)
        if self.needs("chapter-compress-0"):
            app.select(*items)
            more = app.toolbar_button("Mais")
            app.click(*more.center)
            time.sleep(1)
            entry = wait_until(lambda: app.screen.find(app.window_frame(), "Comprimir customizado…"), 5,
                               what="the menu entry")
            app.screen.move(*entry.center)
            time.sleep(0.8)
            self.save("chapter-compress-0", app.composite(self.scratch / "menu.png"))
            app.key(53)
            time.sleep(0.8)
        if self.needs("chapter-compress-1"):
            self.open_sheet(items)
            self.save("chapter-compress-1")
            app.key(53)  # Escape: Cancelar.
            time.sleep(1)
        if self.needs("extra-password-sheet"):
            self.open_sheet(items)
            box = next(e for e in app.ax_elements() if e["role"] == "AXCheckBox"
                       and e["description"] == "Proteger com senha")
            frame = app.window_frame()
            app._guard()
            app.screen.run("safeclick", app.pid, round(frame.x + box["x"] + 8),
                           round(frame.y + box["y"] + box["height"] / 2))
            time.sleep(1)
            def secure_fields():
                fields = [e for e in app.ax_elements() if e["role"] == "AXTextField"
                          and e["subrole"] == "AXSecureTextField"]
                return sorted(fields, key=lambda e: e["y"]) if len(fields) == 2 else None
            fields = wait_until(secure_fields, 5, what="the password fields")
            for field in fields:
                app._guard()
                app.screen.run("safeclick", app.pid, round(frame.x + field["x"] + field["width"] / 2),
                               round(frame.y + field["y"] + field["height"] / 2))
                time.sleep(0.4)
                app.keystroke(PASSWORD)
                time.sleep(0.4)
            app.park_pointer()
            time.sleep(0.6)
            self.save("extra-password-sheet")
            app.key(53)  # Escape: Cancelar.
            time.sleep(1)
        if self.needs("chapter-compress-2"):
            self.swapped = "Capa.png"
            with Swap(FIXTURE / "Capa.png", padded_cover):
                time.sleep(2)
                self.open_sheet(items)
                app.key(36)  # Return: Salvar.
                shots = app.burst(4, self.scratch / "compress")
                self.save("chapter-compress-2", pick(shots, app.screen, "Compactando itens selecionados…"))
                self.swapped = None
                wait_until(lambda: not app.screen.find(app.window_frame(), "Cancelar"), 180, 1,
                           what="the compression to end")
                time.sleep(3)
            self.remove_new_archives()
            time.sleep(1.5)
        if self.needs("chapter-compress-3"):
            self.open_sheet(items)
            app.key(36)  # Return: Salvar.
            shots = app.burst(3, self.scratch / "created")
            self.save("chapter-compress-3", pick(shots, app.screen, "Arquivo compactado criado com sucesso."))
            time.sleep(2)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", type=Path, default=Path(tempfile.gettempdir()) / "zforge-demo-frames")
    parser.add_argument("--app", type=Path, help="an already built Zforge.app (skips the build)")
    parser.add_argument("--frame", action="append", choices=FRAMES + EXTRAS + CARDS,
                        help="only these frames (or extra scenes, or cards' windows)")
    parser.add_argument("--theme", action="append", choices=list(THEMES), help="only these appearances")
    parser.add_argument("--keep", action="store_true", help="leave the copy running and the fixture in place")
    arguments = parser.parse_args()

    wanted = set(arguments.frame or FRAMES)
    out = arguments.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    derived_data = None
    if arguments.app:
        app_path = arguments.app.resolve()
    else:
        derived_data = Path(tempfile.mkdtemp(prefix="zforge-website-build-"))
        app_path = build(derived_data)
    here = Path(__file__).resolve().parent
    subprocess.run([sys.executable, str(here / "make_fixtures.py"), str(FIXTURE_PARENT)], check=True)
    seven_zip = subprocess.run([sys.executable, str(here.parent / "fetch-7zz.py")], check=True,
                               capture_output=True, text=True).stdout.strip().splitlines()[-1]
    screen = ScreenTool()
    app = Driver(app_path, screen)
    pointer = screen.pointer()
    scratch = Path(tempfile.mkdtemp(prefix="zforge-demo-frames-"))
    # A plain grey screen under the copy's window: its translucent sidebar and panes show
    # it instead of the user's desktop, the same in every run. It belongs to the screen tool
    # and is closed at the end; the user's desktop is not changed.
    # It starts after the grant: over the open panel (another process's window) it would
    # stop the panel's click.
    backdrop = None
    try:
        with appearance_restored():
            current = "dark" if dark_mode() else "light"
            themes = arguments.theme or [current, "light" if current == "dark" else "dark"]
            app.launch()
            app.grant_fixture()
            backdrop = subprocess.Popen([str(screen.binary), "backdrop", str(BACKDROP_GREY)],
                                        stdout=subprocess.PIPE, text=True)
            backdrop.stdout.readline()
            time.sleep(0.5)
            app.activate()
            for index, theme in enumerate(themes):
                set_dark_mode(theme == "dark")
                run = Run(app, out, theme, wanted, seven_zip, scratch, record_ax=index == 0)
                reset_documents()
                run.cards()
                run.open_chapter()
                run.view_chapter()
                run.button_chapter()
                run.compress_chapter()
                reset_documents()
    finally:
        if backdrop:
            backdrop.terminate()
        screen.move(*pointer)
        shutil.rmtree(scratch, ignore_errors=True)
        if not arguments.keep:
            app.quit()
            shutil.rmtree(FIXTURE, ignore_errors=True)
        screen.close()
        if derived_data:
            # The copy's launch registered the temporary build with Launch Services (and its
            # Finder extension): unregister it before deleting it.
            lsregister = ("/System/Library/Frameworks/CoreServices.framework/Frameworks/"
                          "LaunchServices.framework/Support/lsregister")
            subprocess.run([lsregister, "-u", str(app_path)], capture_output=True)
            shutil.rmtree(derived_data, ignore_errors=True)


if __name__ == "__main__":
    main()
