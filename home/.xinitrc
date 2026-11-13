export QT_QPA_PLATFORMTHEME=qt5ct
# default terminal for apps that honour $TERMINAL: dwm-term opens the one chosen in Settings → Terminal
export TERMINAL=dwm-term
xrdb -merge "$HOME/.Xresources"
xsettingsd &   # live GTK settings (theme, font size)
xsetroot -cursor_name left_ptr

# keyboard: the system-wide layout lives in /etc/X11/xorg.conf.d/00-keyboard.conf
# (set by install.sh with localectl) so hot-plugged / reconnected keyboards get it too.
# This line is only a fallback: layouts from ~/.config/dwm-btw.conf (dwm-keyboard), default fr,ir.
"$HOME/.local/bin/dwm-keyboard" apply 2>/dev/null || setxkbmap -layout fr,ir
xset r rate 250 40

# let user services (pipewire, etc.) see the X display
systemctl --user import-environment DISPLAY XAUTHORITY TERMINAL
systemctl --user restart clipmenud   # clipboard history (Mod+v)
systemctl --user reset-failed picom 2>/dev/null; systemctl --user restart picom   # compositor (auto-restarts, logs: journalctl --user -u picom)

dwm-display apply   # saved resolution (Mod+Shift+d)
dwm-wall restore   # wallpaper + slideshow (Mod+w)
dunst &
dwm-status &
qs -c arch-sidebar &   # quickshell sidebar (Mod+a)

exec dwm
