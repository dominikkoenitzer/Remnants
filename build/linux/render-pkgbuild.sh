#!/usr/bin/env bash
#
# Render the Arch PKGBUILD for a release.
#
#   build/linux/render-pkgbuild.sh <version> <distdir>
#
# The package pulls the published tarballs by URL, so its checksums can only be
# filled in once those tarballs exist. Run this against the directory holding the
# built assets; it writes <distdir>/PKGBUILD covering whichever architectures
# actually built, and does nothing if no Linux tarball is present.
set -euo pipefail

version=${1:?usage: render-pkgbuild.sh <version> <distdir>}
dist=${2:?usage: render-pkgbuild.sh <version> <distdir>}

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
template="$repo/resources/linux/arch/PKGBUILD.template"
base="https://github.com/dominikkoenitzer/Remnants/releases/download/v$version"

sources=$(mktemp)
trap 'rm -f "$sources"' EXIT
arches=()

# makepkg arch : the arch as it appears in our tarball names
for pair in x86_64:x64 aarch64:arm64; do
	makepkg_arch=${pair%%:*}
	dist_arch=${pair##*:}
	tarball="$dist/Remnants-linux-$dist_arch-$version.tar.gz"
	[ -f "$tarball" ] || continue
	arches+=("'$makepkg_arch'")
	sum=$(sha256sum "$tarball" | cut -d' ' -f1)
	printf 'source_%s=("%s/%s")\n' "$makepkg_arch" "$base" "$(basename "$tarball")" >>"$sources"
	printf "sha256sums_%s=('%s')\n" "$makepkg_arch" "$sum" >>"$sources"
done

if [ ${#arches[@]} -eq 0 ]; then
	echo "No Linux tarball in $dist - skipping PKGBUILD."
	exit 0
fi

desc=$(cd "$repo" && node -p "require('./package.json').description || 'A clean, AI-free code editor built on Code - OSS'")
app=$(cd "$repo" && node -p "require('./product.json').applicationName")

sed -e "s|@@PKGVER@@|$version|g" \
	-e "s|@@APPNAME@@|$app|g" \
	-e "s|@@PKGDESC@@|$desc|g" \
	-e "s|@@ARCHES@@|${arches[*]}|g" \
	-e "s|@@URL@@|https://github.com/dominikkoenitzer/Remnants|g" \
	-e "/@@SOURCES@@/r $sources" \
	-e "/@@SOURCES@@/d" \
	"$template" >"$dist/PKGBUILD"

echo "Wrote $dist/PKGBUILD for ${arches[*]}"
