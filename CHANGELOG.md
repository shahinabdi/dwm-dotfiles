# Changelog

All notable changes to **Lunaris**, the desktop made of two repositories released together:
[`lunaris`](https://github.com/shahinabdi/lunaris) (configs, sidebar, installer — formerly `dwm-dotfiles`) and
[`lunaris-dwm`](https://github.com/shahinabdi/lunaris-dwm) (the window manager and its helper scripts — formerly `dwm`).
Website: <https://lunaris.shahinabdi.com>.
Both repos carry the same version tags.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/) (0.x: still moving fast, things may change between versions).

Update an existing install: sidebar → ⚙ Settings → **Updates**, or `lunaris-update apply` (from 0.7.0; before that: `git pull` in both repos, then `./install.sh`).

---

## [0.9.0] — 2026-11-14 · System monitor

### Added
- **System card** in the sidebar (`Super + A`, under Audio): CPU usage and temperature, memory (and swap),
  disk usage of `/`, load, and the three busiest apps right now — refreshed every 3 s while the sidebar is open,
  bars turn yellow above 75 % and red above 90 %.
- **htop in one click**: the *htop* button (or a click on the card) opens htop in your default terminal.
  `dwm-sysinfo` / `dwm-sysinfo htop` in a terminal.
- `htop` added to the core packages.

### Notes
- If Super+Shift+Q still logs out without asking, your installed dwm predates 0.8.0: sidebar → ⚙ Settings → DWM →
  **Rebuild** once.

---

## [0.8.0] — 2026-11-13 · Default terminal, safe log out

### Added
- **Default terminal** (sidebar → ⚙ Settings → **Terminal**): pick one of the installed terminals (kitty by default;
  alacritty, ghostty, wezterm, st, xterm, urxvt, Xfce Terminal, Konsole, GNOME Terminal appear when installed).
  It is used everywhere: Mod+Return, terminal apps started from the launcher (htop, vim…), `$TERMINAL`, Thunar's
  *Open Terminal Here* and Lunaris's own windows (rebuild, update, nmtui). The workspace rule moves with it.
  `dwm-term` (`get`, `list`, `set <name>`) in a terminal.
- **Log out asks first**: Mod+Shift+Q (quit dwm) opens a small *Cancel / Log out* dialog — Cancel is selected,
  Escape cancels — so a stray key press no longer closes every app.

### Fixed
- Terminal apps from the launcher (htop, vim…) opened in **st** instead of kitty (rofi had no terminal set and
  picked the first one it found).
- Screenshot notification **Show in folder** opened the folder in a terminal: it now opens **Thunar** on the
  Screenshots folder, and folders open in Thunar by default (kitty had registered itself for folders).

### Upgrade note
- dwm is rebuilt by the update (new Mod+Return / Mod+Shift+Q bindings). Log out and in once (or restart dwm in
  place) so `$TERMINAL` is set for apps started from the session.

---

## [0.7.0] — 2026-11-13 · Updates, Lunaris name

### Added
- **Updates**: Lunaris checks for a new version every Tuesday (and at the next login if the computer was off)
  and shows a notification with an **Update now** button.
  - Sidebar → ⚙ Settings → **Updates** (at the top): installed version, **Check now**, **Update to vX**, what's new,
    and the *Check every Tuesday* switch. A dot on the ⚙ gear tells you an update is waiting.
  - The update runs in a terminal: it pulls both repos, redeploys only the configs that changed (yours are backed
    up first), adds new commands, rebuilds dwm only when its source changed (asks for your password) and restarts
    it in place. A repo with local changes is never overwritten.
  - `lunaris-update check | apply | notes | timer on|off` in a terminal.
- Website: <https://lunaris.shahinabdi.com>.

### Changed
- **The project is now called Lunaris.** Repositories: `dwm-dotfiles` → **`lunaris`**, `dwm` → **`lunaris-dwm`**
  (old GitHub links redirect). New installs clone dwm to `~/lunaris-dwm`; existing installs keep their folder.
  Settings paths (`~/.config/dwm-btw/…`, `~/.config/dwm-btw.conf`) are unchanged.

### Fixed
- **Second monitor stayed off after the screens blanked.** A monitor in deep sleep reports itself as unplugged;
  autorandr then switched to "laptop only" and the monitor never got a signal to wake up. `dwm-autorandr` now waits
  while the screens are off and decides once they wake up (a monitor that was really unplugged is still handled).
  Install: `./install.sh` again (or just update: it lists the system file and offers to run the installer).

---

## [0.6.0] — 2026-11-13 · Workspace editor

### Added
- **Workspaces page** (`Super + A` → ⚙ → Workspaces): change each workspace's icon and which apps open on
  it without touching code.
  - Icon: type text, pick one of 32 built-in icons, or paste any icon from the
    [Nerd Fonts cheat sheet](https://www.nerdfonts.com/cheat-sheet) (linked on the page).
  - Apps: add / edit / remove; pick the app from the open windows or by clicking its window;
    optional "title contains"; workspace 1–10 or *any*; jump there or open quietly; floating.
  - **Apply** restarts dwm in place (windows stay); **Reset to defaults**.
  - Tips on the page: several apps on one workspace (kitty, vim, htop…), terminal programs with their own
    class (`kitty --class htop -e htop`), exact matches (`=obs`).
- dwm reads `~/.config/dwm-btw/workspaces.conf` at start / in-place restart. Without it, the built-in
  `tags.h` / `rules.h` are used exactly as before.
- `dwm-workspaces` command: `get`, `save`, `icon`, `add`, `rm`, `windows`, `pick`, `apply`, `reset`.

### Changed
- The page warns when the running dwm is older than this feature and offers **Rebuild dwm now** (once).

### Upgrade note
- Rebuild dwm once (Settings → DWM → Rebuild, or the button on the Workspaces page).

---

## [0.5.0] — 2026-11-13 · Notifications, Bluetooth, microphone

### Added
- **Saved notifications**: every notification is kept until you delete it, even after a reboot
  (`dwm-notif`, stored in `~/.local/share/dwm-btw/notifications.jsonl`). Quick feedback pop-ups
  (volume, brightness, layouts, wallpaper…) are not saved.
- **Notifications card** at the top of the sidebar: the 3 newest, "N new" badge, delete one, **Clear all**
  (asks once), **See all**.
- **Notifications page**: grouped by day, search, filter by app or unread, click to read the whole text,
  delete the filtered ones.
- **Silent mode**: no pop-ups, everything still saved; critical alerts (battery low) still show; stays on
  after a reboot.
- **Cat icon 󰄛 on the bar** with the unread count (bell-off when silent). Left click: Notifications page ·
  middle: clear all · right: silent on/off. Can be hidden in Settings → Bar items.
- **Bluetooth card** that works: on/off, connected devices with battery, *Devices* list (connect /
  disconnect / forget), ↻ search for nearby devices and **Pair** (pair + trust + connect). `dwm-bt` helper.
- **Microphone** volume in the Audio card, next to the output: slider (drag or scroll), mute, device name.

### Changed
- New notification pop-up style: rounded cards with icons, colour by urgency, stacking, max 5 on screen,
  click actions (left: open, middle: close all, right: close).
- Rofi cheat sheet (`Super + Shift + H`) and layout menu: the highlighted row is readable.

### Fixed
- Bluetooth pairing was impossible (adapter not pairable, the card was only an on/off switch).

### Notes
- Keyboards that ask for a PIN still pair with `bluetoothctl` in a terminal.
- New package: `python` (for `dwm-notif` / `dwm-workspaces`).

---

## [0.4.0] — 2026-11-11 · Keyboard profiles, fonts, Persian titles

### Added
- **QWERTY keyboard profile** next to AZERTY (still the default): `./install.sh --keyboard qwerty`
  (`--layouts us,ir`…), `dwm-keyboard set qwerty|azerty`, or Settings → DWM → Keyboard.
  Only the workspace and screen keys change; the cheat sheet follows your profile.
- Font picker lists **all installed fonts** for the interface, with search; terminal and bar lists offer
  monospace fonts only.
- Interface font **Vazirmatn** (Latin + Persian) for GTK, Qt, rofi and notifications.
- Sidebar re-lays itself out after every monitor change (`relayout` IPC, called by autorandr / dwm-monitor).

### Fixed
- **Persian / Arabic window titles** in the bar are shown right-to-left with joined letters (FriBiDi).
- The sidebar overlapped the first screen with two monitors and did not line up with the window gaps.

---

## [0.3.0] — 2026-11-11 · Monitors, fonts, login and lock screen

### Added
- **Multi-monitor**: each screen has its own 10 workspaces; arrangement map, per-screen on/off,
  resolution, position, primary, saved layouts, automatic switching on plug / unplug (autorandr).
- **Settings page** in the sidebar (⚙): bar items on/off, sidebar side / overlay or push / width / margin,
  screen & bar size, fonts, monitors, dwm tools.
- **Nerd Fonts library**: browse ~70 fonts from nerdfonts.com, install / remove in one click; separate
  interface, terminal and bar fonts.
- **Lock screen** (`dwm-lock`): blurred wallpaper, profile picture, name; notifications paused while locked.
- **Login screen**: SDDM Sugar Candy ported to Qt6, Tokyo Night, greeting with your name and picture,
  keyboard-layout chip.
- fastfetch layout that fits the terminal.

### Changed
- Panels (the sidebar) are sticky on every workspace and can reserve space (push mode).

---

## [0.2.0] — 2026-11-11 · Sidebar, layouts, gaps, wallpapers, installer

### Added
- **dwm-dotfiles** (now `lunaris`): one-script installer (`install.sh`, `--dry-run`, `--no-apps`…), configs, `sync.sh`.
- **Quickshell sidebar** (`Super + A`): profile, Wi-Fi, Bluetooth, audio, display, wallpaper, windows,
  screenshot, power.
- **Restart dwm in place** (`Super + Ctrl + Shift + Q`): windows keep their workspaces.
- **App rules**: every app on its own workspace with icons (kitty, Brave, VS Code, Thunar, Mail, Obsidian,
  VLC, OBS); the view jumps to the app.
- **9 layouts**: tile, monocle, floating + bottom stack, centered master, grid, deck, spiral, dwindle;
  layout menu with descriptions (`Super + Shift + L`).
- **Gaps** (inner, outer, smart) for every layout.
- **Wallpaper manager**: thumbnails, next / previous / random, fit mode, slideshow.
- Colour picker (`Super + Shift + C`), profile picture and display name, bar size without rebuild.
- **Tokyo Night everywhere**: bar, GTK 3/4, Qt, kitty, rofi, dunst.

---

## [0.1.0] — 2026-11-10 · First version

### Added
- dwm 6.8 with clickable status bar (keyboard layout, network, volume, microphone, brightness, battery,
  date), media keys, picom (VSync).
- Helper scripts: clipboard history (`dwm-clip`), screenshots (`dwm-shot`), cheat sheet (`dwm-help`),
  controls (`dwm-ctl`), status bar (`dwm-status`).
- French AZERTY ⇄ Persian keyboard layouts.

[0.9.0]: https://github.com/shahinabdi/lunaris/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/shahinabdi/lunaris/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/shahinabdi/lunaris/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/shahinabdi/lunaris/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/shahinabdi/lunaris/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/shahinabdi/lunaris/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/shahinabdi/lunaris/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/shahinabdi/lunaris/releases/tag/v0.2.0
[0.1.0]: https://github.com/shahinabdi/lunaris-dwm/releases/tag/v0.1.0
