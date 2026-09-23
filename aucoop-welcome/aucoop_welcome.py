#!/usr/bin/env python3
"""AUCOOP Welcome: a step-by-step guide for the first login.

Welcome -> Setup (updates, codecs, drivers) -> Extras (Kiwix, offline AI)
-> Register (for AUCOOP volunteers) -> Done.

Every privileged action goes through pkexec, so the system asks for the
password itself. Command output goes to the collapsed "Technical details"
panel, not to the main screen.
"""

import ast
import json
import os
import re
import shutil
import signal
import subprocess
import tempfile
import threading
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf, GLib, Gtk, Gdk

from welcome_i18n import t


APP_DIR = Path(__file__).resolve().parent
MODULES_FILE = APP_DIR / "modules.json"
PKEXEC_RUNNER = APP_DIR / "pkexec-runner.sh"
WORKBENCH_RUNNER = APP_DIR / "run-workbench-registration.sh"
AUTOSTART_FILE = Path.home() / ".config/autostart/aucoop-welcome.desktop"
ESSENTIAL_DONE_MARKER = Path.home() / ".local/state/aucoop-welcome/essential-setup-complete"
AI_RUNNER = Path("/opt/aucoop-ai/run-local-ai.sh")
AI_RUNTIME = Path("/opt/aucoop-ai/llamafile")
# Written by essential-setup.sh as root, also when it ran at night on its own.
SYSTEM_DONE_MARKER = Path("/var/lib/aucoop-welcome/essential-setup-complete")
# Created by schedule-setup.sh, removed by essential-setup.sh once it succeeds.
SETUP_TIMER = Path("/etc/systemd/system/aucoop-essential-setup.timer")
REMINDER = APP_DIR / "remind-when-online.sh"
REMINDER_PID = Path.home() / ".cache/aucoop-welcome/reminder.pid"

# Offer to run setup at night when the download would take longer than this.
SLOW_SECONDS = 20 * 60

# Installed by install/branding.sh; the repo copies are for running from a checkout.
LOGO_FILES = [Path("/usr/share/pixmaps/aucoop-logo.png"), APP_DIR.parent / "assets/AUCOOP_logotip.png"]
SYMBOL_FILES = [Path("/usr/share/pixmaps/aucoop-symbol.png"), APP_DIR.parent / "assets/aucoop-symbol.png"]

PAGES = ["welcome", "setup", "extras", "register", "done"]

# Lines printed by essential-setup.sh, used to tick off its phases.
SETUP_PHASES = [
    ("updates", "Installing initial updates"),
    ("codecs", "Installing multimedia codecs"),
    ("drivers", "Installing recommended hardware drivers"),
]

# apt output inside those phases. pkexec clears the locale, so apt prints
# these in English whatever the desktop language is.
APT_SUMMARY = re.compile(r"^(\d+) upgraded, (\d+) newly installed")
APT_GET = re.compile(r"^Get:(\d+) ")
APT_UNPACK = re.compile(r"^Unpacking (\S+)")
APT_SETUP = re.compile(r"^Setting up (\S+)")
# One line of "apt-get --print-uris": 'url' filename size hash
APT_URI = re.compile(r"^'([^']+)' (\S+) (\d+) ")

BLUE = "#009cd2"

CSS = f"""
.aucoop-window {{ background-color: #f4f6f9; }}
.aucoop-bar {{ background-color: #ffffff; border-color: #e2e6eb; border-style: solid; }}
.aucoop-bar.top {{ border-width: 0 0 1px 0; }}
.aucoop-bar.bottom {{ border-width: 1px 0 0 0; }}
.aucoop-title {{ font-size: 24px; font-weight: bold; color: #1c2430; }}
.aucoop-text {{ font-size: 14px; color: #4b5563; }}
.aucoop-small {{ font-size: 12px; color: #6b7280; }}
.aucoop-tip {{ font-size: 13px; font-style: italic; color: #4b5563; }}
.aucoop-card {{ background-color: #ffffff; border: 1px solid #e2e6eb; border-radius: 12px; }}
.aucoop-card-title {{ font-size: 15px; font-weight: bold; color: #1c2430; }}
.aucoop-ok {{ color: #15803d; font-weight: bold; }}
.aucoop-error {{ color: #c62828; font-weight: bold; }}
.step-dot {{
  min-width: 24px; min-height: 24px; border-radius: 12px;
  background-color: #e2e6eb; color: #6b7280; font-weight: bold; font-size: 12px;
}}
.step-dot.active {{ background-color: {BLUE}; color: #ffffff; }}
.step-dot.done {{ background-color: #d4eef8; color: #00739e; }}
.step-name {{ color: #8a94a3; font-size: 12px; }}
.step-name.active {{ color: #1c2430; font-weight: bold; }}
.step-line {{ min-width: 18px; min-height: 2px; background-color: #e2e6eb; }}
.item-mark {{ font-size: 15px; color: #b3bcc7; min-width: 22px; }}
.item-mark.done {{ color: {BLUE}; }}
button.aucoop-primary {{
  background-image: none; background-color: {BLUE}; color: #ffffff;
  border: none; border-radius: 8px; padding: 9px 26px; box-shadow: none; text-shadow: none;
  font-weight: bold;
}}
button.aucoop-primary:hover {{ background-color: #0088b8; }}
button.aucoop-primary:disabled {{ background-color: #a9d6e8; }}
button.aucoop-primary label {{ color: #ffffff; }}
button.aucoop-plain {{ border-radius: 8px; padding: 9px 18px; }}
progressbar trough {{ min-height: 8px; border-radius: 4px; background-color: #e2e6eb; border: none; }}
progressbar progress {{ min-height: 8px; border-radius: 4px; background-color: {BLUE}; border: none; }}
"""


# ── Helpers (unchanged behaviour) ─────────────────────────────────

def load_config():
    with MODULES_FILE.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def total_ram_gb():
    meminfo = Path("/proc/meminfo").read_text(encoding="utf-8")
    for line in meminfo.splitlines():
        if line.startswith("MemTotal:"):
            kb = int(line.split()[1])
            return kb / 1024 / 1024
    return 0


def ai_recommendation(ai_cfg, ram):
    if not ai_cfg.get("enabled", True):
        return "hidden"

    small_ram = ai_cfg.get("small_model_ram_gb", ai_cfg.get("minimum_ram_gb", 8))
    medium_ram = ai_cfg.get("medium_model_ram_gb", ai_cfg.get("recommended_ram_gb", 16))

    if ram < small_ram:
        return "not_recommended"
    if ram < medium_ram:
        return "basic"
    return "recommended"


def recommended_ai_model(ai_cfg, ram, available=None):
    models = sorted(available if available is not None else ai_cfg.get("models", []),
                    key=lambda m: m.get("min_ram_gb", 0))
    selected = None
    for model in models:
        if ram >= model.get("min_ram_gb", 0):
            selected = model
    if not selected and models:
        return models[0]
    return selected


def ai_model_label(model):
    return t("ai_model_label", name=model["name"], ram=model.get("min_ram_gb", "?"), size=model.get("size_gb", "?"))


def ai_runtime_bytes(ai_cfg):
    """Size the runtime will add, or 0 when it is already installed."""
    if AI_RUNTIME.exists():
        return 0
    return ai_cfg.get("runtime", {}).get("size_bytes", 0)


def ai_free_bytes():
    target = AI_RUNTIME.parent if AI_RUNTIME.parent.exists() else Path("/")
    try:
        return shutil.disk_usage(target).free
    except OSError:
        return 0


def filtered_ai_models(ai_cfg, show_more, ram, free_bytes):
    """Models this computer can actually store, and run unless show_more."""
    extra = ai_runtime_bytes(ai_cfg)
    models = [m for m in ai_cfg.get("models", []) if show_more or m.get("curated", True)]
    # A model that doesn't fit on the disk is never worth offering: the
    # download would fail at the very end, after hours on a slow line.
    models = [m for m in models if free_bytes > (m.get("size_bytes", 0) + extra) * 1.1]
    if show_more:
        return models
    # "8 GB" machines report ~7.8 GB, so allow half a gigabyte.
    return [m for m in models if ram + 0.5 >= m.get("min_ram_gb", 0)]


# ── Connection checks (no root needed) ────────────────────────────

def run_text(argv, timeout=30):
    """stdout of a command in the C locale, or "" if it can't run."""
    try:
        return subprocess.run(
            argv, capture_output=True, text=True, timeout=timeout,
            env={**os.environ, "LC_ALL": "C"},
        ).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def apt_downloads():
    """Files essential-setup.sh would download: {filename: (url, size)}."""
    files = {}
    for args in (["upgrade"], ["install", "mint-meta-codecs"]):
        for line in run_text(["apt-get", "--print-uris", "-qq", "-y", *args], 90).splitlines():
            match = APT_URI.match(line)
            if match:
                files[match[2]] = (match[1], int(match[3]))
    return files


def network_check():
    """Is the computer online, on mobile data, and how big and slow is the download?"""
    state = run_text(["nmcli", "networking", "connectivity", "check"], 20)
    # "unknown" or no NetworkManager: don't block anyone, just try.
    if state and state not in ("full", "unknown"):
        return {"online": False}

    device = ""
    for line in run_text(["nmcli", "-t", "-f", "DEVICE,STATE", "device"]).splitlines():
        name, _, device_state = line.partition(":")
        if device_state == "connected":
            device = name
            break
    metered = bool(device) and run_text(
        ["nmcli", "-g", "GENERAL.METERED", "device", "show", device]
    ).startswith("yes")

    files = apt_downloads()
    size = sum(file_size for _url, file_size in files.values())

    # Time part of a real download (up to 8 MB or 8 s) from the server that
    # carries most of the bytes, counting from the first byte so connection
    # setup doesn't count. Skipped on mobile data, where every MB costs money.
    speed = None
    if files and not metered:
        by_server = {}
        for url, file_size in files.values():
            server = url.split("/")[2]
            by_server[server] = by_server.get(server, 0) + file_size
        server = max(by_server, key=by_server.get)
        url, file_size = max(
            (f for f in files.values() if f[0].split("/")[2] == server), key=lambda f: f[1]
        )
        out = run_text(
            ["curl", "-sS", "-o", "/dev/null", "-r", f"0-{min(file_size, 8_000_000) - 1}",
             "--max-time", "8", "-w", "%{size_download} %{time_total} %{time_starttransfer}", url],
            20,
        )
        try:
            got, total, first_byte = (float(v) for v in out.split())
            if got > 200_000:
                speed = got / max(total - first_byte, 0.1)
        except ValueError:
            speed = None
    return {"online": True, "metered": metered, "size": size, "speed": speed}


def fmt_size(size):
    mb = size / 1e6
    if mb >= 1000:
        return t("size_gb", n=f"{mb / 1000:.1f}")
    return t("size_mb", n=round(mb / 10) * 10 if mb >= 50 else max(1, round(mb)))


def fmt_duration(seconds):
    minutes = max(1, round(seconds / 60))
    if minutes < 60:
        return t("time_min", n=minutes)
    return t("time_h", h=minutes // 60, m=minutes % 60)


def first_existing(paths):
    for path in paths:
        if path.exists():
            return path
    return None


def image(paths, height, white_to_transparent=False):
    """Gtk.Image scaled to a height, or an empty one if the file is missing."""
    path = first_existing(paths)
    if not path:
        return Gtk.Image()
    try:
        pixbuf = GdkPixbuf.Pixbuf.new_from_file(str(path))
        if white_to_transparent:
            # aucoop-symbol.png has a solid white background.
            pixbuf = pixbuf.add_alpha(True, 255, 255, 255)
        width = int(pixbuf.get_width() * height / pixbuf.get_height())
        return Gtk.Image.new_from_pixbuf(pixbuf.scale_simple(width, height, GdkPixbuf.InterpType.BILINEAR))
    except GLib.Error:
        return Gtk.Image()


def label(text="", css=None, wrap=True, xalign=0.0):
    widget = Gtk.Label(label=text)
    widget.set_xalign(xalign)
    widget.set_line_wrap(wrap)
    if css:
        for name in css.split():
            widget.get_style_context().add_class(name)
    return widget


def add_class(widget, *names):
    for name in names:
        widget.get_style_context().add_class(name)
    return widget


def card():
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
    box.set_border_width(16)
    frame = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    add_class(frame, "aucoop-card")
    frame.pack_start(box, True, True, 0)
    return frame, box


# ── Window ────────────────────────────────────────────────────────

class WelcomeWindow(Gtk.Window):
    def __init__(self):
        # Setup may have finished at night, run by the timer, with nobody logged in.
        self.overnight = SYSTEM_DONE_MARKER.exists() and not ESSENTIAL_DONE_MARKER.exists()
        if self.overnight:
            ESSENTIAL_DONE_MARKER.parent.mkdir(parents=True, exist_ok=True)
            ESSENTIAL_DONE_MARKER.write_text("complete\n", encoding="utf-8")
        if ESSENTIAL_DONE_MARKER.exists() and AUTOSTART_FILE.exists():
            AUTOSTART_FILE.unlink(missing_ok=True)

        super().__init__(title=t("window_title"))
        self.set_default_size(840, 600)
        self.set_position(Gtk.WindowPosition.CENTER)
        add_class(self, "aucoop-window")

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.config = load_config()
        self.page_index = 0
        self.busy = False
        self.needs_restart = False
        if ESSENTIAL_DONE_MARKER.exists():
            self.setup_state = "already"
        elif SETUP_TIMER.exists():
            self.setup_state = "scheduled"
        else:
            self.setup_state = "idle"
        self.net = None
        self.extras_state = "idle"
        self.register_state = "idle"
        self.current_ai_model_id = None
        self.apt = {"total": 0, "get": 0, "unpack": 0, "setup": 0}
        self.determinate_bars = set()

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(outer)
        outer.pack_start(self.build_header(), False, False, 0)

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(280)
        outer.pack_start(self.stack, True, True, 0)

        for name, build in (
            ("welcome", self.build_welcome_page),
            ("setup", self.build_setup_page),
            ("extras", self.build_extras_page),
            ("register", self.build_register_page),
            ("done", self.build_done_page),
        ):
            page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
            page.set_border_width(28)
            build(page)
            scroll = Gtk.ScrolledWindow()
            scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            scroll.add(page)
            self.stack.add_named(scroll, name)

        outer.pack_start(self.build_footer(), False, False, 0)

    # ── Chrome: header with logo and stepper, footer with buttons ──

    def build_header(self):
        bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        add_class(bar, "aucoop-bar", "top")
        logo = image(LOGO_FILES, 30)
        logo.set_margin_start(24)
        logo.set_margin_top(14)
        logo.set_margin_bottom(14)
        bar.pack_start(logo, False, False, 0)

        stepper = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        stepper.set_valign(Gtk.Align.CENTER)
        self.step_dots = []
        self.step_names = []
        for i, name in enumerate(PAGES):
            if i:
                line = Gtk.Box()
                line.set_valign(Gtk.Align.CENTER)
                stepper.pack_start(add_class(line, "step-line"), False, False, 0)
            dot = label(str(i + 1), "step-dot", wrap=False, xalign=0.5)
            dot.set_valign(Gtk.Align.CENTER)
            text = label(t(f"step_{name}"), "step-name", wrap=False)
            stepper.pack_start(dot, False, False, 0)
            stepper.pack_start(text, False, False, 0)
            self.step_dots.append(dot)
            self.step_names.append(text)
        stepper.set_margin_end(24)
        bar.pack_end(stepper, False, False, 0)
        return bar

    def build_footer(self):
        footer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        add_class(footer, "aucoop-bar", "bottom")

        self.details = Gtk.Expander(label=t("details"))
        self.details.set_margin_start(24)
        self.details.set_margin_end(24)
        self.details.set_margin_top(8)
        self.log_buffer = Gtk.TextBuffer()
        self.log_buffer.set_text(t("details_empty"))
        self.log_view = Gtk.TextView(buffer=self.log_buffer)
        self.log_view.set_editable(False)
        self.log_view.set_monospace(True)
        self.log_view.set_cursor_visible(False)
        log_scroll = Gtk.ScrolledWindow()
        log_scroll.set_min_content_height(140)
        log_scroll.add(self.log_view)
        self.details.add(log_scroll)
        footer.pack_start(self.details, False, False, 0)

        buttons = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        buttons.set_border_width(14)
        buttons.set_margin_start(10)
        buttons.set_margin_end(10)
        self.back_button = add_class(Gtk.Button(label=t("back")), "aucoop-plain")
        self.back_button.connect("clicked", lambda _b: self.go(self.page_index - 1))
        buttons.pack_start(self.back_button, False, False, 0)

        self.primary_button = add_class(Gtk.Button(), "aucoop-primary")
        self.primary_button.connect("clicked", self.on_primary)
        buttons.pack_end(self.primary_button, False, False, 0)

        self.secondary_button = add_class(Gtk.Button(), "aucoop-plain")
        self.secondary_button.connect("clicked", self.on_secondary)
        buttons.pack_end(self.secondary_button, False, False, 0)

        footer.pack_start(buttons, False, False, 0)
        return footer

    def go(self, index):
        index = max(0, min(index, len(PAGES) - 1))
        if index == self.page_index and self.stack.get_visible_child_name() == PAGES[index]:
            self.refresh()
            return
        self.stack.set_transition_type(
            Gtk.StackTransitionType.SLIDE_LEFT if index > self.page_index else Gtk.StackTransitionType.SLIDE_RIGHT
        )
        self.page_index = index
        self.stack.set_visible_child_name(PAGES[index])
        if PAGES[index] == "done":
            self.enter_done_page()
        if PAGES[index] == "setup" and self.setup_state in ("idle", "failed") and self.net is None:
            self.check_network()
        self.refresh()

    def refresh(self):
        """Update the stepper and the footer buttons for the current page."""
        for i, (dot, name) in enumerate(zip(self.step_dots, self.step_names)):
            for widget in (dot, name):
                ctx = widget.get_style_context()
                ctx.remove_class("active")
                ctx.remove_class("done")
            if i < self.page_index:
                dot.set_text("✔")
                add_class(dot, "done")
            else:
                dot.set_text(str(i + 1))
                if i == self.page_index:
                    add_class(dot, "active")
                    add_class(name, "active")

        page = PAGES[self.page_index]
        primary, secondary = None, None
        primary_enabled = not self.busy
        if page == "welcome":
            primary = t("welcome_start")
        elif page == "setup":
            state, kind = self.setup_state, self.net_kind()
            if state in ("checking", "running"):
                primary = t("setup_start")
                primary_enabled = False
            elif state in ("idle", "failed") and kind == "offline":
                primary, secondary = t("net_remind"), t("net_check_again")
            elif state in ("idle", "failed") and kind == "metered":
                primary, secondary = t("net_start_anyway"), t("net_wait_wifi")
            elif state in ("idle", "failed") and kind == "slow":
                primary, secondary = t("setup_start"), t("net_tonight")
            elif state in ("idle", "failed"):
                primary = t("setup_retry") if state == "failed" else t("setup_start")
                secondary = t("setup_skip")
            elif state == "reminded":
                primary = t("close")
            elif state == "scheduled":
                primary, secondary = t("next"), t("net_start_now")
            else:
                primary = t("next")
        elif page == "extras":
            if self.extras_state == "done" or not self.has_extras_selection():
                primary = t("next")
            else:
                primary = t("extras_install")
            if self.extras_state != "done" and self.has_extras_selection():
                secondary = t("skip")
        elif page == "register":
            if self.register_state == "done":
                primary = t("next")
            elif self.token_entry.get_text().strip():
                primary = t("register_run")
                secondary = t("skip")
            else:
                primary = t("skip")
        elif page == "done":
            primary = t("done_restart") if self.needs_restart else t("done_close")
            if self.needs_restart:
                secondary = t("done_close")

        self.primary_button.set_label(primary)
        self.primary_button.set_sensitive(primary_enabled)
        self.secondary_button.set_visible(bool(secondary) and not self.busy)
        if secondary:
            self.secondary_button.set_label(secondary)
        self.back_button.set_visible(self.page_index > 0)
        self.back_button.set_sensitive(not self.busy)

    def on_primary(self, _button):
        page = PAGES[self.page_index]
        if page == "welcome":
            self.go(1)
        elif page == "setup":
            state = self.setup_state
            if state in ("idle", "failed"):
                if self.net_kind() == "offline":
                    self.start_reminder(unmetered=False)
                else:
                    self.start_setup()
            elif state == "reminded":
                self.close()
            elif state != "checking":
                self.go(2)
        elif page == "extras":
            if self.extras_state != "done" and self.has_extras_selection():
                self.start_extras()
            else:
                self.go(3)
        elif page == "register":
            if self.register_state != "done" and self.token_entry.get_text().strip():
                self.start_registration()
            else:
                self.go(4)
        elif page == "done":
            if self.needs_restart:
                subprocess.Popen(["systemctl", "reboot"])
            self.close()

    def on_secondary(self, _button):
        page = PAGES[self.page_index]
        if page == "done":
            self.close()
        elif page == "setup" and self.setup_state in ("idle", "failed"):
            kind = self.net_kind()
            if kind == "offline":
                self.check_network()
            elif kind == "metered":
                self.start_reminder(unmetered=True)
            elif kind == "slow":
                self.schedule_tonight()
            else:
                self.go(self.page_index + 1)
        elif page == "setup" and self.setup_state == "scheduled":
            self.start_setup()
        else:
            self.go(self.page_index + 1)

    def set_busy(self, busy):
        self.busy = busy
        self.refresh()

    # ── Pages ──

    def build_welcome_page(self, page):
        page.set_valign(Gtk.Align.CENTER)
        symbol = image(SYMBOL_FILES, 120, white_to_transparent=True)
        page.pack_start(symbol, False, False, 0)
        page.pack_start(label(t("welcome_title"), "aucoop-title", xalign=0.5), False, False, 4)
        body = label(t("welcome_body"), "aucoop-text", xalign=0.5)
        body.set_justify(Gtk.Justification.CENTER)
        body.set_max_width_chars(60)
        page.pack_start(body, False, False, 0)
        needs = label(t("welcome_needs"), "aucoop-small", xalign=0.5)
        needs.set_justify(Gtk.Justification.CENTER)
        needs.set_max_width_chars(60)
        page.pack_start(needs, False, False, 6)

    def build_setup_page(self, page):
        page.pack_start(label(t("setup_title"), "aucoop-title"), False, False, 0)
        page.pack_start(label(t("setup_body"), "aucoop-text"), False, False, 0)

        frame, box = card()
        self.setup_marks = {}
        self.setup_spinners = {}
        for key, _marker in SETUP_PHASES:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            mark = label("○", "item-mark", wrap=False, xalign=0.5)
            spinner = Gtk.Spinner()
            spinner.set_no_show_all(True)
            spinner.set_size_request(22, 16)  # same width as the ○/✔ mark
            row.pack_start(mark, False, False, 0)
            row.pack_start(spinner, False, False, 0)
            row.pack_start(label(t(f"setup_{key}"), "aucoop-card-title", wrap=False), False, False, 0)
            box.pack_start(row, False, False, 2)
            self.setup_marks[key] = mark
            self.setup_spinners[key] = spinner
        page.pack_start(frame, False, False, 6)

        self.net_card, net_box = card()
        self.net_card.set_no_show_all(True)
        net_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.net_spinner = Gtk.Spinner()
        self.net_spinner.set_no_show_all(True)
        net_row.pack_start(self.net_spinner, False, False, 0)
        self.net_text = label("", "aucoop-card-title")
        net_row.pack_start(self.net_text, True, True, 0)
        net_box.pack_start(net_row, False, False, 0)
        self.net_hint = label("", "aucoop-text")
        self.net_hint.set_no_show_all(True)
        net_box.pack_start(self.net_hint, False, False, 0)
        net_box.show_all()
        page.pack_start(self.net_card, False, False, 0)

        self.setup_progress = Gtk.ProgressBar()
        self.setup_progress.set_no_show_all(True)
        page.pack_start(self.setup_progress, False, False, 4)
        self.setup_detail = label("", "aucoop-small", wrap=False)
        self.setup_detail.set_ellipsize(3)  # Pango.EllipsizeMode.END
        page.pack_start(self.setup_detail, False, False, 0)

        self.setup_status = label(t("setup_password"), "aucoop-small")
        page.pack_start(self.setup_status, False, False, 0)
        self.setup_tip = label("", "aucoop-tip")
        page.pack_start(self.setup_tip, False, False, 0)

        if self.setup_state == "already":
            self.mark_setup_phases(done=len(SETUP_PHASES))
            done_text = t("setup_overnight") if self.overnight else t("setup_already")
            self.show_status(self.setup_status, done_text, "aucoop-ok")
        elif self.setup_state == "scheduled":
            self.show_net_card(t("net_scheduled"))
            self.setup_status.set_text("")

    def build_extras_page(self, page):
        page.pack_start(label(t("extras_title"), "aucoop-title"), False, False, 0)
        page.pack_start(label(t("extras_body"), "aucoop-text"), False, False, 0)

        self.module_switches = {}
        for module in self.config.get("optional_modules", []):
            if module["id"] != "kiwix":
                continue
            frame, box = card()
            head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            head.pack_start(label(t("kiwix_title"), "aucoop-card-title", wrap=False), True, True, 0)
            switch = Gtk.Switch()
            switch.set_active(module.get("default_selected", False))
            switch.connect("notify::active", lambda *_a: self.refresh())
            head.pack_end(switch, False, False, 0)
            box.pack_start(head, False, False, 0)
            box.pack_start(label(t("kiwix_body"), "aucoop-text"), False, False, 0)
            self.module_switches[module["id"]] = switch
            page.pack_start(frame, False, False, 0)

        ram = total_ram_gb()
        ai_cfg = self.config.get("local_ai", {})
        ai_state = ai_recommendation(ai_cfg, ram)
        self.ai_free = ai_free_bytes()
        available = filtered_ai_models(ai_cfg, False, ram, self.ai_free)
        ai_model = recommended_ai_model(ai_cfg, ram, available)
        self.ai_switch = None
        self.ai_model_combo = None
        self.show_more_models_check = None
        self.ai_installed = AI_RUNNER.exists()

        if self.ai_installed:
            frame, box = card()
            head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            head.pack_start(label(t("ai_title"), "aucoop-card-title", wrap=False), True, True, 0)
            self.ai_remove_button = add_class(Gtk.Button(label=t("ai_remove")), "aucoop-plain")
            self.ai_remove_button.connect("clicked", self.on_remove_ai)
            head.pack_end(self.ai_remove_button, False, False, 0)
            box.pack_start(head, False, False, 0)
            self.ai_installed_label = label(t("ai_installed"), "aucoop-text")
            box.pack_start(self.ai_installed_label, False, False, 0)
            page.pack_start(frame, False, False, 0)
        elif ai_state != "hidden" and not available:
            frame, box = card()
            box.pack_start(label(t("ai_title"), "aucoop-card-title", wrap=False), False, False, 0)
            box.pack_start(label(t("ai_none_fit"), "aucoop-text"), False, False, 0)
            page.pack_start(frame, False, False, 0)
        elif ai_state != "hidden" and available:
            frame, box = card()
            head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
            head.pack_start(label(t("ai_title"), "aucoop-card-title", wrap=False), True, True, 0)
            self.ai_switch = Gtk.Switch()
            self.ai_switch.connect("notify::active", lambda *_a: self.refresh())
            head.pack_end(self.ai_switch, False, False, 0)
            box.pack_start(head, False, False, 0)

            key = {"recommended": "ai_recommended", "basic": "ai_basic"}.get(ai_state, "ai_weak")
            box.pack_start(label(t(key, ram=f"{ram:.0f}"), "aucoop-text"), False, False, 0)

            if ai_model:
                box.pack_start(label(t("ai_suggested", name=ai_model["name"]), "aucoop-small"), False, False, 0)
                more = Gtk.Expander(label=t("ai_more"))
                inner = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
                inner.set_margin_top(6)
                inner.pack_start(label(t("ai_model"), "aucoop-small"), False, False, 0)
                self.ai_model_combo = Gtk.ComboBoxText()
                self.current_ai_model_id = ai_model["id"]
                self.populate_ai_model_combo(show_more=False)
                self.ai_model_combo.connect("changed", self.on_ai_model_changed)
                inner.pack_start(self.ai_model_combo, False, False, 0)

                # Each model comes with its own licence; the user accepts it.
                licence_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
                self.ai_license_label = label("", "aucoop-small", wrap=False)
                licence_row.pack_start(self.ai_license_label, False, False, 0)
                self.ai_license_link = Gtk.LinkButton(uri="", label="?")
                self.ai_license_link.set_no_show_all(True)
                licence_row.pack_start(self.ai_license_link, False, False, 0)
                inner.pack_start(licence_row, False, False, 0)
                self.on_ai_model_changed(self.ai_model_combo)
                self.show_more_models_check = Gtk.CheckButton(label=t("ai_show_more"))
                self.show_more_models_check.connect("toggled", self.on_toggle_more_models)
                inner.pack_start(self.show_more_models_check, False, False, 0)
                canirun_url = ai_cfg.get("canirun_url")
                if canirun_url:
                    check = add_class(Gtk.Button(label=t("ai_check")), "aucoop-plain")
                    check.set_halign(Gtk.Align.START)
                    check.connect("clicked", lambda _b: subprocess.Popen(["xdg-open", canirun_url]))
                    inner.pack_start(check, False, False, 0)
                more.add(inner)
                box.pack_start(more, False, False, 4)
            box.pack_start(label(t("ai_disclaimer"), "aucoop-small"), False, False, 0)
            page.pack_start(frame, False, False, 0)

        self.extras_progress = Gtk.ProgressBar()
        self.extras_progress.set_no_show_all(True)
        page.pack_start(self.extras_progress, False, False, 4)
        self.extras_status = label("", "aucoop-small")
        page.pack_start(self.extras_status, False, False, 0)

    def build_register_page(self, page):
        page.pack_start(label(t("register_title"), "aucoop-title"), False, False, 0)
        page.pack_start(label(t("register_body"), "aucoop-text"), False, False, 0)

        frame, box = card()
        grid = Gtk.Grid(column_spacing=12, row_spacing=10)
        grid.attach(label(t("register_instance"), "aucoop-small"), 0, 0, 1, 1)
        self.instance_combo = Gtk.ComboBoxText()
        self.instance_combo.append("demo", "Demo (demo.ereuse.org)")
        self.instance_combo.append("production", "Production (app.ereuse.org)")
        self.instance_combo.append("custom", t("register_custom"))
        self.instance_combo.set_active_id("demo")
        self.instance_combo.set_hexpand(True)
        self.instance_combo.connect("changed", self.on_instance_changed)
        grid.attach(self.instance_combo, 1, 0, 1, 1)

        grid.attach(label(t("register_token"), "aucoop-small"), 0, 1, 1, 1)
        self.token_entry = Gtk.Entry()
        self.token_entry.connect("changed", lambda _e: self.refresh())
        grid.attach(self.token_entry, 1, 1, 1, 1)

        self.custom_url_label = label(t("register_url"), "aucoop-small")
        self.custom_url_label.set_no_show_all(True)
        grid.attach(self.custom_url_label, 0, 2, 1, 1)
        self.custom_url_entry = Gtk.Entry()
        self.custom_url_entry.set_text("https://demo.ereuse.org/api/v1/snapshot/")
        self.custom_url_entry.set_no_show_all(True)
        grid.attach(self.custom_url_entry, 1, 2, 1, 1)
        box.pack_start(grid, False, False, 0)
        page.pack_start(frame, False, False, 6)

        self.register_progress = Gtk.ProgressBar()
        self.register_progress.set_no_show_all(True)
        page.pack_start(self.register_progress, False, False, 4)
        self.register_status = label("", "aucoop-small")
        page.pack_start(self.register_status, False, False, 0)

        result = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        self.registration_qr_image = Gtk.Image()
        self.registration_qr_image.set_no_show_all(True)
        result.pack_start(self.registration_qr_image, False, False, 0)
        self.registration_link = Gtk.LinkButton(uri="", label="")
        self.registration_link.set_no_show_all(True)
        self.registration_link.set_valign(Gtk.Align.CENTER)
        result.pack_start(self.registration_link, False, False, 0)
        page.pack_start(result, False, False, 0)

    def build_done_page(self, page):
        page.set_valign(Gtk.Align.CENTER)
        page.pack_start(image(SYMBOL_FILES, 96, white_to_transparent=True), False, False, 0)
        page.pack_start(label(t("done_title"), "aucoop-title", xalign=0.5), False, False, 0)
        page.pack_start(label(t("done_body"), "aucoop-text", xalign=0.5), False, False, 0)

        frame, self.done_list = card()
        frame.set_halign(Gtk.Align.CENTER)
        frame.set_margin_top(10)
        page.pack_start(frame, False, False, 0)

        self.done_restart_note = label(t("done_restart_note"), "aucoop-small", xalign=0.5)
        self.done_restart_note.set_no_show_all(True)
        page.pack_start(self.done_restart_note, False, False, 4)

    def enter_done_page(self):
        for child in self.done_list.get_children():
            self.done_list.remove(child)
        tips = [t("done_browser"), t("done_office")]
        if shutil.which("kiwix-desktop"):
            tips.append(t("done_kiwix"))
        if AI_RUNNER.exists():
            tips.append(t("done_ai"))
        for tip in tips:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            row.pack_start(label("✔", "item-mark done", wrap=False, xalign=0.5), False, False, 0)
            row.pack_start(label(tip, "aucoop-text"), False, False, 0)
            self.done_list.pack_start(row, False, False, 2)
        self.done_list.show_all()
        self.done_restart_note.set_visible(self.needs_restart)
        # The guide is finished: don't open it again at the next login, unless
        # setup still has to happen (scheduled for tonight, or no internet).
        if self.setup_state in ("done", "already"):
            AUTOSTART_FILE.unlink(missing_ok=True)

    # ── Shared bits for long tasks ──

    def append_log(self, line):
        if self.log_buffer.get_text(self.log_buffer.get_start_iter(), self.log_buffer.get_end_iter(), False) == t("details_empty"):
            self.log_buffer.set_text("")
        self.log_buffer.insert(self.log_buffer.get_end_iter(), line)
        self.log_view.scroll_to_iter(self.log_buffer.get_end_iter(), 0, False, 0, 0)
        return False

    def start_pulse(self, bar):
        bar.show()
        bar.set_pulse_step(0.04)
        self.determinate_bars.discard(bar)

        def tick():
            if not self.busy:
                return False
            # Once real progress is known the bar shows it instead of bouncing.
            if bar not in self.determinate_bars:
                bar.pulse()
            return True

        GLib.timeout_add(90, tick)

    def show_status(self, widget, text, css=None):
        ctx = widget.get_style_context()
        ctx.remove_class("aucoop-ok")
        ctx.remove_class("aucoop-error")
        if css:
            ctx.add_class(css)
        widget.set_text(text)
        return False

    def run_streaming(self, argv, on_line=None):
        """Run a command, send its output to the details panel, return its exit code."""
        proc = subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        assert proc.stdout is not None
        for line in proc.stdout:
            GLib.idle_add(self.append_log, line)
            if on_line:
                GLib.idle_add(on_line, line)
        return proc.wait()

    # ── Setup ──

    def mark_setup_phases(self, done, running=None):
        for i, (key, _marker) in enumerate(SETUP_PHASES):
            mark, spinner = self.setup_marks[key], self.setup_spinners[key]
            ctx = mark.get_style_context()
            if i < done:
                spinner.stop(); spinner.hide(); mark.show()
                mark.set_text("✔"); ctx.add_class("done")
            elif i == running:
                mark.hide(); spinner.show(); spinner.start()
            else:
                spinner.stop(); spinner.hide(); mark.show()
                mark.set_text("○"); ctx.remove_class("done")

    def on_setup_line(self, line):
        for i, (_key, marker) in enumerate(SETUP_PHASES):
            if line.startswith(marker):
                self.mark_setup_phases(done=i, running=i)
                self.apt = {"total": 0, "get": 0, "unpack": 0, "setup": 0}
                self.determinate_bars.discard(self.setup_progress)
                self.setup_detail.set_text("")
                return False

        match = APT_SUMMARY.match(line)
        if match:
            self.apt = {"total": int(match[1]) + int(match[2]), "get": 0, "unpack": 0, "setup": 0}
            return False
        apt = self.apt
        total = apt["total"]
        if not total:
            return False

        if match := APT_GET.match(line):
            apt["get"] = min(int(match[1]), total)
            self.setup_detail.set_text(t("setup_downloading", n=apt["get"], total=total))
        elif match := APT_UNPACK.match(line):
            apt["unpack"] = min(apt["unpack"] + 1, total)
            name = match[1].split(":")[0]
            self.setup_detail.set_text(t("setup_installing", n=apt["unpack"], total=total, name=name))
        elif match := APT_SETUP.match(line):
            apt["setup"] = min(apt["setup"] + 1, total)
            name = match[1].split(":")[0]
            self.setup_detail.set_text(t("setup_configuring", n=apt["setup"], total=total, name=name))
        else:
            return False

        # Download, unpack and set up each count for a third of the phase.
        self.determinate_bars.add(self.setup_progress)
        self.setup_progress.set_fraction((apt["get"] + apt["unpack"] + apt["setup"]) / (3 * total))
        return False

    def rotate_tips(self):
        tips = t("tips")
        state = {"i": 0}

        def tick():
            if self.setup_state != "running":
                self.setup_tip.set_text("")
                return False
            self.setup_tip.set_text(tips[state["i"] % len(tips)])
            state["i"] += 1
            return True

        tick()
        GLib.timeout_add_seconds(7, tick)

    def start_setup(self):
        if self.setup_state == "scheduled":
            self.net_card.hide()  # "Scheduled for tonight" no longer applies
        self.setup_state = "running"
        self.set_busy(True)
        self.mark_setup_phases(done=0, running=0)
        self.show_status(self.setup_status, t("setup_running"))
        self.start_pulse(self.setup_progress)
        self.rotate_tips()

        def worker():
            code = self.run_streaming(["pkexec", str(PKEXEC_RUNNER), "essential-setup"], self.on_setup_line)
            GLib.idle_add(self.finish_setup, code)

        threading.Thread(target=worker, daemon=True).start()

    def finish_setup(self, code):
        self.setup_progress.hide()
        self.setup_detail.set_text("")
        if code == 0:
            self.setup_state = "done"
            self.needs_restart = True
            self.net_card.hide()
            self.mark_setup_phases(done=len(SETUP_PHASES))
            self.show_status(self.setup_status, t("setup_done"), "aucoop-ok")
            ESSENTIAL_DONE_MARKER.parent.mkdir(parents=True, exist_ok=True)
            ESSENTIAL_DONE_MARKER.write_text("complete\n", encoding="utf-8")
            AUTOSTART_FILE.unlink(missing_ok=True)
        else:
            self.setup_state = "failed"
            self.mark_setup_phases(done=0)
            self.show_status(self.setup_status, t("setup_failed"), "aucoop-error")
        self.set_busy(False)
        return False

    # ── Connection: check, remind, schedule ──

    def net_kind(self):
        net = self.net
        if not net:
            return None
        if not net["online"]:
            return "offline"
        if net["metered"]:
            return "metered"
        if net["speed"] and net["size"] / net["speed"] > SLOW_SECONDS:
            return "slow"
        return "ok"

    def show_net_card(self, text, hint="", spinning=False):
        self.net_text.set_text(text)
        self.net_hint.set_text(hint)
        self.net_hint.set_visible(bool(hint))
        self.net_spinner.set_visible(spinning)
        if spinning:
            self.net_spinner.start()
        else:
            self.net_spinner.stop()
        self.net_card.show()

    def check_network(self):
        self.setup_state = "checking"
        self.net = None
        self.show_net_card(t("net_checking"), spinning=True)
        self.refresh()

        def worker():
            result = network_check()
            GLib.idle_add(self.on_network_checked, result)

        threading.Thread(target=worker, daemon=True).start()

    def on_network_checked(self, net):
        self.net = net
        self.setup_state = "idle"
        kind = self.net_kind()
        if kind == "offline":
            self.show_net_card(t("net_offline"), t("net_offline_hint"))
            self.setup_status.set_text("")
        else:
            if net["size"] < 5_000_000:
                text = t("net_nothing")
            elif net["speed"]:
                text = t("net_summary", size=fmt_size(net["size"]), time=fmt_duration(net["size"] / net["speed"]))
            else:
                text = t("net_summary_size", size=fmt_size(net["size"]))
            hint = {"metered": t("net_metered"), "slow": t("net_slow")}.get(kind, "")
            self.show_net_card(text, hint)
            self.show_status(self.setup_status, t("setup_password"))
        self.refresh()
        return False

    def on_reopened(self):
        """Opened again, e.g. by the online reminder: look at the connection again."""
        if self.setup_state == "reminded":
            self.go(PAGES.index("setup"))
            self.check_network()

    def start_reminder(self, unmetered):
        """Remind the user (and reopen Welcome) once the computer is online."""
        REMINDER_PID.parent.mkdir(parents=True, exist_ok=True)
        # Only one reminder at a time.
        try:
            old = int(REMINDER_PID.read_text())
            if "remind-when-online" in Path(f"/proc/{old}/cmdline").read_text(errors="ignore"):
                os.kill(old, signal.SIGTERM)
        except (OSError, ValueError):
            pass
        argv = [str(REMINDER), t("remind_title"), t("remind_body")]
        if unmetered:
            argv.append("--unmetered")
        proc = subprocess.Popen(
            argv, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        REMINDER_PID.write_text(str(proc.pid))
        self.setup_state = "reminded"
        self.show_status(self.setup_status, t("net_reminded"), "aucoop-ok")
        self.refresh()

    def schedule_tonight(self):
        self.set_busy(True)

        def worker():
            code = self.run_streaming(["pkexec", str(PKEXEC_RUNNER), "schedule-setup"])
            GLib.idle_add(self.on_scheduled, code)

        threading.Thread(target=worker, daemon=True).start()

    def on_scheduled(self, code):
        if code == 0:
            self.setup_state = "scheduled"
            self.show_net_card(t("net_scheduled"))
            self.show_status(self.setup_status, "")
        else:
            self.show_status(self.setup_status, t("setup_failed"), "aucoop-error")
        self.set_busy(False)
        return False

    # ── Extras ──

    def has_extras_selection(self):
        if any(switch.get_active() for switch in self.module_switches.values()):
            return True
        return bool(self.ai_switch and self.ai_switch.get_active())

    def start_extras(self):
        modules = [module_id for module_id, switch in self.module_switches.items() if switch.get_active()]
        want_ai = bool(self.ai_switch and self.ai_switch.get_active())
        model_id = "auto"
        if self.ai_model_combo and self.ai_model_combo.get_active_id():
            model_id = self.ai_model_combo.get_active_id()

        self.extras_state = "running"
        self.set_busy(True)
        self.show_status(self.extras_status, t("extras_running"))
        self.start_pulse(self.extras_progress)

        def worker():
            failed = False
            for module_id in modules:
                if self.run_streaming(["pkexec", str(PKEXEC_RUNNER), "install-module", module_id]) != 0:
                    failed = True
            if want_ai:
                if self.run_streaming(["pkexec", str(PKEXEC_RUNNER), "install-local-ai", model_id]) != 0:
                    failed = True
                else:
                    GLib.idle_add(self.pin_local_ai_launcher)
            GLib.idle_add(self.finish_extras, failed)

        threading.Thread(target=worker, daemon=True).start()

    def finish_extras(self, failed):
        self.extras_progress.hide()
        if failed:
            self.extras_state = "idle"
            self.show_status(self.extras_status, t("extras_failed"), "aucoop-error")
        else:
            self.extras_state = "done"
            self.show_status(self.extras_status, t("extras_done"), "aucoop-ok")
        self.set_busy(False)
        return False

    def on_remove_ai(self, _button):
        self.set_busy(True)
        self.show_status(self.extras_status, t("ai_removing"))
        self.start_pulse(self.extras_progress)

        def worker():
            code = self.run_streaming(["pkexec", str(PKEXEC_RUNNER), "uninstall-local-ai"])
            GLib.idle_add(self.finish_remove_ai, code)

        threading.Thread(target=worker, daemon=True).start()

    def finish_remove_ai(self, code):
        self.extras_progress.hide()
        if code == 0:
            self.unpin_local_ai_launcher()
            self.ai_installed = False
            self.ai_installed_label.set_text(t("ai_removed"))
            self.ai_remove_button.hide()
            self.show_status(self.extras_status, t("ai_removed"), "aucoop-ok")
        else:
            self.show_status(self.extras_status, t("extras_failed"), "aucoop-error")
        self.set_busy(False)
        return False

    def unpin_local_ai_launcher(self):
        launcher = "aucoop-local-ai.desktop"
        try:
            current = ast.literal_eval(subprocess.check_output(
                ["gsettings", "get", "org.cinnamon", "favorite-apps"], text=True).strip())
            if launcher in current:
                current.remove(launcher)
                subprocess.run(["gsettings", "set", "org.cinnamon", "favorite-apps", str(current)], check=False)
        except Exception:
            pass

        config_path = Path.home() / ".config/cinnamon/spices/grouped-window-list@cinnamon.org/2.json"
        if config_path.exists():
            try:
                data = json.loads(config_path.read_text(encoding="utf-8"))
                value = data.setdefault("pinned-apps", {}).setdefault("value", [])
                if launcher in value:
                    value.remove(launcher)
                    config_path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
            except Exception:
                pass
        return False

    def on_ai_model_changed(self, combo):
        model = next((m for m in self.config.get("local_ai", {}).get("models", [])
                      if m["id"] == combo.get_active_id()), None)
        if not model or not model.get("license"):
            self.ai_license_label.set_text("")
            self.ai_license_link.hide()
            return
        self.ai_license_label.set_text(t("ai_license", license=model["license"]))
        if model.get("license_url"):
            self.ai_license_link.set_uri(model["license_url"])
            self.ai_license_link.set_label(model["name"])
            self.ai_license_link.show()

    def on_toggle_more_models(self, _button):
        show_more = bool(self.show_more_models_check and self.show_more_models_check.get_active())
        self.populate_ai_model_combo(show_more=show_more)

    def populate_ai_model_combo(self, show_more):
        if not self.ai_model_combo:
            return

        active_id = self.ai_model_combo.get_active_id() or self.current_ai_model_id
        self.ai_model_combo.remove_all()

        visible_models = filtered_ai_models(
            self.config.get("local_ai", {}), show_more, total_ram_gb(), self.ai_free
        )
        for model in visible_models:
            self.ai_model_combo.append(model["id"], ai_model_label(model))

        visible_ids = {model["id"] for model in visible_models}
        if active_id in visible_ids:
            self.ai_model_combo.set_active_id(active_id)
        elif self.current_ai_model_id in visible_ids:
            self.ai_model_combo.set_active_id(self.current_ai_model_id)
        elif visible_models:
            self.ai_model_combo.set_active_id(visible_models[0]["id"])

    def pin_local_ai_launcher(self):
        launcher = "aucoop-local-ai.desktop"

        try:
            current = ast.literal_eval(subprocess.check_output(
                ["gsettings", "get", "org.cinnamon", "favorite-apps"],
                text=True,
            ).strip())
            if launcher not in current:
                current.append(launcher)
                subprocess.run(
                    ["gsettings", "set", "org.cinnamon", "favorite-apps", str(current)],
                    check=False,
                )
        except Exception:
            pass

        config_path = Path.home() / ".config/cinnamon/spices/grouped-window-list@cinnamon.org/2.json"
        if config_path.exists():
            try:
                data = json.loads(config_path.read_text(encoding="utf-8"))
                value = data.setdefault("pinned-apps", {}).setdefault("value", [])
                if launcher not in value:
                    value.append(launcher)
                    config_path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
            except Exception:
                pass
        return False

    # ── Registration ──

    def on_instance_changed(self, combo):
        is_custom = combo.get_active_id() == "custom"
        self.custom_url_label.set_visible(is_custom)
        self.custom_url_entry.set_visible(is_custom)
        self.refresh()

    def registration_url(self):
        instance = self.instance_combo.get_active_id()
        if instance == "demo":
            return "https://demo.ereuse.org/api/v1/snapshot/"
        if instance == "production":
            return "https://app.ereuse.org/api/v1/snapshot/"
        return self.custom_url_entry.get_text().strip()

    def start_registration(self):
        token = self.token_entry.get_text().strip()
        url = self.registration_url()
        if not url:
            return

        self.register_state = "running"
        self.set_busy(True)
        self.show_status(self.register_status, t("register_running"))
        self.registration_link.hide()
        self.registration_qr_image.hide()
        self.start_pulse(self.register_progress)
        found = {}

        def on_line(line):
            if line.startswith("url: "):
                found["url"] = line.split("url: ", 1)[1].strip()
            if line.startswith("dhid: "):
                found["dhid"] = line.split("dhid: ", 1)[1].strip()
            return False

        def worker():
            code = self.run_streaming(["pkexec", "bash", str(WORKBENCH_RUNNER), url, token], on_line)
            GLib.idle_add(self.finish_registration, code, found)

        threading.Thread(target=worker, daemon=True).start()

    def finish_registration(self, code, found):
        self.register_progress.hide()
        if code == 0:
            self.register_state = "done"
            status = t("register_done")
            if found.get("dhid"):
                status += " " + t("register_device_id", dhid=found["dhid"])
            self.show_status(self.register_status, status, "aucoop-ok")
            if found.get("url"):
                self.show_registration_result(found["url"])
        else:
            self.register_state = "idle"
            self.show_status(self.register_status, t("register_failed"), "aucoop-error")
        self.set_busy(False)
        return False

    def show_registration_result(self, url):
        self.registration_link.set_uri(url)
        self.registration_link.set_label(url)
        self.registration_link.show()

        qr_path = Path(tempfile.gettempdir()) / "aucoop-devicehub-qr.png"
        subprocess.run(["qrencode", "-s", "4", "-o", str(qr_path), url], check=False)
        if qr_path.exists():
            self.registration_qr_image.set_from_file(str(qr_path))
            self.registration_qr_image.show()


def main():
    # One Welcome at a time: opening it again (desktop icon, the online
    # reminder) brings the existing window to the front instead.
    app = Gtk.Application(application_id="org.aucoop.Welcome")

    def on_activate(app):
        if app.get_windows():
            win = app.get_windows()[0]
            win.present()
            win.on_reopened()
            return
        win = WelcomeWindow()
        app.add_window(win)
        win.show_all()
        win.go(0)

    app.connect("activate", on_activate)
    app.run(None)


if __name__ == "__main__":
    main()
