# vaporwave-digicore rice — Orchis-Pink-Dark / BeautyLine / Qogir-Dark

Reproduces the current rice on a fresh EndeavourOS (GNOME/Wayland) install.

## Repo layout

```
rice/
├── rice-setup.sh              # run this on the new machine
├── generate-dconf-dump.sh     # run this on the OLD machine first, to refresh gnome-rice.dconf
├── gnome-rice.dconf           # scoped dconf export (generated, not hand-edited)
├── wallpaper.png              # your background image, renamed for portability
└── rice-packages.txt          # `pacman -Qqe` output, for reference / bulk restore
```

## One-time: capture the current state (on Warranty-is-Void)

```bash
cd ~/rice
./generate-dconf-dump.sh                    # writes gnome-rice.dconf
cp ~/.local/share/backgrounds/2026-08-09-*.png ./wallpaper.png
pacman -Qqe > rice-packages.txt
git add -A && git commit -m "refresh rice snapshot"
```

## Replicate on a new machine

```bash
git clone <your-repo-url> rice
cd rice
./rice-setup.sh
```

That installs the packages it can, builds Orchis-Pink-Dark and clones
BeautyLine from upstream, drops the wallpaper in place, enables the
user-theme extension, and applies both `gsettings` and the scoped
`gnome-rice.dconf`.

## Notes

- `eos-qogir-icons` only exists in the EndeavourOS repos. On plain Arch the
  script falls back to AUR's `qogir-icon-theme` if you have `yay`/`paru`
  installed — otherwise it'll tell you to grab it manually.
- The full `dconf dump /org/gnome/` you generated earlier is broader than
  you want for a repo (network/geolocation state, per-window junk). Stick
  to the scoped `desktop/interface/` dump — it's the only namespace that
  actually matters for the theme.
- Re-run `rice-setup.sh` any time — it's idempotent and skips anything
  already in place.
