#!/usr/bin/env bash
#
# rice-setup.sh — reproduce the Orchis-Pink-Dark / BeautyLine / Qogir-Dark rice
# Target: EndeavourOS (GNOME/Wayland). Idempotent — safe to re-run.
#
# Usage:
#   ./rice-setup.sh
#
# Expects (optional, drop these next to the script if you have them):
#   ./wallpaper.png            — your desktop background
#   ./gnome-rice.dconf         — scoped dconf dump (see generate-dconf-dump.sh)

set -euo pipefail

THEME_DIR="$HOME/.local/share/themes"
ICON_DIR="$HOME/.local/share/icons"
BG_DIR="$HOME/.local/share/backgrounds"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\033[1;35m[rice]\033[0m %s\n' "$1"; }

mkdir -p "$THEME_DIR" "$ICON_DIR" "$BG_DIR"

# ---------------------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------------------
log "Installing packages..."
PKGS=(
  gnome-shell-extensions   # provides user-theme extension
  gnome-tweaks
  eos-qogir-icons           # Qogir-Dark cursor + icon set (EndeavourOS repo)
)

sudo pacman -Sy --needed --noconfirm "${PKGS[@]}"

if ! pacman -Qq eos-qogir-icons &>/dev/null; then
  log "eos-qogir-icons not found in repos (not on EndeavourOS?)."
  log "Falling back to AUR qogir-icon-theme via yay/paru if available."
  if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm qogir-icon-theme
  elif command -v paru &>/dev/null; then
    paru -S --needed --noconfirm qogir-icon-theme
  else
    log "No AUR helper found — install Qogir manually: https://github.com/vinceliuice/Qogir-icon-theme"
  fi
fi

# ---------------------------------------------------------------------------
# 2. Orchis-Pink-Dark GTK theme (built from source via upstream install script)
# ---------------------------------------------------------------------------
if [ ! -d "$THEME_DIR/Orchis-Pink-Dark" ]; then
  log "Building Orchis-Pink-Dark theme..."
  TMP=$(mktemp -d)
  git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git "$TMP/Orchis-theme"
  ( cd "$TMP/Orchis-theme" && ./install.sh -t pink -c dark --tweaks compact )
  rm -rf "$TMP"
else
  log "Orchis-Pink-Dark already present, skipping."
fi

# ---------------------------------------------------------------------------
# 3. BeautyLine icon theme
# ---------------------------------------------------------------------------
if [ ! -d "$ICON_DIR/BeautyLine" ]; then
  log "Cloning BeautyLine icons..."
  git clone --depth=1 https://github.com/mnjul/BeautyLine.git "$ICON_DIR/BeautyLine"
else
  log "BeautyLine already present, skipping."
fi

# ---------------------------------------------------------------------------
# 4. Wallpaper
# ---------------------------------------------------------------------------
if [ -f "$SCRIPT_DIR/wallpaper.png" ]; then
  log "Installing wallpaper..."
  cp "$SCRIPT_DIR/wallpaper.png" "$BG_DIR/rice-wallpaper.png"
  WALLPAPER_URI="file://$BG_DIR/rice-wallpaper.png"
  gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER_URI"
  gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER_URI"
  gsettings set org.gnome.desktop.background picture-options 'zoom'
else
  log "No wallpaper.png found next to script — skipping (set it manually)."
fi

# ---------------------------------------------------------------------------
# 5. Enable the user-theme extension
# ---------------------------------------------------------------------------
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || true

# ---------------------------------------------------------------------------
# 6. Apply gsettings directly (belt-and-suspenders alongside dconf load below)
# ---------------------------------------------------------------------------
log "Applying gsettings..."
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Pink-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'BeautyLine'
gsettings set org.gnome.desktop.interface cursor-theme 'Qogir-Dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface accent-color 'pink'
gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Pink-Dark'

# ---------------------------------------------------------------------------
# 7. Load scoped dconf dump if present (see generate-dconf-dump.sh to make one)
# ---------------------------------------------------------------------------
if [ -f "$SCRIPT_DIR/gnome-rice.dconf" ]; then
  log "Loading scoped dconf dump..."
  dconf load /org/gnome/desktop/interface/ < "$SCRIPT_DIR/gnome-rice.dconf"
else
  log "No gnome-rice.dconf found — skipped (gsettings above already covers the essentials)."
fi

log "Done. Log out/in (or Alt+F2 -> r on X11, or just re-login on Wayland) to make sure the shell theme fully applies."
