#!/usr/bin/env bash
# install.sh — set up the dwm-btw desktop on Arch Linux.
#
#   ./install.sh               everything: packages, apps, configs, dwm, services
#   ./install.sh --dry-run     show what would happen, change nothing
#   ./install.sh --link        symlink configs to this repo instead of copying
#                              (edits in ~/.config then land in the repo directly)
#   ./install.sh --no-apps     skip workspace apps (Thunar, Obsidian, OBS, Brave, Code, Proton Mail)
#   ./install.sh --no-aur      skip AUR packages (and installing yay)
#   ./install.sh --configs     only deploy configs (no packages, no dwm build, no services)
#   ./install.sh --no-sddm     keep logging in with startx (no SDDM login screen)
#   ./install.sh --keyboard qwerty   QWERTY keys: Mod + 1 … 0 for workspaces, Mod + . / , for screens
#                              (default: azerty — Mod + & é " ' ( - è _ ç à, Mod + ; / ,)
#   ./install.sh --layouts us,ir     keyboard layouts, Mod+Space cycles (default fr,ir / us,ir with qwerty)
#
# Env: DWM_DIR (default ~/dwm-btw)   DWM_REPO (default https://github.com/shahinabdi/dwm.git)
#
# Existing files that differ are backed up as <file>.bak-<timestamp> before being replaced.

set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DWM_DIR=${DWM_DIR:-$HOME/dwm-btw}
DWM_REPO=${DWM_REPO:-https://github.com/shahinabdi/dwm.git}
STAMP=$(date +%Y%m%d-%H%M%S)

DRY=0 LINK=0 APPS=1 AUR=1 ONLY_CONFIGS=0 SDDM=1 KEYBOARD="" LAYOUTS=""
while (( $# )); do
	a=$1; shift
	case $a in
		--keyboard=*) KEYBOARD=${a#*=} ;;
		--keyboard)   KEYBOARD=${1:-}; shift || true ;;
		--layouts=*)  LAYOUTS=${a#*=} ;;
		--layouts)    LAYOUTS=${1:-}; shift || true ;;
		--dry-run) DRY=1 ;;
		--link)    LINK=1 ;;
		--no-apps) APPS=0 ;;
		--no-aur)  AUR=0 ;;
		--configs) ONLY_CONFIGS=1 ;;
		--no-sddm) SDDM=0 ;;
		-h|--help) sed -n '2,18p' "$0"; exit 0 ;;
		*) echo "unknown option: $a (see --help)" >&2; exit 1 ;;
	esac
done

# keyboard profile: option > existing ~/.config/dwm-btw.conf > azerty
KBD_CONF=$HOME/.config/dwm-btw.conf
KBD_GIVEN=0; [ -n "$KEYBOARD$LAYOUTS" ] && KBD_GIVEN=1
if [ -f "$KBD_CONF" ]; then
	# shellcheck disable=SC1090
	old=$( . "$KBD_CONF"; echo "${KEYBOARD:-}|${LAYOUTS:-}")
	# keep the saved layouts only when the profile is not being changed on the command line
	if [ -z "$KEYBOARD" ]; then KEYBOARD=${old%%|*}; [ -n "$LAYOUTS" ] || LAYOUTS=${old#*|}; fi
fi
KEYBOARD=${KEYBOARD:-azerty}
case $KEYBOARD in azerty|qwerty) ;; *) echo "--keyboard must be azerty or qwerty" >&2; exit 1 ;; esac
if [ -z "$LAYOUTS" ]; then [ "$KEYBOARD" = qwerty ] && LAYOUTS=us,ir || LAYOUTS=fr,ir; fi
[[ $LAYOUTS =~ ^[a-z]+(\([a-z0-9_-]+\))?(,[a-z]+(\([a-z0-9_-]+\))?)*$ ]] || { echo "bad --layouts: $LAYOUTS" >&2; exit 1; }

c_blue=$'\e[1;34m' c_yel=$'\e[1;33m' c_red=$'\e[1;31m' c_dim=$'\e[2m' c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_blue" "$*" "$c_off"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '%s  ! %s%s\n' "$c_yel" "$*" "$c_off"; }
die()  { printf '%s  x %s%s\n' "$c_red" "$*" "$c_off" >&2; exit 1; }
run()  { if (( DRY )); then printf '    %s[dry] %s%s\n' "$c_dim" "$*" "$c_off"; else "$@"; fi; }

pkgs() { grep -vE '^\s*(#|$)' "$REPO/packages/$1" | tr -s ' \n' ' '; }

# ---------------------------------------------------------------- checks
[ -f /etc/arch-release ] || die "This installer is for Arch Linux."
(( EUID != 0 )) || die "Run as your normal user (sudo is used when needed), not as root."
command -v sudo >/dev/null || die "sudo is required."

# ---------------------------------------------------------------- packages
install_packages() {
	step "Official packages"
	local list
	list=$(pkgs core.txt)
	(( APPS )) && list+=" $(pkgs apps.txt)"
	# shellcheck disable=SC2086
	run sudo pacman -S --needed --noconfirm $list

	if (( APPS && AUR )); then
		step "AUR packages"
		if ! command -v yay >/dev/null; then
			info "installing yay (AUR helper)"
			local tmp; tmp=$(mktemp -d)
			run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
			(( DRY )) || (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
			rm -rf "$tmp"
		fi
		# shellcheck disable=SC2086
		run yay -S --needed --noconfirm --answerdiff None --answerclean None $(pkgs aur.txt)
	fi
}

# ---------------------------------------------------------------- configs
# put_file <src in repo> <dest>  — copy (or symlink) with backup, @HOME@ substituted
put_file() {
	local src=$1 dst=$2
	[ -d "$(dirname "$dst")" ] || run mkdir -p "$(dirname "$dst")"
	if (( LINK )) && ! grep -q '@HOME@' "$src" 2>/dev/null; then
		if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then return; fi
		[ -e "$dst" ] || [ -L "$dst" ] && run mv "$dst" "$dst.bak-$STAMP" && info "backup: ${dst/#$HOME/\~}.bak-$STAMP"
		run ln -s "$src" "$dst"
		return
	fi
	local tmp; tmp=$(mktemp)
	sed "s|@HOME@|$HOME|g" "$src" > "$tmp"
	if [ -e "$dst" ] && ! [ -L "$dst" ] && cmp -s "$tmp" "$dst"; then rm -f "$tmp"; return; fi
	if [ -e "$dst" ] || [ -L "$dst" ]; then
		run mv "$dst" "$dst.bak-$STAMP"; info "backup: ${dst/#$HOME/\~}.bak-$STAMP"
	fi
	if (( DRY )); then rm -f "$tmp"; printf '    %s[dry] install %s%s\n' "$c_dim" "${dst/#$HOME/\~}" "$c_off"
	else install -m "$(stat -c %a "$src")" "$tmp" "$dst"; rm -f "$tmp"; fi
}

deploy_configs() {
	step "Configs -> \$HOME $( (( LINK )) && echo '(symlinks)' || echo '(copies)')"
	local p src f
	while read -r p; do
		[[ -z $p || $p == \#* ]] && continue
		src="$REPO/home/$p"
		[ -e "$src" ] || { warn "missing in repo: $p"; continue; }
		if [ -d "$src" ]; then
			while IFS= read -r -d '' f; do
				put_file "$f" "$HOME/$p/${f#"$src"/}"
			done < <(find "$src" -type f -print0)
		else
			put_file "$src" "$HOME/$p"
		fi
		info "$p"
	done < "$REPO/manifest.txt"
	run mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Pictures/Wallpapers" "$HOME/.local/bin"
	# starter wallpapers (never overwrites); the dwm repo's current.jpg is added after it is cloned
	for f in "$REPO"/wallpapers/*; do
		[ -e "$HOME/Pictures/Wallpapers/$(basename "$f")" ] || run cp "$f" "$HOME/Pictures/Wallpapers/"
	done
	(( DRY )) || systemctl --user daemon-reload 2>/dev/null || true
}

# noise-cancelling mic: needs the name of this machine's microphone
deploy_mic_filter() {
	step "Noise-cancelling microphone (RNNoise)"
	local dst="$HOME/.config/pipewire/pipewire.conf.d/99-input-denoising.conf" mic=""
	local LINK=0   # generated per machine: always a real file, never a symlink
	if command -v pactl >/dev/null && pactl info >/dev/null 2>&1; then
		mic=$(pactl list sources short | awk '$2 ~ /^alsa_input/ {print $2}' | grep -i -m1 'mic' ||
		      pactl list sources short | awk '$2 ~ /^alsa_input/ {print $2; exit}')
	fi
	if [ -z "$mic" ]; then
		warn "no microphone found (PipeWire not running yet?) — rerun ./install.sh --configs after logging in"
		return
	fi
	info "microphone: $mic"
	local tmp; tmp=$(mktemp)
	sed "s|@MIC_SOURCE@|$mic|g" "$REPO/templates/99-input-denoising.conf.in" > "$tmp"
	put_file "$tmp" "$dst"; rm -f "$tmp"
	if (( ! DRY )); then
		systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || true
		for _ in 1 2 3 4 5 6 7 8 9 10; do pactl list sources short 2>/dev/null | grep -q rnnoise_source && break; sleep 0.5; done
		pactl set-default-source rnnoise_source 2>/dev/null && info "default mic: Noise Canceling Microphone" || true
	fi
}

# ---------------------------------------------------------------- dwm + scripts
build_dwm() {
	step "dwm ($DWM_DIR)"
	if [ ! -d "$DWM_DIR/.git" ]; then
		[ -e "$DWM_DIR" ] && die "$DWM_DIR exists but is not a git checkout; set DWM_DIR=... to use another folder"
		run git clone "$DWM_REPO" "$DWM_DIR"
	elif [ -z "$(git -C "$DWM_DIR" status --porcelain --untracked-files=no -- . ':!dwm' ':!*.o')" ]; then
		run git -C "$DWM_DIR" pull --ff-only || warn "could not update $DWM_DIR (continuing with local copy)"
	else
		warn "$DWM_DIR has local changes — not pulling, building as is"
	fi
	info "keyboard profile: $KEYBOARD"
	if (( DRY )); then info "[dry] make clean && make KEYBOARD=$KEYBOARD && sudo make install"
	else (cd "$DWM_DIR" && make clean >/dev/null && make KEYBOARD="$KEYBOARD" && sudo make install); fi

	step "dwm helper scripts -> ~/.local/bin"
	local s
	for s in "$DWM_DIR"/scripts/*; do
		[ -f "$s" ] && [ -x "$s" ] || continue
		run ln -sfn "$s" "$HOME/.local/bin/$(basename "$s")"
		info "$(basename "$s")"
	done
	if [ -f "$DWM_DIR/scripts/xkb-group.c" ]; then
		run cc -O2 -o "$HOME/.local/bin/xkb-group" "$DWM_DIR/scripts/xkb-group.c" -lX11
		info "xkb-group (compiled)"
	fi
	(( DRY )) || printf 'DWM_DIR=%q\n' "$DWM_DIR" > "$HOME/.config/dwm-dev.conf"
	[ -f "$DWM_DIR/current.jpg" ] && [ ! -e "$HOME/Pictures/Wallpapers/mountain-lake.jpg" ] &&
		run cp "$DWM_DIR/current.jpg" "$HOME/Pictures/Wallpapers/mountain-lake.jpg"

	case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *)
		warn "~/.local/bin is not in PATH — add to ~/.bashrc:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
	esac
}

# ---------------------------------------------------------------- system
setup_system() {
	step "System settings (sudo)"
	run sudo install -Dm644 "$REPO/system/etc/X11/xorg.conf.d/30-touchpad.conf" /etc/X11/xorg.conf.d/30-touchpad.conf
	info "touchpad: tap-to-click, natural scrolling"
	run sudo install -Dm644 "$REPO/system/etc/systemd/system/autorandr.service.d/override.conf" \
		/etc/systemd/system/autorandr.service.d/override.conf
	run sudo systemctl daemon-reload
	info "monitors: plug in a screen -> saved layout, or extended side by side (autorandr)"
	run sudo localectl set-x11-keymap "$LAYOUTS" pc105 "" ""
	info "keyboard: $LAYOUTS (Mod+Space switches), dwm keys: $KEYBOARD"

	if (( SDDM )); then
		step "Login screen (SDDM + Sugar Candy, keyboard $LAYOUTS, dwm session = ~/.xinitrc)"
		run sudo cp -r "$REPO/sddm/sugar-candy-dwm" /usr/share/sddm/themes/
		run sudo install -Dm644 "$REPO/system/etc/sddm.conf.d/10-dwm-btw.conf" /etc/sddm.conf.d/10-dwm-btw.conf
		local xs; xs=$(mktemp)
		sed "s/^setxkbmap -layout fr,ir$/setxkbmap -layout $LAYOUTS/" "$REPO/system/etc/sddm/Xsetup-dwm-btw" > "$xs"
		run sudo install -Dm755 "$xs" /etc/sddm/Xsetup-dwm-btw
		rm -f "$xs"
		run sudo install -Dm755 "$REPO/system/usr/local/bin/dwm-session" /usr/local/bin/dwm-session
		run sudo install -Dm644 "$REPO/system/usr/local/share/xsessions/dwm.desktop" /usr/local/share/xsessions/dwm.desktop
		run sudo systemctl enable sddm.service
		info "SDDM starts at the next boot (pick the dwm session)"
	fi

	step "Services"
	run sudo systemctl enable --now NetworkManager.service
	run sudo systemctl enable --now bluetooth.service
	run systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service
	info "picom, clipmenud and xsettingsd are started by ~/.xinitrc at login"

	step "Theme"
	(( DRY )) || gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
	(( DRY )) || gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark 2>/dev/null || true
	run fc-cache -f
}

# ---------------------------------------------------------------- keyboard profile
save_keyboard() {
	step "Keyboard profile: $KEYBOARD  (layouts $LAYOUTS)"
	if [ "$KEYBOARD" = qwerty ]; then info "workspaces: Mod + 1 … 9 0   screens: Mod + . / ,"
	else info "workspaces: Mod + & é \" ' ( - è _ ç à   screens: Mod + ; / ,"; fi
	if (( KBD_GIVEN )) || [ ! -f "$KBD_CONF" ]; then
		if (( DRY )); then info "[dry] write $KBD_CONF"
		else mkdir -p "$(dirname "$KBD_CONF")"
			printf '# dwm-btw keyboard profile (dwm-keyboard / install.sh --keyboard)\nKEYBOARD=%s\nLAYOUTS=%s\n' \
				"$KEYBOARD" "$LAYOUTS" > "$KBD_CONF"; fi
	fi
	info "change later: dwm-keyboard set azerty|qwerty [layouts]"
}

# ---------------------------------------------------------------- main
printf '%sdwm-dotfiles installer%s  (repo: %s)\n' "$c_blue" "$c_off" "$REPO"
(( DRY )) && warn "dry run — nothing will be changed"

save_keyboard
if (( ONLY_CONFIGS )); then
	deploy_configs
	deploy_mic_filter
else
	install_packages
	deploy_configs
	build_dwm
	setup_system
	deploy_mic_filter
fi

step "Done"
info "Log in on a TTY and run:  startx"
info "Already in dwm? Restart it in place with Mod+Ctrl+Shift+q (or log out once)."
info "Keys cheat sheet: Mod+Shift+h    Sidebar: Mod+a"
