#!/usr/bin/env bash
#
# generate-dconf-dump.sh — export ONLY the appearance-relevant dconf keys.
# Run this on your current (already riced) machine to produce a clean,
# portable gnome-rice.dconf to drop next to rice-setup.sh.
#
# Why not `dconf dump /org/gnome/`? That path includes things like
# NetworkManager connection metadata, geolocation caches, and per-window
# state you don't want sitting in a public dotfiles repo.

set -euo pipefail

OUT="${1:-gnome-rice.dconf}"

dconf dump /org/gnome/desktop/interface/ > "$OUT"

echo "Wrote $OUT"
echo "Contents:"
cat "$OUT"
