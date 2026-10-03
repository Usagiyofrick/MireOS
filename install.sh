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

log() {
    printf '\n\033[1;35m[Sungan]\033[0m %s\n' "$1"
}

# ------------------------------------------------------------
# 1. Bootstrap
# ------------------------------------------------------------

log "Bootstrapping installer dependencies..."

sudo apt update

sudo apt install -y \
    ca-certificates \
    curl \
    git \
    gnupg \
    rsync

# ------------------------------------------------------------
# 2. Debian backports
# ------------------------------------------------------------

log "Configuring Debian trixie-backports..."

sudo mkdir -p /etc/apt/sources.list.d

cat <<'APT' | sudo tee /etc/apt/sources.list.d/backports.list >/dev/null
deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware
APT

# ------------------------------------------------------------
# 3. Yazi repository
# ------------------------------------------------------------

log "Configuring Yazi repository..."

sudo mkdir -p /usr/share/keyrings

curl -fsSL \
    https://yazi-rs.github.io/builds/yazi-keyring.gpg \
    | sudo tee /usr/share/keyrings/yazi-keyring.gpg >/dev/null

cat <<'APT' | sudo tee /etc/apt/sources.list.d/yazi.list >/dev/null
deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main
APT

sudo apt update

# ------------------------------------------------------------
# 4. Base packages
# ------------------------------------------------------------

log "Installing base packages..."

mapfile -t BASE_PACKAGES < <(
    grep -vE '^[[:space:]]*(#|$)' \
        "$SUNGAN_DIR/packages/base.txt"
)

if ((${#BASE_PACKAGES[@]})); then
    sudo apt install -y "${BASE_PACKAGES[@]}"
fi

# ------------------------------------------------------------
# 5. Yazi
# ------------------------------------------------------------

log "Installing Yazi..."

sudo apt install -y yazi

# ------------------------------------------------------------
# 6. Hyprland / Quickshell from backports
# ------------------------------------------------------------

log "Installing Sungan desktop packages from backports..."

mapfile -t BACKPORT_PACKAGES < <(
    grep -vE '^[[:space:]]*(#|$)' \
        "$SUNGAN_DIR/packages/backports.txt"
)

if ((${#BACKPORT_PACKAGES[@]})); then
    sudo apt install -y -t trixie-backports \
        "${BACKPORT_PACKAGES[@]}"
fi

# ------------------------------------------------------------
# 7. SDDM / Astronaut dependencies
# ------------------------------------------------------------

if [[ -f "$SUNGAN_DIR/packages/sddm.txt" ]]; then
    log "Installing SDDM theme dependencies..."

    mapfile -t SDDM_PACKAGES < <(
        grep -vE '^[[:space:]]*(#|$)' \
            "$SUNGAN_DIR/packages/sddm.txt"
    )

    if ((${#SDDM_PACKAGES[@]})); then
        sudo apt install -y "${SDDM_PACKAGES[@]}"
    fi
fi

# ------------------------------------------------------------
# 8. Services
# ------------------------------------------------------------

log "Enabling services..."

sudo systemctl enable NetworkManager.service
sudo systemctl enable ssh.service
sudo systemctl enable sddm.service

sudo systemctl set-default graphical.target

# ------------------------------------------------------------
# 9. Fish
# ------------------------------------------------------------

log "Configuring Fish..."

FISH="$(command -v fish)"

if [[ -n "$FISH" ]] &&
   [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$FISH" ]]; then
    chsh -s "$FISH"
fi

mkdir -p "$HOME/.config/fish/conf.d"

cat > "$HOME/.config/fish/config.fish" <<'FISH'
set -U fish_greeting
FISH

if [[ -d "$SUNGAN_DIR/config/fish" ]]; then
    cp -a "$SUNGAN_DIR/config/fish/." \
        "$HOME/.config/fish/"
fi

# ------------------------------------------------------------
# 10. Sungan user configuration
# ------------------------------------------------------------

log "Installing Sungan configuration..."

for dir in \
    hypr \
    quickshell \
    foot \
    yazi \
    zathura \
    wofi \
    sungan
do
    if [[ -d "$SUNGAN_DIR/config/$dir" ]]; then
        mkdir -p "$HOME/.config/$dir"

        cp -a \
            "$SUNGAN_DIR/config/$dir/." \
            "$HOME/.config/$dir/"
    fi
done

# ------------------------------------------------------------
# 11. Monitor profile
# ------------------------------------------------------------

log "Selecting monitor profile..."

MONITOR_PROFILE="monitors-desktop.conf"

if find /sys/class/drm \
    -maxdepth 1 \
    -type l \
    \( -name '*-LVDS-*' -o -name '*-eDP-*' \) \
    | grep -q .; then

    MONITOR_PROFILE="monitors-laptop.conf"
    echo "Laptop panel detected."
else
    echo "Desktop monitor profile selected."
fi

MONITOR_SOURCE="$SUNGAN_DIR/config/hypr/profiles/$MONITOR_PROFILE"
MONITOR_TARGET="$HOME/.config/hypr/monitors.conf"

mkdir -p "$HOME/.config/hypr"

if [[ -f "$MONITOR_SOURCE" ]]; then
    cp "$MONITOR_SOURCE" "$MONITOR_TARGET"
    echo "Monitor profile installed: $MONITOR_PROFILE"
else
    echo "Monitor profile not found: $MONITOR_SOURCE"
    exit 1
fi

# ------------------------------------------------------------
# 12. Helper scripts
# ------------------------------------------------------------

log "Installing Sungan helper scripts..."

mkdir -p "$HOME/.local/bin"

if [[ -d "$SUNGAN_DIR/scripts" ]]; then
    cp -a \
        "$SUNGAN_DIR/scripts/." \
        "$HOME/.local/bin/"

    chmod +x "$HOME/.local/bin"/sungan-* 2>/dev/null || true
fi

# ------------------------------------------------------------
# 13. Wallpaper
# ------------------------------------------------------------

log "Installing wallpaper..."

mkdir -p "$HOME/Pictures/Wallpapers"

if [[ -f "$SUNGAN_DIR/config/wallpapers/sungan.png" ]]; then
    cp \
        "$SUNGAN_DIR/config/wallpapers/sungan.png" \
        "$HOME/Pictures/Wallpapers/sungan.png"
fi

if [[ -f "$HOME/.config/hypr/hyprpaper.conf" ]]; then
    sed -i \
        -E "s#^[[:space:]]*path[[:space:]]*=.*sungan\.png#    path = $HOME/Pictures/Wallpapers/sungan.png#" \
        "$HOME/.config/hypr/hyprpaper.conf"
fi

# ------------------------------------------------------------
# 14. SDDM Astronaut theme
# ------------------------------------------------------------

log "Installing SDDM Astronaut theme..."

ASTRONAUT_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
TMP_ASTRONAUT="$(mktemp -d)"

git clone --depth 1 \
    https://github.com/Keyitdev/sddm-astronaut-theme.git \
    "$TMP_ASTRONAUT/sddm-astronaut-theme"

sudo rm -rf "$ASTRONAUT_DIR"

sudo cp -a \
    "$TMP_ASTRONAUT/sddm-astronaut-theme" \
    "$ASTRONAUT_DIR"

rm -rf "$TMP_ASTRONAUT"

if [[ -f "$SUNGAN_DIR/config/sddm/sungan_japanese.conf" ]]; then
    sudo cp \
        "$SUNGAN_DIR/config/sddm/sungan_japanese.conf" \
        "$ASTRONAUT_DIR/Themes/sungan_japanese.conf"
fi

if [[ -f "$SUNGAN_DIR/config/sddm/astronaut-metadata.desktop" ]]; then
    sudo cp \
        "$SUNGAN_DIR/config/sddm/astronaut-metadata.desktop" \
        "$ASTRONAUT_DIR/metadata.desktop"
else
    sudo sed -i \
        's#^ConfigFile=.*#ConfigFile=Themes/sungan_japanese.conf#' \
        "$ASTRONAUT_DIR/metadata.desktop"
fi

sudo mkdir -p /etc/sddm.conf.d

if [[ -f "$SUNGAN_DIR/config/sddm/theme.conf" ]]; then
    sudo cp \
        "$SUNGAN_DIR/config/sddm/theme.conf" \
        /etc/sddm.conf.d/theme.conf
else
    cat <<'SDDM' | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
[Theme]
Current=sddm-astronaut-theme
SDDM
fi

# ------------------------------------------------------------
# 15. JetBrainsMono Nerd Font
# ------------------------------------------------------------

log "Installing JetBrainsMono Nerd Font..."

FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"

if ! fc-match "JetBrainsMono Nerd Font" | grep -qi "JetBrainsMonoNerd"; then
    mkdir -p "$FONT_DIR"

    TMP_FONT="$(mktemp -d)"

    curl -fL \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
        -o "$TMP_FONT/JetBrainsMono.tar.xz"

    tar -xf \
        "$TMP_FONT/JetBrainsMono.tar.xz" \
        -C "$FONT_DIR"

    rm -rf "$TMP_FONT"

    fc-cache -f
fi

# ------------------------------------------------------------
# 16. GTK preferences
# ------------------------------------------------------------

log "Applying desktop preferences..."

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme \
        'prefer-dark' 2>/dev/null || true

    gsettings set org.gnome.desktop.interface gtk-theme \
        'Adwaita-dark' 2>/dev/null || true

    if [[ -d /usr/share/icons/Papirus-Dark ]]; then
        gsettings set org.gnome.desktop.interface icon-theme \
            'Papirus-Dark' 2>/dev/null || true
    fi

    if [[ -d /usr/share/icons/Bibata-Modern-Ice ]]; then
        gsettings set org.gnome.desktop.interface cursor-theme \
            'Bibata-Modern-Ice' 2>/dev/null || true

        gsettings set org.gnome.desktop.interface cursor-size \
            24 2>/dev/null || true
    fi
fi

echo
echo "========================================"
echo " Sungan 순간 installation complete"
echo "========================================"
echo
echo "Reboot the system:"
echo
echo "    sudo reboot"
echo
echo "SDDM should start automatically."
echo "Select the Hyprland session if necessary."
echo
