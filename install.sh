#!/usr/bin/env bash
# Reproduce this dotfiles setup on a fresh system.
#
#   ./install.sh              -- install Agave Nerd Font (if missing) + stow configs
#   ./install.sh --packages   -- also apt-get install everything in packages-ubuntu.txt,
#                                 and (only on a detected hybrid NVIDIA + other-GPU
#                                 system) apply the nvidia-drm modeset=0 fix below.
#                                 Includes an NVIDIA driver + GRUB packages -- only
#                                 pass this flag if you know that's what you want.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(kitty mako sway swaylock waybar wofi)
FONT_DIR="$HOME/.local/share/fonts/Agave"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d%H%M%S)"
# Prefixed zzz- so it sorts (and therefore wins) after the NVIDIA driver
# package's own modprobe.d files (e.g. nvidia-graphics-drivers-kms.conf),
# which set modeset=1 by default and would otherwise silently override this.
NVIDIA_MODESET_CONF="/etc/modprobe.d/zzz-nvidia-drm-nomodeset.conf"

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

fix_hybrid_nvidia() {
    if ! command -v lspci >/dev/null; then
        return
    fi

    local gpus gpu_count nvidia_count
    gpus="$(lspci | grep -Ei 'vga compatible controller|3d controller|display controller' || true)"
    gpu_count=0
    nvidia_count=0
    [ -n "$gpus" ] && gpu_count="$(printf '%s\n' "$gpus" | grep -c .)"
    [ -n "$gpus" ] && nvidia_count="$(printf '%s\n' "$gpus" | grep -ic nvidia || true)"

    if [ "$nvidia_count" -eq 0 ] || [ "$gpu_count" -lt 2 ]; then
        # Not a hybrid NVIDIA + other-GPU system -- this fix would disable
        # the only display-capable GPU on an NVIDIA-only machine, so it
        # must never run unless there's a confirmed second GPU to fall back on.
        return
    fi

    echo "==> Hybrid NVIDIA + other-GPU system detected:"
    printf '%s\n' "$gpus" | sed 's/^/    /'

    if [ -f "$NVIDIA_MODESET_CONF" ] && grep -q "modeset=0" "$NVIDIA_MODESET_CONF"; then
        echo "==> nvidia-drm modeset=0 already configured, skipping"
        return
    fi

    echo "==> Disabling nvidia-drm modeset: on hybrid laptops NVIDIA and the other"
    echo "    GPU can race for the display/KMS role at boot, occasionally leaving"
    echo "    NVIDIA in charge of a display it can't drive -- a black screen that"
    echo "    needs a hard reset to clear. This stops NVIDIA from ever claiming"
    echo "    that role; it still loads normally for compute/CUDA."
    echo "options nvidia-drm modeset=0" | sudo tee "$NVIDIA_MODESET_CONF" >/dev/null
    sudo update-initramfs -u
    echo "    Applied. Takes effect on next boot."
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
        fix_hybrid_nvidia
    fi

    stow_packages

    echo "==> Done"
    echo "    Linked: ${PACKAGES[*]}"
    [ -d "$BACKUP_DIR" ] && echo "    Backed up pre-existing configs to: $BACKUP_DIR"
    echo "    Reload sway with \$mod+Shift+c (or 'swaymsg reload') to pick up changes."
}

main "$@"
