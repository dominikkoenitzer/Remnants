#!/usr/bin/env bash
#
# Build a distributable disk image from a packaged macOS build.
#
#   build/darwin/package-dmg.sh <arch> <version> <outdir>
#
# A disk image is what a macOS user expects to download: mount it, drag the app
# onto the Applications shortcut, eject. `hdiutil` is enough for that, so this
# pulls in no tooling. Run build/darwin/package-zip.sh first, or at least make
# sure the bundle is signed: the app is copied from ../VSCode-darwin-<arch> as
# it stands, and an unsigned or invalidated bundle will not launch on Apple
# silicon.
set -euo pipefail

arch=${1:?usage: package-dmg.sh <arch> <version> <outdir>}
version=${2:?usage: package-dmg.sh <arch> <version> <outdir>}
outdir=${3:?usage: package-dmg.sh <arch> <version> <outdir>}

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
built="$(dirname "$repo")/VSCode-darwin-$arch"
name_long=$(cd "$repo" && node -p "require('./product.json').nameLong")
app="$built/$name_long.app"

if [ ! -d "$app" ]; then
	echo "App bundle not found at $app - run 'npm run gulp vscode-darwin-$arch' first." >&2
	exit 1
fi

stagedir=$(mktemp -d)
mount=$(mktemp -d)
cleanup() {
	hdiutil detach "$mount" -quiet 2>/dev/null || true
	rm -rf "$stagedir" "$mount"
}
trap cleanup EXIT

# ditto rather than cp, so the signature and any symlinks inside survive.
ditto "$app" "$stagedir/$name_long.app"
ln -s /Applications "$stagedir/Applications"

mkdir -p "$outdir"
dmg="$outdir/Remnants-darwin-$arch-$version.dmg"
rm -f "$dmg"
hdiutil create -volname "$name_long" -srcfolder "$stagedir" -ov -format UDZO -quiet "$dmg"

# Mount the finished image and check what is actually inside it, rather than
# trusting that what went in came out.
hdiutil attach "$dmg" -mountpoint "$mount" -nobrowse -quiet
codesign --verify --deep --strict "$mount/$name_long.app"
test -L "$mount/Applications"
hdiutil detach "$mount" -quiet

echo "Wrote $dmg ($(du -h "$dmg" | cut -f1))"
