#!/usr/bin/env bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root."
    echo "Run it as your normal user with sudo access."
    exit 1
fi

if ! grep -q "trixie" /etc/os-release 2>/dev/null; then
    echo "Mire installer currently expects Debian 13 (trixie)."
    exit 1
fi

MIRE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/8] Configuring Debian backports..."

sudo mkdir -p /etc/apt/sources.list.d

if [[ ! -f /etc/apt/sources.list.d/backports.list ]]; then
    echo \
        "deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware" \
        | sudo tee /etc/apt/sources.list.d/backports.list >/dev/null
fi

echo "[2/8] Updating package lists..."

sudo apt update

echo "[3/8] Installing base packages..."

mapfile -t BASE_PACKAGES < \
    <(grep -vE '^\s*(#|$)' "$MIRE_DIR/packages/base.txt")

sudo apt install -y "${BASE_PACKAGES[@]}"

echo "[4/8] Installing Mire desktop from backports..."

mapfile -t BACKPORT_PACKAGES < \
    <(grep -vE '^\s*(#|$)' "$MIRE_DIR/packages/backports.txt")

sudo apt install -y -t trixie-backports "${BACKPORT_PACKAGES[@]}"

echo "[5/8] Enabling services..."

sudo systemctl enable --now NetworkManager
sudo systemctl enable --now ssh

echo "[6/8] Setting fish as login shell..."

FISH="$(command -v fish)"

if [[ "${SHELL:-}" != "$FISH" ]]; then
    chsh -s "$FISH"
fi

mkdir -p "$HOME/.config/fish"

cat > "$HOME/.config/fish/config.fish" <<'FISH_EOF'
set -U fish_greeting
FISH_EOF

echo "[7/8] Installing JetBrainsMono Nerd Font..."

FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"

if ! fc-match "JetBrainsMono Nerd Font" \
    | grep -qi "JetBrainsMonoNerd"; then

    mkdir -p "$FONT_DIR"

    tmp="$(mktemp -d)"

    curl -fL \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
        -o "$tmp/JetBrainsMono.tar.xz"

    tar -xf "$tmp/JetBrainsMono.tar.xz" \
        -C "$FONT_DIR"

    rm -rf "$tmp"

    fc-cache -f
fi

echo "[8/8] Installing Mire configs..."

for dir in \
    hypr \
    quickshell \
    foot \
    yazi \
    zathura \
    mire
do
    if [[ -d "$MIRE_DIR/config/$dir" ]]; then
        mkdir -p "$HOME/.config/$dir"

        cp -a \
            "$MIRE_DIR/config/$dir/." \
            "$HOME/.config/$dir/"
    fi
done

echo
echo "Mire installation complete."
echo
echo "Log out and log back in so fish becomes your login shell."
echo "Then start Hyprland from the TTY with:"
echo
echo "    Hyprland"
