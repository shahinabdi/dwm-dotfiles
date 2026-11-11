export QT_QPA_PLATFORMTHEME=qt5ct
xrdb -merge "$HOME/.Xresources"
xsettingsd &   # live GTK settings (theme, font size)
xsetroot -cursor_name left_ptr

# keyboard: the system-wide layout lives in /etc/X11/xorg.conf.d/00-keyboard.conf
# (set with `sudo localectl set-x11-keymap fr`) so hot-plugged / reconnected
# keyboards also get fr. This line is only a fallback.
setxkbmap -layout fr,ir
xset r rate 250 40

# let user services (pipewire, etc.) see the X display
systemctl --user import-environment DISPLAY XAUTHORITY
systemctl --user restart clipmenud   # clipboard history (Mod+v)
systemctl --user reset-failed picom 2>/dev/null; systemctl --user restart picom   # compositor (auto-restarts, logs: journalctl --user -u picom)

dwm-display apply   # saved resolution (Mod+Shift+d)
dwm-wall restore   # wallpaper + slideshow (Mod+w)
dunst &
dwm-status &
qs -c arch-sidebar &   # quickshell sidebar (Mod+a)

exec dwm
