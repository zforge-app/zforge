"""Shared helpers of the website capture scripts (capture_app.py and
Documentation/FinderMenuScene/capture_finder_menu.py).

Everything goes through System Events (GUI scripting) and the window server:
the terminal running the scripts needs the Accessibility and Screen Recording
permissions. No script here asks to control another app by Apple Events
(`tell application "Finder"`), which would raise a permission prompt.
"""
from __future__ import annotations

import json
import subprocess
import tempfile
import time
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent

# The appearances and the suffix of their files (<name>-light.png, <name>-dark.png).
THEMES = {"light": "light", "dark": "dark"}


def osa(script: str) -> str:
    result = subprocess.run(["osascript", "-"], input=script, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"osascript failed: {result.stderr.strip()}\n{script}")
    return result.stdout.strip()


@dataclass(frozen=True)
class Rect:
    x: float
    y: float
    width: float
    height: float

    @property
    def center(self) -> tuple[float, float]:
        return self.x + self.width / 2, self.y + self.height / 2

    @property
    def right(self) -> float:
        return self.x + self.width

    @property
    def bottom(self) -> float:
        return self.y + self.height


class ScreenTool:
    """screen_tool.swift, compiled once into a temporary folder."""

    def __init__(self) -> None:
        self._folder = tempfile.TemporaryDirectory(prefix="zforge-capture-tool-")
        self.binary = Path(self._folder.name) / "screen_tool"
        subprocess.run(["xcrun", "swiftc", "-O", str(HERE / "screen_tool.swift"), "-o", str(self.binary)],
                       check=True)

    def run(self, *arguments: object) -> str:
        return subprocess.run([str(self.binary), *map(str, arguments)], check=True, capture_output=True,
                              text=True).stdout

    def windows(self, pid: int) -> list[dict]:
        return [json.loads(line) for line in self.run("windows", pid).splitlines() if line.strip()]

    def click(self, x: float, y: float) -> None:
        self.run("click", round(x), round(y))

    def right_click(self, x: float, y: float) -> None:
        self.run("rightclick", round(x), round(y))

    def move(self, x: float, y: float) -> None:
        self.run("move", round(x), round(y))

    def find(self, area: Rect, text: str) -> Rect | None:
        """Where `text` is drawn inside `area` (Vision text recognition), or None."""
        result = subprocess.run([str(self.binary), "find", *(f"{value:.0f}" for value in
                                 (area.x, area.y, area.width, area.height)), text],
                                capture_output=True, text=True)
        if result.returncode != 0:
            return None
        return Rect(*(float(value) for value in result.stdout.split()))

    def find_in(self, image: Path, text: str) -> bool:
        return subprocess.run([str(self.binary), "findin", str(image), text], capture_output=True).returncode == 0

    def pointer(self) -> tuple[float, float]:
        x, y = self.run("pointer").split()
        return float(x), float(y)

    def close(self) -> None:
        self._folder.cleanup()


def dark_mode() -> bool:
    return osa('tell application "System Events" to tell appearance preferences to get dark mode') == "true"


def set_dark_mode(dark: bool) -> None:
    value = "true" if dark else "false"
    osa(f'tell application "System Events" to tell appearance preferences to set dark mode to {value}')
    time.sleep(1.5)


@contextmanager
def appearance_restored():
    """Gives back the system appearance the user had, whatever happens."""
    original = dark_mode()
    try:
        yield
    finally:
        if dark_mode() != original:
            set_dark_mode(original)


def capture_region(rect: Rect, path: Path) -> Path:
    """The screen inside `rect` (points), at the display's pixel density, without the pointer."""
    path.parent.mkdir(parents=True, exist_ok=True)
    region = f"{rect.x:.0f},{rect.y:.0f},{rect.width:.0f},{rect.height:.0f}"
    subprocess.run(["screencapture", "-x", "-R", region, str(path)], check=True)
    return path


def capture_window(window_id: int, path: Path) -> Path:
    """One window alone, with its rounded corners transparent and no shadow."""
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["screencapture", "-x", "-o", f"-l{window_id}", str(path)], check=True)
    return path


def image_size(path: Path) -> tuple[int, int]:
    out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)], check=True,
                         capture_output=True, text=True).stdout.split()
    return int(out[out.index("pixelWidth:") + 1]), int(out[out.index("pixelHeight:") + 1])


def capture_window_part(window_id: int, window: Rect, part: Rect, path: Path) -> Path:
    """Part of one window (`part` in screen points), cut from a capture of the window alone,
    so a rounded corner of the window inside the part stays transparent instead of showing
    what is behind the window."""
    with tempfile.TemporaryDirectory(prefix="zforge-capture-") as folder:
        whole = capture_window(window_id, Path(folder) / "window.png")
        return crop_window_capture(whole, window, part, path)


def crop_window_capture(whole: Path, window: Rect, part: Rect, path: Path) -> Path:
    """Cuts `part` (screen points) out of a capture of `window`."""
    width, height = image_size(whole)
    scale = width / window.width
    x = round((part.x - window.x) * scale)
    y = round((part.y - window.y) * scale)
    w = min(round(part.width * scale), width - x)
    h = min(round(part.height * scale), height - y)
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["sips", "-c", str(h), str(w), "--cropOffset", str(y), str(x), str(whole),
                    "--out", str(path)], check=True, capture_output=True)
    return path


def wait_until(condition, timeout: float = 10, interval: float = 0.15, what: str = "condition"):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        value = condition()
        if value:
            return value
        time.sleep(interval)
    raise TimeoutError(f"timed out waiting for {what}")


class Process:
    """GUI scripting of one process, addressed by its pid (two Zforge copies may run)."""

    def __init__(self, pid: int | None = None, name: str | None = None) -> None:
        self.pid = pid
        self.name = name

    @property
    def ref(self) -> str:
        if self.pid is not None:
            return f"(first process whose unix id is {self.pid})"
        return f'(first process whose name is "{self.name}")'

    def tell(self, body: str) -> str:
        return osa(f'tell application "System Events"\nset p to {self.ref}\n{body}\nend tell')

    def activate(self) -> None:
        self.tell("set frontmost of p to true\ntry\nperform action \"AXRaise\" of window 1 of p\nend try")
        wait_until(lambda: self.tell("return frontmost of p") == "true", 5, what="the process to come forward")
        time.sleep(0.3)

    def keystroke(self, text: str, modifiers: str = "") -> None:
        using = f" using {{{modifiers}}}" if modifiers else ""
        self.tell(f'set frontmost of p to true\nkeystroke "{text}"{using}')

    def key(self, code: int, modifiers: str = "") -> None:
        using = f" using {{{modifiers}}}" if modifiers else ""
        self.tell(f"set frontmost of p to true\nkey code {code}{using}")

    def window_frame(self, index: int = 1) -> Rect:
        values = self.tell(f"set w to window {index} of p\nreturn (position of w) & (size of w)")
        x, y, width, height = (float(value) for value in values.split(", "))
        return Rect(x, y, width, height)

    def set_window_frame(self, x: float, y: float, width: float, height: float, index: int = 1) -> None:
        self.tell(f"set w to window {index} of p\nset position of w to {{{x:.0f}, {y:.0f}}}\n"
                  f"set size of w to {{{width:.0f}, {height:.0f}}}")
        time.sleep(0.5)

    def window_title(self, index: int = 1) -> str:
        try:
            return self.tell(f"return name of window {index} of p")
        except RuntimeError:
            return ""  # No window at this moment (an alert or panel is closing).

    def texts(self, scope: str = "window 1 of p") -> list[tuple[str, Rect]]:
        """Every static text inside `scope`, with its frame on the screen."""
        out = self.tell(f"""
set out to ""
set allItems to entire contents of {scope}
repeat with i from 1 to count of allItems
  set e to item i of allItems
  try
    if role of e is "AXStaticText" then
      set v to value of e
      if v is missing value then set v to name of e
      set {{ex, ey}} to position of e
      set {{ew, eh}} to size of e
      set out to out & v & tab & ex & tab & ey & tab & ew & tab & eh & linefeed
    end if
  end try
end repeat
return out""")
        found = []
        for line in out.splitlines():
            parts = line.split("\t")
            if len(parts) == 5:
                found.append((parts[0], Rect(*(float(value) for value in parts[1:]))))
        return found

    def find_text(self, text: str, scope: str = "window 1 of p") -> Rect | None:
        for value, rect in self.texts(scope):
            if value == text and rect.width > 0:
                return rect
        return None

    def menu_bar_click(self, *path: str) -> None:
        """Clicks a menu bar item by its titles, as shown (for example "Visualizar", "Lista")."""
        reference = f'menu bar item "{path[0]}" of menu bar 1 of p'
        for title in path[1:-1]:
            reference = f'menu item "{title}" of menu 1 of {reference}'
        self.tell(f'click menu item "{path[-1]}" of menu 1 of {reference}')

    def menu_item_names(self, *path: str) -> list[str]:
        reference = f'menu bar item "{path[0]}" of menu bar 1 of p'
        for title in path[1:]:
            reference = f'menu item "{title}" of menu 1 of {reference}'
        names = self.tell(f"return name of every menu item of menu 1 of {reference}")
        return [name.strip() for name in names.split(", ")]
