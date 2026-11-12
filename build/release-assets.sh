#!/usr/bin/env bash
#
# Print the name of every file the build jobs and the PKGBUILD render make for a
# release, one per line. A release that carries all of them has every platform.
#
#   build/release-assets.sh <version>
set -euo pipefail

version=${1:?usage: release-assets.sh <version>}

cat <<EOF
RemnantsUserSetup-x64.exe
RemnantsUserSetup-arm64.exe
RemnantsSetup-x64.exe
RemnantsSetup-arm64.exe
Remnants-win32-x64-$version.zip
Remnants-win32-arm64-$version.zip
Remnants-darwin-arm64-$version.dmg
Remnants-darwin-x64-$version.dmg
Remnants-darwin-arm64-$version.zip
Remnants-darwin-x64-$version.zip
remnants-$version-amd64.deb
remnants-$version-arm64.deb
remnants-$version-x86_64.rpm
remnants-$version-aarch64.rpm
Remnants-linux-x64-$version.tar.gz
Remnants-linux-arm64-$version.tar.gz
PKGBUILD
EOF
