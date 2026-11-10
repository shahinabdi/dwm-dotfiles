#!/usr/bin/env bash
# sync.sh — copy your live configs (listed in manifest.txt) back into this repo,
# so changes made on this machine can be committed:
#
#   ./sync.sh && git status && git diff
#
# Your $HOME path is written back as @HOME@. Files installed with --link are
# already the repo files and are skipped.

set -euo pipefail
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

copy_back() { # live -> repo
	local live=$1 dst=$2
	[ -L "$live" ] && [ "$(readlink -f "$live")" = "$(readlink -f "$dst")" ] && return
	mkdir -p "$(dirname "$dst")"
	sed "s|$HOME|@HOME@|g" "$live" > "$dst.tmp"
	if cmp -s "$dst.tmp" "$dst" 2>/dev/null; then rm -f "$dst.tmp"; else mv "$dst.tmp" "$dst"; echo "  updated ${dst#"$REPO"/}"; fi
}

while read -r p; do
	[[ -z $p || $p == \#* ]] && continue
	live="$HOME/$p"
	[ -e "$live" ] || { echo "  missing on this machine: $p"; continue; }
	if [ -d "$live" ]; then
		while IFS= read -r -d '' f; do
			copy_back "$f" "$REPO/home/$p/${f#"$live"/}"
		done < <(find "$live" -type f -print0)
	else
		copy_back "$live" "$REPO/home/$p"
	fi
done < "$REPO/manifest.txt"

[ -f /etc/X11/xorg.conf.d/30-touchpad.conf ] &&
	copy_back /etc/X11/xorg.conf.d/30-touchpad.conf "$REPO/system/etc/X11/xorg.conf.d/30-touchpad.conf"

echo "sync done — review with: git -C \"$REPO\" diff"
