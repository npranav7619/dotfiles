#!/usr/bin/env bash
# Reproduce this dotfiles setup on a fresh system.
#
#   ./install.sh              -- install Agave Nerd Font (if missing) + stow configs
#   ./install.sh --packages   -- also apt-get install everything in packages-ubuntu.txt
#                                 (includes an NVIDIA driver + GRUB packages -- only
#                                 pass this flag if you know that's what you want)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(foot mako sway waybar wofi)
FONT_DIR="$HOME/.local/share/fonts/Agave"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d%H%M%S)"

install_font() {
    if fc-list | grep -i "Agave Nerd Font Mono" >/dev/null; then
        echo "==> Agave Nerd Font already installed, skipping"
        return
    fi

    echo "==> Installing Agave Nerd Font"
    local tmp
    tmp="$(mktemp -d)"
    curl -fL -o "$tmp/Agave.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Agave.zip
    mkdir -p "$FONT_DIR"
    unzip -o -q "$tmp/Agave.zip" -d "$FONT_DIR"
    rm -rf "$tmp"
    fc-cache -f "$FONT_DIR" >/dev/null
}

install_packages() {
    if ! command -v apt-get >/dev/null; then
        echo "==> apt-get not found, skipping package install" >&2
        return
    fi
    echo "==> Installing packages from packages-ubuntu.txt"
    sudo apt-get update
    xargs -a "$DOTFILES_DIR/packages-ubuntu.txt" sudo apt-get install -y
}

stow_packages() {
    echo "==> Linking dotfiles with stow"
    for pkg in "${PACKAGES[@]}"; do
        for path in "$DOTFILES_DIR/$pkg/.config/"*; do
            local name target
            name="$(basename "$path")"
            target="$HOME/.config/$name"
            if [ -e "$target" ] && [ ! -L "$target" ]; then
                echo "    backing up existing $target -> $BACKUP_DIR/"
                mkdir -p "$BACKUP_DIR"
                mv "$target" "$BACKUP_DIR/"
            fi
        done
        stow -v -t "$HOME" -d "$DOTFILES_DIR" "$pkg"
    done
}

main() {
    install_font

    if [ "${1:-}" = "--packages" ]; then
        install_packages
    fi

    stow_packages

    echo "==> Done"
    echo "    Linked: ${PACKAGES[*]}"
    [ -d "$BACKUP_DIR" ] && echo "    Backed up pre-existing configs to: $BACKUP_DIR"
    echo "    Reload sway with \$mod+Shift+c (or 'swaymsg reload') to pick up changes."
}

main "$@"
