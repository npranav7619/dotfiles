# dotfiles

Minimal Sway desktop, managed with [GNU Stow](https://www.gnu.org/software/stow/).

- **Theme:** Catppuccin Mocha by default, click the paint-brush icon in waybar to cycle
  through Catppuccin Mocha / Gruvbox Dark / Nord / Dracula -- applied consistently across
  kitty, sway, waybar, mako, wofi and swaylock.
- **Font:** [Agave Nerd Font](https://github.com/ryanoasis/nerd-fonts).
- **Packages:** kitty (terminal), sway (compositor), waybar (bar), mako (notifications),
  wofi (launcher), swaylock (lock screen).

## Tested with

Built and verified against these versions (Ubuntu 26.04). If something in waybar
doesn't work on another machine, check its version first -- the mpris module, named
module instances (`clock#time`/`clock#date`), and the clock's calendar scroll actions
all need a reasonably recent waybar (older LTS releases may ship one too old):

| App      | Version |
|----------|---------|
| sway     | 1.11    |
| waybar   | 0.15.0  |
| kitty    | 0.45.0  |
| mako     | 1.x     |
| wofi     | 1.5.1   |
| swaylock | 1.8.4   |
| stow     | 2.4.1   |

## Usage

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

This installs the Agave Nerd Font (if not already present) and symlinks each
package's config into `~/.config` via `stow`. Any pre-existing real config
files get moved to `~/.config-backup-<timestamp>/` first, so nothing is lost.

To also install the full package list this setup was built against (Ubuntu,
includes an NVIDIA driver and GRUB packages -- read `packages-ubuntu.txt`
before running this):

```sh
./install.sh --packages
```

Note: `packages-ubuntu.txt` is a snapshot of this specific machine, including
a version-pinned `nvidia-driver-595` / `linux-modules-nvidia-595-generic-hwe-26.04`.
Exact-versioned driver packages like that eventually get dropped from Ubuntu's repos
as newer driver branches replace them, so `--packages` on a future Ubuntu release may
fail on those two lines specifically. If that happens, drop them from the file (or
swap in whatever `ubuntu-drivers devices` recommends) and re-run -- everything else
in the list is generic and not expected to go stale the same way.

### Hybrid NVIDIA laptops: black screen on login

On a hybrid-GPU laptop (NVIDIA + Intel/AMD), `./install.sh --packages` detects this
via `lspci` and automatically disables `nvidia-drm`'s modeset capability
(`/etc/modprobe.d/zzz-nvidia-drm-nomodeset.conf`). Without this, NVIDIA and the other
GPU can race for the display/KMS role at boot -- when NVIDIA occasionally wins that
race it can't actually drive the display, leaving a black screen that needs a hard
reset to clear. With modeset disabled, NVIDIA can never claim that role (it still
loads normally for compute/CUDA), so the other GPU is always the one driving the
display. This is a no-op on non-hybrid systems and skips itself if already applied.

The filename is prefixed `zzz-` deliberately: the NVIDIA driver package ships its own
`modprobe.d` file that sets `modeset=1`, and `modprobe.d` files are applied in
alphabetical order with the last one read winning. Anything that doesn't sort after
NVIDIA's own file gets silently overridden by it.

What this does **not** cover: if your compositor is launched through a custom
wrapper script that pins a specific `/dev/dri/cardN` device (as opposed to letting
the compositor pick automatically), that wrapper is inherently specific to one
machine's PCI layout and isn't something `install.sh` can safely generate for you.

## Structure

Each top-level directory is a stow package mirroring `$HOME`, e.g.
`kitty/.config/kitty/kitty.conf` links to `~/.config/kitty/kitty.conf`. To
(re)link a single package by hand: `stow -v -t ~ kitty`.


## Wallpaper
original wallpaper credits [walls-catppuccin-mocha](https://github.com/orangci/walls-catppuccin-mocha)
