#!/usr/bin/env bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root."
    echo "Run it as a normal user with sudo access."
    exit 1
fi

if ! grep -q "trixie" /etc/os-release 2>/dev/null; then
    echo "Sungan installer currently supports Debian 13 (trixie)."
    exit 1
fi

SUNGAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/9] Configuring Debian backports..."

sudo mkdir -p /etc/apt/sources.list.d

cat <<'APT' | sudo tee /etc/apt/sources.list.d/backports.list >/dev/null
deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware
APT

echo "[2/9] Configuring Yazi repository..."

sudo mkdir -p /usr/share/keyrings

curl -fsSL \
    https://yazi-rs.github.io/builds/yazi-keyring.gpg \
    | sudo tee /usr/share/keyrings/yazi-keyring.gpg >/dev/null

cat <<'APT' | sudo tee /etc/apt/sources.list.d/yazi.list >/dev/null
deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main
APT

echo "[3/9] Updating package lists..."

sudo apt update

echo "[4/9] Installing base packages..."

mapfile -t BASE_PACKAGES < \
    <(grep -vE '^\s*(#|$)' "$SUNGAN_DIR/packages/base.txt")

sudo apt install -y "${BASE_PACKAGES[@]}"

echo "[5/9] Installing Yazi..."

sudo apt install -y yazi

echo "[6/9] Installing Sungan desktop from backports..."

mapfile -t BACKPORT_PACKAGES < \
    <(grep -vE '^\s*(#|$)' "$SUNGAN_DIR/packages/backports.txt")

sudo apt install -y -t trixie-backports "${BACKPORT_PACKAGES[@]}"

echo "[7/9] Enabling services..."

sudo systemctl enable --now NetworkManager
sudo systemctl enable --now ssh

echo "[8/9] Setting Fish as login shell..."

FISH="$(command -v fish)"

if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$FISH" ]]; then
    chsh -s "$FISH"
fi

mkdir -p "$HOME/.config/fish"

cat > "$HOME/.config/fish/config.fish" <<'FISH'
set -U fish_greeting
FISH

echo "[9/9] Installing Sungan configs..."

for dir in \
    hypr \
    quickshell \
    foot \
    yazi \
    zathura \
    sungan
do
    if [[ -d "$SUNGAN_DIR/config/$dir" ]]; then
        mkdir -p "$HOME/.config/$dir"
        cp -a "$SUNGAN_DIR/config/$dir/." "$HOME/.config/$dir/"
    fi
done

echo
echo "Installing JetBrainsMono Nerd Font..."

FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"

if ! fc-match "JetBrainsMono Nerd Font" | grep -qi "JetBrainsMonoNerd"; then
    mkdir -p "$FONT_DIR"

    TMP_DIR="$(mktemp -d)"

    curl -fL \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
        -o "$TMP_DIR/JetBrainsMono.tar.xz"

    tar -xf "$TMP_DIR/JetBrainsMono.tar.xz" \
        -C "$FONT_DIR"

    rm -rf "$TMP_DIR"

    fc-cache -f
fi

echo
echo "Sungan installation complete."
echo
echo "Log out and log back in."
echo "Then start:"
echo
echo "    Hyprland"
