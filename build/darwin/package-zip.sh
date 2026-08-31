#!/usr/bin/env bash
#
# Ad-hoc sign and zip a packaged macOS build.
#
#   build/darwin/package-zip.sh <arch> <version> <outdir>
#
# `npm run gulp vscode-darwin-<arch>` emits the bundle next to the repo, as
# ../VSCode-darwin-<arch>/<nameLong>.app. Two macOS specifics are handled here:
#
#  * Ad-hoc signing (`--sign -`). Apple silicon refuses to execute any arm64
#    binary without a valid signature, and gulp's packaging step rewrites files
#    inside the bundle, which invalidates the signature Electron shipped with.
#    Without this the app dies at launch with "is damaged and can't be opened".
#    This is not notarization: users still clear the quarantine flag on first
#    run (see the README).
#  * `ditto` rather than `zip`, so symlinks, resource forks and the bundle's
#    signature survive the round trip.
set -euo pipefail

arch=${1:?usage: package-zip.sh <arch> <version> <outdir>}
version=${2:?usage: package-zip.sh <arch> <version> <outdir>}
outdir=${3:?usage: package-zip.sh <arch> <version> <outdir>}

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
built="$(dirname "$repo")/VSCode-darwin-$arch"
name_long=$(cd "$repo" && node -p "require('./product.json').nameLong")
app="$built/$name_long.app"

if [ ! -d "$app" ]; then
	echo "App bundle not found at $app - run 'npm run gulp vscode-darwin-$arch' first." >&2
	exit 1
fi

# Sign nested code first, then the outer bundle. --deep is deprecated for real
# signing identities but remains the supported way to ad-hoc sign a tree of
# helper apps and frameworks in one pass.
codesign --force --deep --sign - "$app"
codesign --verify --deep --strict --verbose=2 "$app"

# Run the packaged Electron as plain node, the same way the bundled `bin/code`
# shim does. No display needed, and it fails loudly if the bundle is unusable.
name_short=$(cd "$repo" && node -p "require('./product.json').nameShort")
ELECTRON_RUN_AS_NODE=1 "$app/Contents/MacOS/$name_short" \
	"$app/Contents/Resources/app/out/cli.js" --version

mkdir -p "$outdir"
zip="$outdir/Remnants-darwin-$arch-$version.zip"
ditto -c -k --sequesterRsrc --keepParent "$app" "$zip"
echo "Wrote $zip ($(du -h "$zip" | cut -f1))"
