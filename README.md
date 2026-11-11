# dwm-dotfiles

Arch Linux + [dwm](https://github.com/shahinabdi/dwm) (X11) desktop: Tokyo Night colours, a Quickshell
quick-settings sidebar, rofi menus, PipeWire with a noise-cancelling mic, screenshots, clipboard history,
whole-screen scaling and an in-place dwm restart.

The dwm source and its helper scripts (`dwm-shot`, `dwm-clip`, `dwm-power`, `dwm-display`, `dwm-dev`,
`dwm-help`, `dwm-status`, …) live in the **dwm** repo; this repo holds everything else and installs both.

## Install

```sh
sudo pacman -S --needed git
git clone https://github.com/shahinabdi/dwm-dotfiles.git
cd dwm-dotfiles
./install.sh --dry-run   # see what it would do
./install.sh                      # French AZERTY keyboard (default)
./install.sh --keyboard qwerty    # QWERTY keyboard (US / UK / most others)
```

Then log in on a TTY and run `startx`.

| Option | Effect |
|---|---|
| `--dry-run` | print every action, change nothing |
| `--link` | symlink configs to this repo instead of copying (edits land in the repo) |
| `--no-apps` | skip the workspace apps |
| `--no-aur` | skip AUR packages (Brave, VS Code, Proton Mail) and yay |
| `--configs` | only deploy configs (+ the mic filter); no packages, build or services |
| `--no-sddm` | keep logging in from a TTY with `startx` |
| `--keyboard azerty\|qwerty` | which keys the workspace / screen shortcuts use (default `azerty`) |
| `--layouts us,ir` | keyboard layouts, `Mod+Space` cycles (default `fr,ir`, or `us,ir` with qwerty) |

### Keyboard profiles

| | AZERTY (default) | QWERTY |
|---|---|---|
| workspace 1–10 | `Mod + & é " ' ( - è _ ç à` | `Mod + 1 … 9 0` |
| move window to workspace | `Mod + Shift + & … à` | `Mod + Shift + 1 … 0` |
| next / previous screen | `Mod + ;` / `Mod + ,` | `Mod + .` / `Mod + ,` |
| layouts | `fr,ir` | `us,ir` |

Everything else is identical. The choice is saved in `~/.config/dwm-btw.conf`; switch later with
`dwm-keyboard set qwerty` (or `azerty`), which rebuilds and restarts dwm in place.

`DWM_DIR` (default `~/dwm-btw`) and `DWM_REPO` choose where dwm is cloned from/to.

What it does:

1. installs packages from `packages/core.txt`, `apps.txt` (pacman) and `aur.txt` (yay, installed if missing)
2. copies every path in `manifest.txt` from `home/` into `$HOME`; files that differ are first backed up
   as `<file>.bak-<timestamp>`, identical files are left alone, so re-running is safe
3. clones and builds dwm (`make KEYBOARD=azerty|qwerty && sudo make install`), links its scripts into `~/.local/bin`,
   compiles `xkb-group`
4. touchpad tap-to-click + natural scrolling, keyboard layouts (`fr,ir` or `--layouts`), enables NetworkManager,
   Bluetooth and PipeWire
5. creates the RNNoise noise-cancelling mic for this machine's microphone and makes it the default
   (needs PipeWire running — if you install from a TTY, run `./install.sh --configs` again after `startx`)

## Keeping the repo up to date

After changing configs on your machine:

```sh
./sync.sh        # copies the live files from manifest.txt back into home/
git diff
git commit -am "update configs"
```

Add a new config by listing its path in `manifest.txt` and running `./sync.sh`.

## What's inside

| Path | What |
|---|---|
| `home/.xinitrc` | session start: keyboard, xsettingsd, picom + clipmenud services, status bar, sidebar, dwm |
| `home/.config/quickshell/arch-sidebar` | sidebar (Mod+a): user/distro, Wi-Fi, Bluetooth, audio, brightness, scale/font/resolution, dwm tools, screenshots, power |
| `home/.config/rofi` | `tokyo-dwm` theme used by all menus (apps, clipboard, Wi-Fi, power, display, help) |
| `home/.config/picom`, `systemd/user/picom.service` | compositor, auto-restarted, logs in `journalctl --user -u picom` |
| `home/.config/dunst` | notifications |
| `home/.config/kitty` | terminal |
| `home/.config/fastfetch` | system info in boxed sections (Hardware / Software / Uptime), Tokyo Night colours: run `fastfetch` |
| `home/.config/gtk-3.0`, `gtk-4.0`, `.gtkrc-2.0`, `qt5ct`, `qt6ct`, `xsettingsd` | dark Adwaita, Papirus-Dark icons, JetBrains Mono, live GTK font changes |
| `home/.Xresources`, `.icons/default` | Capitaine cursors |
| `home/.config/flameshot` | annotate screenshots |
| `home/.config/systemd/user/clipmenud.service.d` | clipboard history: Ctrl+C copies only, 500 entries |
| `templates/99-input-denoising.conf.in` | PipeWire RNNoise filter (mic name filled in at install) |
| `system/etc/X11/xorg.conf.d/30-touchpad.conf` | tap-to-click, natural scrolling |

## Workspaces

| | 1 | 2 | 3 | 4 | 5 | 6 | 7–9 | 10 |
|---|---|---|---|---|---|---|---|---|
| app | kitty | Brave | VS Code | Thunar | Proton Mail | Obsidian | — | OBS |

Rules and icons are in `rules.h` / `tags.h` in the dwm repo.

## Keys (Mod = Super)

| Key | Action |
|---|---|
| Mod+Shift+h | cheat sheet with every binding |
| Mod+Return / Mod+d | terminal / app launcher |
| Mod+a | quick-settings sidebar |
| Mod+& é " ' ( - è _ ç à (QWERTY: Mod+1 … 0) | workspace 1–10 (Shift = move window) |
| Mod+Space | next keyboard layout (fr ⇄ ir / us ⇄ ir) |
| Mod+v | clipboard history |
| Mod+Shift+s / Print | screenshot region / full screen (Mod+Print: menu) |
| Mod+Escape | power menu |
| Mod+Shift+d | display: scale, font size, resolution |
| Mod+Ctrl+Shift+q | restart dwm in place |
| Mod+; / Mod+, (QWERTY: Mod+. / Mod+,) | focus next / previous screen (each screen has its own workspaces) |
| Mod+Shift+; / , | move window to next / previous screen |
| Mod+w / Mod+Shift+w | wallpaper picker / next wallpaper |
| Mod+Shift+c | colour picker |
| Mod+Shift+g, Mod+Shift+↑/↓ | gaps on/off, bigger/smaller |
| Mod+Shift+←/→, Mod+Shift+l | cycle layouts, layout menu |
| Mod+a → ⚙ | settings: bar items, sidebar side/push, fonts (Nerd Fonts), monitors, dwm |
