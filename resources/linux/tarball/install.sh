#!/usr/bin/env bash
#
# Install @@NAME_LONG@@ from this tarball on any Linux distribution.
#
#   sudo ./install.sh                     system-wide (/opt/@@APPNAME@@)
#   ./install.sh --user                   just for you, no root (~/.local)
#   sudo ./install.sh --prefix /opt/foo   somewhere else
#
# On Arch, prefer the PKGBUILD from the release page so pacman owns the files.
set -euo pipefail

APP="@@APPNAME@@"
NAME="@@NAME_LONG@@"
ICON="@@ICON@@"
VERSION="@@VERSION@@"

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
	cat <<EOF
Install $NAME $VERSION.

  --user            install under ~/.local, without root
  --system          install system-wide (default; needs root)
  --prefix DIR      install the application into DIR
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
		echo "A system-wide install writes to $prefix and $sharedir." >&2
		echo "Re-run it with sudo, or install just for yourself with: ./install.sh --user" >&2
		exit 1
	fi
fi

echo "Installing $NAME $VERSION into $prefix"

# tar rather than cp so symlinks and the executable bits survive. install.sh,
# uninstall.sh and the staged share/ tree are placed separately below.
install -d "$prefix"
tar -cf - -C "$here" --exclude=./install.sh --exclude=./uninstall.sh --exclude=./share . |
	tar -xf - -C "$prefix"
install -m755 "$here/uninstall.sh" "$prefix/uninstall.sh"

# The shipped .desktop files point at the default prefix; retarget them if this
# install went elsewhere.
retarget() {
	sed "s|/opt/$APP/$APP|$prefix/$APP|g" "$1"
}

install -d "$sharedir/applications" "$sharedir/icons/hicolor/512x512/apps" \
	"$sharedir/metainfo" "$sharedir/mime/packages"
retarget "$here/share/applications/$APP.desktop" >"$sharedir/applications/$APP.desktop"
retarget "$here/share/applications/$APP-url-handler.desktop" >"$sharedir/applications/$APP-url-handler.desktop"
chmod 644 "$sharedir/applications/$APP.desktop" "$sharedir/applications/$APP-url-handler.desktop"
install -m644 "$here/share/icons/hicolor/512x512/apps/$ICON.png" "$sharedir/icons/hicolor/512x512/apps/$ICON.png"
install -m644 "$here/share/metainfo/$APP.appdata.xml" "$sharedir/metainfo/$APP.appdata.xml"
install -m644 "$here/share/mime/packages/$APP-workspace.xml" "$sharedir/mime/packages/$APP-workspace.xml"

if [ "$mode" = system ]; then
	install -Dm644 "$here/share/bash-completion/completions/$APP" "$sharedir/bash-completion/completions/$APP"
	install -Dm644 "$here/share/zsh/site-functions/_$APP" "$sharedir/zsh/site-functions/_$APP"
fi

install -d "$bindir"
ln -sfn "$prefix/bin/$APP" "$bindir/$APP"

# Chromium falls back to this helper when the kernel denies unprivileged user
# namespaces. Most distros allow them, so it usually goes unused, but the setuid
# bit keeps Remnants launching on hardened kernels that turn them off. Only
# possible as root; a --user install runs with the namespace sandbox instead.
if [ "$mode" = system ] && [ -f "$prefix/chrome-sandbox" ]; then
	chown root:root "$prefix/chrome-sandbox"
	chmod 4755 "$prefix/chrome-sandbox"
fi

# Best effort: a missing tool here only delays the menu entry showing up.
command -v update-desktop-database >/dev/null && update-desktop-database -q "$sharedir/applications" || true
command -v update-mime-database >/dev/null && update-mime-database "$sharedir/mime" || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -qtf "$sharedir/icons/hicolor" || true

uninstall_cmd="$prefix/uninstall.sh"
if [ "$mode" = user ]; then
	uninstall_cmd="$uninstall_cmd --user"
fi

echo
echo "$NAME is installed."
echo "  launch:     $APP            (or pick $NAME from your application menu)"
echo "  uninstall:  $uninstall_cmd"

case ":$PATH:" in
*":$bindir:"*) ;;
*)
	echo
	echo "Note: $bindir is not on your PATH. Add it to your shell profile:"
	echo "  export PATH=\"$bindir:\$PATH\""
	;;
esac
