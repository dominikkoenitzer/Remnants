#!/usr/bin/env bash
#
# Remove an @@NAME_LONG@@ install made by install.sh.
#
#   sudo /opt/@@APPNAME@@/uninstall.sh          system-wide install
#   ~/.local/lib/@@APPNAME@@/uninstall.sh --user
#
# Your settings, keybindings and extensions live in ~/.@@APPNAME@@ and are left
# alone; delete that directory too if you want a clean slate.
set -euo pipefail

APP="@@APPNAME@@"
NAME="@@NAME_LONG@@"
ICON="@@ICON@@"

usage() {
	cat <<EOF
Uninstall $NAME.

  --user            remove a ~/.local install
  --system          remove a system-wide install (default; needs root)
  --prefix DIR      the directory the application was installed into
  -h, --help        show this message
EOF
}

mode=system
prefix=""
while [ $# -gt 0 ]; do
	case "$1" in
	--user) mode=user ;;
	--system) mode=system ;;
	--prefix)
		prefix=${2:?--prefix needs a directory}
		shift
		;;
	--prefix=*) prefix=${1#*=} ;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "unknown option: $1" >&2
		usage >&2
		exit 2
		;;
	esac
	shift
done

if [ "$mode" = user ]; then
	: "${prefix:=$HOME/.local/lib/$APP}"
	bindir="$HOME/.local/bin"
	sharedir="$HOME/.local/share"
else
	: "${prefix:=/opt/$APP}"
	bindir="/usr/local/bin"
	sharedir="/usr/share"
	if [ "$(id -u)" != 0 ]; then
		echo "Removing a system-wide install needs root; re-run it with sudo." >&2
		exit 1
	fi
fi

echo "Removing $NAME from $prefix"

# Only unlink the symlink if it still points into this install, so a second
# install elsewhere is not disturbed.
if [ -L "$bindir/$APP" ] && [ "$(readlink "$bindir/$APP")" = "$prefix/bin/$APP" ]; then
	rm -f "$bindir/$APP"
fi

rm -f \
	"$sharedir/applications/$APP.desktop" \
	"$sharedir/applications/$APP-url-handler.desktop" \
	"$sharedir/icons/hicolor/512x512/apps/$ICON.png" \
	"$sharedir/metainfo/$APP.appdata.xml" \
	"$sharedir/mime/packages/$APP-workspace.xml" \
	"$sharedir/bash-completion/completions/$APP" \
	"$sharedir/zsh/site-functions/_$APP"

rm -rf "$prefix"

command -v update-desktop-database >/dev/null && update-desktop-database -q "$sharedir/applications" || true
command -v update-mime-database >/dev/null && update-mime-database "$sharedir/mime" || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -qtf "$sharedir/icons/hicolor" || true

echo "$NAME removed. Your settings in ~/.$APP were kept."
