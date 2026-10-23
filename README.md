# anime-cyberpunk rice — Orchis-Pink-Dark / BeautyLine / Qogir-Dark

Reproduces this rice on a fresh EndeavourOS (GNOME/Wayland) install.

## Install

```bash
git clone https://github.com/GrimDaTrashPanda/riced-potatoes.git ~/rice
cd ~/rice
./rice-setup.sh
```

Log out and back in afterwards so the GNOME Shell theme fully applies.

## What it does

- Builds the Orchis-Pink-Dark GTK/Shell theme from upstream
- Installs BeautyLine icons (AUR, needs `yay` or `paru`)
- Installs the Qogir-Dark cursor
- Sets the wallpaper
- Enables the user-theme extension
- Applies the settings via `gsettings` and `gnome-rice.dconf`

## Repo contents

- `rice-setup.sh` — the installer
- `gnome-rice.dconf` — scoped dconf export
- `generate-dconf-dump.sh` — regenerates `gnome-rice.dconf` from a running system
- `wallpaper.png` — background image

## Notes

- `eos-qogir-icons` only exists in the EndeavourOS repos. On plain Arch the script falls back to the AUR, then to a manual install from source.
- The script is safe to re-run. It skips anything already installed.
