#!/usr/bin/env bash
#
# rice-setup.sh — reproduce the Orchis-Pink-Dark / BeautyLine / Qogir-Dark rice
# Target: GNOME on Arch-based Linux (EndeavourOS, Arch, Manjaro, etc.)
#
# Usage:
#   ./rice-setup.sh
#
# Expects (optional, drop these next to the script if you have them):
#   ./wallpaper.png            — your desktop background
#   ./gnome-rice.dconf         — scoped dconf dump (see generate-dconf-dump.sh)
#
# Safe to re-run — skips anything already installed.

set -uo pipefail
# Note: deliberately NOT using `set -e` — a failure in one step (e.g. theme
# build) should not silently skip the steps after it. Each step checks its
# own success and reports clearly instead.

THEME_DIR="$HOME/.local/share/themes"
ICON_DIR="$HOME/.local/share/icons"
BG_DIR="$HOME/.local/share/backgrounds"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FAILURES=()

log()  { printf '\033[1;35m[rice]\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m[ok]\033[0m   %s\n' "$1"; }
warn() { printf '\033[1;33m[skip]\033[0m %s\n' "$1"; }
err()  { printf '\033[1;31m[fail]\033[0m %s\n' "$1"; FAILURES+=("$1"); }

echo ""
echo "=============================================="
echo "  rice-setup: Orchis-Pink-Dark / BeautyLine / Qogir-Dark"
echo "=============================================="
echo ""

# ---------------------------------------------------------------------------
# 0. Pre-flight checks — fail loud and early, in plain English
# ---------------------------------------------------------------------------
log "Running pre-flight checks..."

# 0a. Are we on an Arch-based system?
if ! command -v pacman &>/dev/null; then
  err "This script only works on Arch-based Linux (pacman not found)."
  echo ""
  echo "  You appear to be on a different distro. This rice can't be"
  echo "  auto-installed here — the theme/icon packages and package"
  echo "  manager commands are Arch-specific."
  exit 1
fi
ok "Arch-based system detected (pacman found)."

# 0b. Are we actually running GNOME?
if [ "${XDG_CURRENT_DESKTOP:-}" != "GNOME" ] && [ "${DESKTOP_SESSION:-}" != "gnome" ]; then
  err "GNOME doesn't appear to be your current desktop environment."
  echo ""
  echo "  Detected XDG_CURRENT_DESKTOP='${XDG_CURRENT_DESKTOP:-<unset>}'."
  echo "  This rice (themes, icons, gsettings, extensions) only works on"
  echo "  GNOME. If you're on KDE, XFCE, etc., these steps won't apply —"
  echo "  stop here rather than let commands fail confusingly below."
  echo ""
  read -rp "  Continue anyway? [y/N] " REPLY
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    exit 1
  fi
else
  ok "GNOME desktop detected."
fi

# 0c. Do we have sassc? (required to compile the Orchis GTK theme)
if ! command -v sassc &>/dev/null; then
  log "sassc not found (needed to build the GTK theme) — installing..."
  if ! sudo pacman -S --needed --noconfirm sassc; then
    err "Could not install sassc. The theme build in step 2 will fail without it."
    echo "  Try manually: sudo pacman -S sassc"
  fi
else
  ok "sassc present."
fi

# 0d. Do we have git?
if ! command -v git &>/dev/null; then
  log "git not found — installing..."
  sudo pacman -S --needed --noconfirm git || err "Could not install git — steps 2 and 3 need it to clone themes."
else
  ok "git present."
fi

echo ""
mkdir -p "$THEME_DIR" "$ICON_DIR" "$BG_DIR"

# ---------------------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------------------
log "Step 1/7: Installing base packages..."
PKGS=(
  gnome-shell-extensions   # provides user-theme extension
  gnome-tweaks
)

if sudo pacman -Sy --needed --noconfirm "${PKGS[@]}"; then
  ok "Base packages installed."
else
  err "Base package install failed — check your internet connection / mirrors."
fi

# Qogir cursor/icon theme: EndeavourOS ships it as eos-qogir-icons.
# On plain Arch it doesn't exist, so fall back to the AUR, and if there's
# no AUR helper, fall back further to a manual git clone + install script
# (so this doesn't just give up on non-EndeavourOS boxes).
if pacman -Si eos-qogir-icons &>/dev/null; then
  if sudo pacman -S --needed --noconfirm eos-qogir-icons; then
    ok "Qogir-Dark installed (eos-qogir-icons)."
  else
    err "eos-qogir-icons found in repos but install failed."
  fi
elif [ -d /usr/share/icons/Qogir-Dark ] || [ -d "$ICON_DIR/Qogir-Dark" ]; then
  ok "Qogir-Dark already present, skipping."
else
  warn "eos-qogir-icons not available (not on EndeavourOS)."
  if command -v yay &>/dev/null; then
    log "Installing qogir-icon-theme via yay..."
    yay -S --needed --noconfirm qogir-icon-theme && ok "Qogir installed via AUR." \
      || err "AUR install of qogir-icon-theme failed."
  elif command -v paru &>/dev/null; then
    log "Installing qogir-icon-theme via paru..."
    paru -S --needed --noconfirm qogir-icon-theme && ok "Qogir installed via AUR." \
      || err "AUR install of qogir-icon-theme failed."
  else
    log "No AUR helper (yay/paru) found. Falling back to a manual install from source..."
    TMP=$(mktemp -d)
    if git clone --depth=1 https://github.com/vinceliuice/Qogir-icon-theme.git "$TMP/Qogir-icon-theme" \
       && ( cd "$TMP/Qogir-icon-theme" && ./install.sh -d "$ICON_DIR" ); then
      ok "Qogir installed from source into $ICON_DIR."
    else
      err "Manual Qogir install failed. Get it yourself: https://github.com/vinceliuice/Qogir-icon-theme"
    fi
    rm -rf "$TMP"
  fi
fi

echo ""

# ---------------------------------------------------------------------------
# 2. Orchis-Pink-Dark GTK theme (built from source via upstream install script)
# ---------------------------------------------------------------------------
log "Step 2/7: Orchis-Pink-Dark GTK theme..."
if [ ! -d "$THEME_DIR/Orchis-Pink-Dark" ]; then
  if ! command -v sassc &>/dev/null; then
    err "Skipping theme build — sassc is missing (see pre-flight check above)."
  else
    TMP=$(mktemp -d)
    if git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git "$TMP/Orchis-theme" \
       && ( cd "$TMP/Orchis-theme" && ./install.sh -t pink -c dark --tweaks compact ); then
      ok "Orchis-Pink-Dark built and installed."
    else
      err "Orchis theme build failed. Common cause: missing build tools. Try: sudo pacman -S base-devel sassc"
    fi
    rm -rf "$TMP"
  fi
else
  ok "Orchis-Pink-Dark already present, skipping."
fi

echo ""

# ---------------------------------------------------------------------------
# 3. BeautyLine icon theme
# ---------------------------------------------------------------------------
log "Step 3/7: BeautyLine icons..."
if [ ! -d "$ICON_DIR/BeautyLine" ]; then
  if git clone --depth=1 https://github.com/mnjul/BeautyLine.git "$ICON_DIR/BeautyLine"; then
    ok "BeautyLine cloned."
  else
    err "BeautyLine clone failed — check your internet connection."
  fi
else
  ok "BeautyLine already present, skipping."
fi

echo ""

# ---------------------------------------------------------------------------
# 4. Wallpaper
# ---------------------------------------------------------------------------
log "Step 4/7: Wallpaper..."
if [ -f "$SCRIPT_DIR/wallpaper.png" ]; then
  cp "$SCRIPT_DIR/wallpaper.png" "$BG_DIR/rice-wallpaper.png"
  WALLPAPER_URI="file://$BG_DIR/rice-wallpaper.png"
  gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER_URI"
  gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER_URI"
  gsettings set org.gnome.desktop.background picture-options 'zoom'
  ok "Wallpaper installed and set."
else
  warn "No wallpaper.png found next to the script — skipping (set one manually)."
fi

echo ""

# ---------------------------------------------------------------------------
# 5. Enable the user-theme extension
# ---------------------------------------------------------------------------
log "Step 5/7: Enabling user-theme extension..."
if gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null; then
  ok "user-theme extension enabled."
else
  err "Could not enable user-theme extension. Is gnome-shell-extensions installed? (see step 1)"
fi

echo ""

# ---------------------------------------------------------------------------
# 6. Apply gsettings directly (belt-and-suspenders alongside dconf load below)
# ---------------------------------------------------------------------------
log "Step 6/7: Applying gsettings..."
GS_OK=true
gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Pink-Dark' || GS_OK=false
gsettings set org.gnome.desktop.interface icon-theme 'BeautyLine' || GS_OK=false
gsettings set org.gnome.desktop.interface cursor-theme 'Qogir-Dark' || GS_OK=false
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || GS_OK=false
gsettings set org.gnome.desktop.interface accent-color 'pink' || GS_OK=false
gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Pink-Dark' || GS_OK=false
if $GS_OK; then
  ok "gsettings applied."
else
  err "One or more gsettings failed to apply — this usually means the theme/icon/cursor packages above didn't actually install."
fi

echo ""

# ---------------------------------------------------------------------------
# 7. Load scoped dconf dump if present (see generate-dconf-dump.sh to make one)
# ---------------------------------------------------------------------------
log "Step 7/7: Loading dconf export..."
if [ -f "$SCRIPT_DIR/gnome-rice.dconf" ]; then
  if dconf load /org/gnome/desktop/interface/ < "$SCRIPT_DIR/gnome-rice.dconf"; then
    ok "dconf export loaded."
  else
    err "dconf load failed — is dconf-cli installed?"
  fi
else
  warn "No gnome-rice.dconf found — skipped (gsettings above already covers the essentials)."
fi

echo ""
echo "=============================================="
if [ ${#FAILURES[@]} -eq 0 ]; then
  echo -e "\033[1;32mDone — everything applied cleanly.\033[0m"
else
  echo -e "\033[1;31mDone, but with ${#FAILURES[@]} problem(s):\033[0m"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  echo ""
  echo "Fix those and re-run the script — it's safe to run again, it skips"
  echo "anything already in place."
fi
echo ""
echo -e "\033[1;33m>>> LOG OUT AND BACK IN NOW. <<<\033[0m"
echo "The GNOME Shell theme (top bar, overview, etc.) will not fully"
echo "apply until you do — this is not optional, and it's easy to think"
echo "the rice 'didn't work' when really it's just waiting for a re-login."
echo "=============================================="
