# dotfiles

Minimal Sway desktop, managed with [GNU Stow](https://www.gnu.org/software/stow/).

- **Theme:** Catppuccin Mocha, applied consistently across foot, sway, waybar, mako and wofi.
- **Font:** [Agave Nerd Font](https://github.com/ryanoasis/nerd-fonts).
- **Packages:** foot (terminal), sway (compositor), waybar (bar), mako (notifications), wofi (launcher).

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

## Structure

Each top-level directory is a stow package mirroring `$HOME`, e.g.
`foot/.config/foot/foot.ini` links to `~/.config/foot/foot.ini`. To
(re)link a single package by hand: `stow -v -t ~ foot`.
