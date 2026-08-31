#!/usr/bin/env bash
#
# Stage a packaged Linux build into a distributable tarball.
#
#   build/linux/package-tarball.sh <arch> <version> <outdir>
#
# `npm run gulp vscode-linux-<arch>` emits the app next to the repo, as
# ../VSCode-linux-<arch>. Only the deb/rpm/snap tasks generate the desktop
# integration files, and those tasks need a Chromium sysroot plus dpkg-shlibdeps
# to compute distro dependencies. A tarball needs none of that and runs on every
# distro, so this renders the same desktop/icon/completion files from the
# templates in resources/linux, drops in install.sh, and tars the result.
set -euo pipefail

arch=${1:?usage: package-tarball.sh <arch> <version> <outdir>}
version=${2:?usage: package-tarball.sh <arch> <version> <outdir>}
outdir=${3:?usage: package-tarball.sh <arch> <version> <outdir>}

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
built="$(dirname "$repo")/VSCode-linux-$arch"

if [ ! -d "$built" ]; then
	echo "Packaged app not found at $built - run 'npm run gulp vscode-linux-$arch' first." >&2
	exit 1
fi

# cd first so node resolves a relative path: an absolute $repo is a POSIX-style
# path under Git Bash, which node on Windows cannot open.
field() { (cd "$repo" && node -p "require('./product.json').$1"); }
app=$(field applicationName)   # remnants
name_long=$(field nameLong)    # Remnants
name_short=$(field nameShort)  # Remnants
icon=$(field linuxIconName)    # remnants
url_protocol=$(field urlProtocol)
license=$(field licenseName)

# The default install prefix that install.sh and the Arch package both use. It
# is baked into the shipped .desktop files so that a plain `sudo ./install.sh`
# needs no further edits; install.sh rewrites it when --prefix says otherwise.
exec_path="/opt/$app/$app"

# --ozone-platform-hint=auto makes Electron pick Wayland when WAYLAND_DISPLAY is
# set and X11 otherwise. Without it a Wayland session (Hyprland, Sway, GNOME)
# runs Remnants through XWayland, which blurs it on fractional scaling and drops
# per-monitor DPI. Override per user via `remnants --ozone-platform-hint=x11` or
# by editing the .desktop file.
launch="$exec_path --ozone-platform-hint=auto"

stagedir=$(mktemp -d)
trap 'rm -rf "$stagedir"' EXIT
dist="Remnants-linux-$arch"
stage="$stagedir/$dist"

cp -a "$built" "$stage"

render() {
	sed -e "s|@@NAME_LONG@@|$name_long|g" \
		-e "s|@@NAME_SHORT@@|$name_short|g" \
		-e "s|@@NAME@@|$app|g" \
		-e "s|@@APPNAME@@|$app|g" \
		-e "s|@@PRODNAME@@|$name_long|g" \
		-e "s|@@EXEC@@|$launch|g" \
		-e "s|@@ICON@@|$icon|g" \
		-e "s|@@URLPROTOCOL@@|$url_protocol|g" \
		-e "s|@@LICENSE@@|$license|g" \
		-e "s|@@VERSION@@|$version|g" \
		"$1" >"$2"
}

share="$stage/share"
mkdir -p \
	"$share/applications" \
	"$share/icons/hicolor/512x512/apps" \
	"$share/metainfo" \
	"$share/mime/packages" \
	"$share/bash-completion/completions" \
	"$share/zsh/site-functions"

render "$repo/resources/linux/code.desktop" "$share/applications/$app.desktop"
render "$repo/resources/linux/code-url-handler.desktop" "$share/applications/$app-url-handler.desktop"
render "$repo/resources/linux/code.appdata.xml" "$share/metainfo/$app.appdata.xml"
render "$repo/resources/linux/code-workspace.xml" "$share/mime/packages/$app-workspace.xml"
render "$repo/resources/completions/bash/code" "$share/bash-completion/completions/$app"
render "$repo/resources/completions/zsh/_code" "$share/zsh/site-functions/_$app"
cp "$repo/resources/linux/code.png" "$share/icons/hicolor/512x512/apps/$icon.png"

render "$repo/resources/linux/tarball/install.sh" "$stage/install.sh"
render "$repo/resources/linux/tarball/uninstall.sh" "$stage/uninstall.sh"
chmod +x "$stage/install.sh" "$stage/uninstall.sh"

mkdir -p "$outdir"
tarball="$outdir/$dist-$version.tar.gz"
tar -czf "$tarball" -C "$stagedir" "$dist"
echo "Wrote $tarball ($(du -h "$tarball" | cut -f1))"
