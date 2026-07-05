#!/usr/bin/env python3
"""Cycle the system color theme across sway, foot, waybar, mako, wofi and swaylock.

Rewrites the THEME:COLORS block in each app's config file, then reloads
each app live (sway reload, mako reload, SIGUSR1 to running foot instances,
restart waybar). wofi and swaylock pick up their config fresh next launch,
no reload needed.
"""
import subprocess
import sys
from pathlib import Path

# scripts/ -> waybar(.config/waybar) -> .config -> waybar(pkg) -> dotfiles root
REPO_ROOT = Path(__file__).resolve().parents[4]
STATE_FILE = Path.home() / ".cache" / "waybar-theme"

SWAY_FILE = REPO_ROOT / "sway/.config/sway/config"
FOOT_FILE = REPO_ROOT / "foot/.config/foot/foot.ini"
WAYBAR_FILE = REPO_ROOT / "waybar/.config/waybar/style.css"
MAKO_FILE = REPO_ROOT / "mako/.config/mako/config"
WOFI_FILE = REPO_ROOT / "wofi/.config/wofi/style.css"
SWAYLOCK_FILE = REPO_ROOT / "swaylock/.config/swaylock/config"

ALL_FILES = (SWAY_FILE, FOOT_FILE, WAYBAR_FILE, MAKO_FILE, WOFI_FILE, SWAYLOCK_FILE)


def check_layout() -> None:
    """Fail loudly if the repo was moved/restructured, instead of writing
    to the wrong place or crashing with a cryptic traceback mid-way through
    (which would leave some app files themed and others not)."""
    missing = [str(p) for p in ALL_FILES if not p.is_file()]
    if missing:
        sys.exit(
            "cycle-theme.py: expected config file(s) not found, "
            "REPO_ROOT may be wrong (" + str(REPO_ROOT) + "):\n  "
            + "\n  ".join(missing)
        )

THEMES = {
    "catppuccin-mocha": {
        "sway": """set $base     #1e1e2e
set $text     #cdd6f4
set $rosewater #f5e0dc
set $overlay0 #6c7086
set $mauve    #cba6f7
set $peach    #fab387""",
        "foot": """foreground=cdd6f4
background=1e1e2e

regular0=45475a
regular1=f38ba8
regular2=a6e3a1
regular3=f9e2af
regular4=89b4fa
regular5=f5c2e7
regular6=94e2d5
regular7=bac2de
bright0=585b70
bright1=f38ba8
bright2=a6e3a1
bright3=f9e2af
bright4=89b4fa
bright5=f5c2e7
bright6=94e2d5
bright7=a6adc8

selection-foreground=1e1e2e
selection-background=f5e0dc
urls=f9e2af""",
        "waybar": """@define-color base      #1e1e2e;
@define-color mantle    #181825;
@define-color text      #cdd6f4;
@define-color subtext0  #a6adc8;
@define-color surface0  #313244;
@define-color surface1  #45475a;
@define-color overlay0  #6c7086;
@define-color blue      #89b4fa;
@define-color green     #a6e3a1;
@define-color yellow    #f9e2af;
@define-color red       #f38ba8;
@define-color mauve     #cba6f7;
@define-color lavender  #b4befe;
@define-color peach     #fab387;""",
        "mako": """background-color=#1e1e2e
text-color=#cdd6f4
border-color=#cba6f7

[urgency=low]
border-color=#a6adc8

[urgency=normal]
border-color=#cba6f7

[urgency=high]
border-color=#f38ba8
text-color=#f38ba8
default-timeout=0""",
        "wofi": """@define-color base     #1e1e2e;
@define-color surface0 #313244;
@define-color text     #cdd6f4;
@define-color mauve    #cba6f7;""",
        "swaylock": """color=1e1e2e

ring-color=313244
ring-clear-color=fab387
ring-caps-lock-color=f9e2af
ring-ver-color=89b4fa
ring-wrong-color=f38ba8

inside-color=1e1e2e
inside-clear-color=313244
inside-caps-lock-color=313244
inside-ver-color=313244
inside-wrong-color=313244

key-hl-color=a6e3a1
bs-hl-color=fab387

line-color=00000000
line-clear-color=00000000
line-caps-lock-color=00000000
line-ver-color=00000000
line-wrong-color=00000000

text-color=cdd6f4
text-clear-color=cdd6f4
text-ver-color=cdd6f4
text-wrong-color=f38ba8
text-caps-lock-color=f9e2af

layout-bg-color=1e1e2e
layout-border-color=cba6f7
layout-text-color=cdd6f4

separator-color=00000000""",
    },
    "gruvbox-dark": {
        "sway": """set $base     #1d2021
set $text     #ebdbb2
set $rosewater #ebdbb2
set $overlay0 #7c6f64
set $mauve    #d3869b
set $peach    #fe8019""",
        "foot": """foreground=ebdbb2
background=1d2021

regular0=282828
regular1=cc241d
regular2=98971a
regular3=d79921
regular4=458588
regular5=b16286
regular6=689d6a
regular7=a89984
bright0=928374
bright1=fb4934
bright2=b8bb26
bright3=fabd2f
bright4=83a598
bright5=d3869b
bright6=8ec07c
bright7=ebdbb2

selection-foreground=1d2021
selection-background=ebdbb2
urls=fabd2f""",
        "waybar": """@define-color base      #1d2021;
@define-color mantle    #1d2021;
@define-color text      #ebdbb2;
@define-color subtext0  #a89984;
@define-color surface0  #3c3836;
@define-color surface1  #504945;
@define-color overlay0  #7c6f64;
@define-color blue      #83a598;
@define-color green     #b8bb26;
@define-color yellow    #fabd2f;
@define-color red       #fb4934;
@define-color mauve     #d3869b;
@define-color lavender  #8ec07c;
@define-color peach     #fe8019;""",
        "mako": """background-color=#1d2021
text-color=#ebdbb2
border-color=#d3869b

[urgency=low]
border-color=#a89984

[urgency=normal]
border-color=#d3869b

[urgency=high]
border-color=#fb4934
text-color=#fb4934
default-timeout=0""",
        "wofi": """@define-color base     #1d2021;
@define-color surface0 #3c3836;
@define-color text     #ebdbb2;
@define-color mauve    #d3869b;""",
        "swaylock": """color=1d2021

ring-color=3c3836
ring-clear-color=fe8019
ring-caps-lock-color=fabd2f
ring-ver-color=83a598
ring-wrong-color=fb4934

inside-color=1d2021
inside-clear-color=3c3836
inside-caps-lock-color=3c3836
inside-ver-color=3c3836
inside-wrong-color=3c3836

key-hl-color=b8bb26
bs-hl-color=fe8019

line-color=00000000
line-clear-color=00000000
line-caps-lock-color=00000000
line-ver-color=00000000
line-wrong-color=00000000

text-color=ebdbb2
text-clear-color=ebdbb2
text-ver-color=ebdbb2
text-wrong-color=fb4934
text-caps-lock-color=fabd2f

layout-bg-color=1d2021
layout-border-color=d3869b
layout-text-color=ebdbb2

separator-color=00000000""",
    },
    "nord": {
        "sway": """set $base     #2e3440
set $text     #eceff4
set $rosewater #eceff4
set $overlay0 #4c566a
set $mauve    #b48ead
set $peach    #d08770""",
        "foot": """foreground=d8dee9
background=2e3440

regular0=3b4252
regular1=bf616a
regular2=a3be8c
regular3=ebcb8b
regular4=81a1c1
regular5=b48ead
regular6=88c0d0
regular7=e5e9f0
bright0=4c566a
bright1=bf616a
bright2=a3be8c
bright3=ebcb8b
bright4=81a1c1
bright5=b48ead
bright6=8fbcbb
bright7=eceff4

selection-foreground=2e3440
selection-background=88c0d0
urls=ebcb8b""",
        "waybar": """@define-color base      #2e3440;
@define-color mantle    #2e3440;
@define-color text      #eceff4;
@define-color subtext0  #d8dee9;
@define-color surface0  #3b4252;
@define-color surface1  #434c5e;
@define-color overlay0  #4c566a;
@define-color blue      #81a1c1;
@define-color green     #a3be8c;
@define-color yellow    #ebcb8b;
@define-color red       #bf616a;
@define-color mauve     #b48ead;
@define-color lavender  #8fbcbb;
@define-color peach     #d08770;""",
        "mako": """background-color=#2e3440
text-color=#eceff4
border-color=#b48ead

[urgency=low]
border-color=#d8dee9

[urgency=normal]
border-color=#b48ead

[urgency=high]
border-color=#bf616a
text-color=#bf616a
default-timeout=0""",
        "wofi": """@define-color base     #2e3440;
@define-color surface0 #3b4252;
@define-color text     #eceff4;
@define-color mauve    #b48ead;""",
        "swaylock": """color=2e3440

ring-color=3b4252
ring-clear-color=d08770
ring-caps-lock-color=ebcb8b
ring-ver-color=81a1c1
ring-wrong-color=bf616a

inside-color=2e3440
inside-clear-color=3b4252
inside-caps-lock-color=3b4252
inside-ver-color=3b4252
inside-wrong-color=3b4252

key-hl-color=a3be8c
bs-hl-color=d08770

line-color=00000000
line-clear-color=00000000
line-caps-lock-color=00000000
line-ver-color=00000000
line-wrong-color=00000000

text-color=eceff4
text-clear-color=eceff4
text-ver-color=eceff4
text-wrong-color=bf616a
text-caps-lock-color=ebcb8b

layout-bg-color=2e3440
layout-border-color=b48ead
layout-text-color=eceff4

separator-color=00000000""",
    },
    "dracula": {
        "sway": """set $base     #282a36
set $text     #f8f8f2
set $rosewater #ff79c6
set $overlay0 #6272a4
set $mauve    #bd93f9
set $peach    #ffb86c""",
        "foot": """foreground=f8f8f2
background=282a36

regular0=21222c
regular1=ff5555
regular2=50fa7b
regular3=f1fa8c
regular4=bd93f9
regular5=ff79c6
regular6=8be9fd
regular7=f8f8f2
bright0=6272a4
bright1=ff6e6e
bright2=69ff94
bright3=ffffa5
bright4=d6acff
bright5=ff92df
bright6=a4ffff
bright7=ffffff

selection-foreground=f8f8f2
selection-background=44475a
urls=f1fa8c""",
        "waybar": """@define-color base      #282a36;
@define-color mantle    #21222c;
@define-color text      #f8f8f2;
@define-color subtext0  #6272a4;
@define-color surface0  #44475a;
@define-color surface1  #6272a4;
@define-color overlay0  #6272a4;
@define-color blue      #8be9fd;
@define-color green     #50fa7b;
@define-color yellow    #f1fa8c;
@define-color red       #ff5555;
@define-color mauve     #bd93f9;
@define-color lavender  #ff79c6;
@define-color peach     #ffb86c;""",
        "mako": """background-color=#282a36
text-color=#f8f8f2
border-color=#bd93f9

[urgency=low]
border-color=#6272a4

[urgency=normal]
border-color=#bd93f9

[urgency=high]
border-color=#ff5555
text-color=#ff5555
default-timeout=0""",
        "wofi": """@define-color base     #282a36;
@define-color surface0 #44475a;
@define-color text     #f8f8f2;
@define-color mauve    #bd93f9;""",
        "swaylock": """color=282a36

ring-color=44475a
ring-clear-color=ffb86c
ring-caps-lock-color=f1fa8c
ring-ver-color=8be9fd
ring-wrong-color=ff5555

inside-color=282a36
inside-clear-color=44475a
inside-caps-lock-color=44475a
inside-ver-color=44475a
inside-wrong-color=44475a

key-hl-color=50fa7b
bs-hl-color=ffb86c

line-color=00000000
line-clear-color=00000000
line-caps-lock-color=00000000
line-ver-color=00000000
line-wrong-color=00000000

text-color=f8f8f2
text-clear-color=f8f8f2
text-ver-color=f8f8f2
text-wrong-color=ff5555
text-caps-lock-color=f1fa8c

layout-bg-color=282a36
layout-border-color=bd93f9
layout-text-color=f8f8f2

separator-color=00000000""",
    },
}

THEME_ORDER = ["catppuccin-mocha", "gruvbox-dark", "nord", "dracula"]


def replace_block(path: Path, text: str, new_content: str) -> str:
    start_marker = "THEME:COLORS:START"
    end_marker = "THEME:COLORS:END"
    try:
        start_idx = text.index(start_marker)
        start_line_end = text.index("\n", start_idx) + 1
        end_idx = text.index(end_marker)
        end_line_start = text.rfind("\n", 0, end_idx) + 1
    except ValueError:
        sys.exit(f"cycle-theme.py: {path} is missing a THEME:COLORS:START/END marker pair")
    return text[:start_line_end] + new_content + "\n" + text[end_line_start:]


def apply_theme(name: str) -> None:
    theme = THEMES[name]
    targets = (
        (SWAY_FILE, "sway"),
        (FOOT_FILE, "foot"),
        (WAYBAR_FILE, "waybar"),
        (MAKO_FILE, "mako"),
        (WOFI_FILE, "wofi"),
        (SWAYLOCK_FILE, "swaylock"),
    )
    # Compute every new file's contents before writing any of them, so a
    # bad marker in one file can't leave some apps re-themed and others not.
    rewritten = {
        path: replace_block(path, path.read_text(encoding="utf-8"), theme[key])
        for path, key in targets
    }
    for path, new_text in rewritten.items():
        path.write_text(new_text, encoding="utf-8")


def reload_apps() -> None:
    subprocess.run(["swaymsg", "reload"], check=False)
    subprocess.run(["makoctl", "reload"], check=False)
    subprocess.run(["pkill", "-SIGUSR1", "foot"], check=False)
    subprocess.run(["pkill", "-x", "waybar"], check=False)
    subprocess.Popen(
        ["waybar"],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main() -> None:
    check_layout()

    current = STATE_FILE.read_text().strip() if STATE_FILE.exists() else THEME_ORDER[0]
    if current not in THEME_ORDER:
        current = THEME_ORDER[0]
    next_theme = THEME_ORDER[(THEME_ORDER.index(current) + 1) % len(THEME_ORDER)]

    apply_theme(next_theme)

    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(next_theme)

    reload_apps()


if __name__ == "__main__":
    main()
