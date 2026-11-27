#!/usr/bin/env bash
#
# Render the Arch PKGBUILD for a release.
#
#   build/linux/render-pkgbuild.sh <version> <distdir>
#
# The package pulls the published tarballs by URL, so its checksums can only be
# filled in once those tarballs exist. Run this against the directory holding the
# built assets; it writes <distdir>/PKGBUILD, and does nothing if no Linux tarball
# is present. An architecture that did not build in this run (a re-run after one
# of them failed) keeps the checksum from the release's SHA256SUMS, so the
# PKGBUILD that replaces the release's one still covers it. Needs gh for that.
set -euo pipefail

version=${1:?usage: render-pkgbuild.sh <version> <distdir>}
dist=${2:?usage: render-pkgbuild.sh <version> <distdir>}

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
template="$repo/resources/linux/arch/PKGBUILD.template"
site=$(cd "$repo" && node -p "require('./product.json').downloadUrl")
base="$site/releases/download/v$version"

sources=$(mktemp)
release_sums=$(mktemp)
trap 'rm -f "$sources" "$release_sums"' EXIT
fetched=false
built=0
arches=()

# makepkg arch : the arch as it appears in our tarball names
for pair in x86_64:x64 aarch64:arm64; do
	makepkg_arch=${pair%%:*}
	dist_arch=${pair##*:}
	name="Remnants-linux-$dist_arch-$version.tar.gz"
	if [ -f "$dist/$name" ]; then
		sum=$(sha256sum "$dist/$name" | cut -d' ' -f1)
		built=$((built + 1))
	else
		if ! $fetched; then
			gh release download "v$version" -p SHA256SUMS -O "$release_sums" --clobber 2>/dev/null || : >"$release_sums"
			fetched=true
		fi
		sum=$(awk -v name="$name" '$2 == name { print $1; exit }' "$release_sums")
		[ -n "$sum" ] || continue
	fi
	arches+=("'$makepkg_arch'")
	printf 'source_%s=("%s/%s")\n' "$makepkg_arch" "$base" "$name" >>"$sources"
	printf "sha256sums_%s=('%s')\n" "$makepkg_arch" "$sum" >>"$sources"
done

if [ "$built" -eq 0 ]; then
	echo "No Linux tarball in $dist - skipping PKGBUILD."
	exit 0
fi

desc=$(cd "$repo" && node -p "require('./package.json').description || 'A clean, AI-free code editor built on Code - OSS'")
app=$(cd "$repo" && node -p "require('./product.json').applicationName")

sed -e "s|@@PKGVER@@|$version|g" \
	-e "s|@@APPNAME@@|$app|g" \
	-e "s|@@PKGDESC@@|$desc|g" \
	-e "s|@@ARCHES@@|${arches[*]}|g" \
	-e "s|@@URL@@|$site|g" \
	-e "/@@SOURCES@@/r $sources" \
	-e "/@@SOURCES@@/d" \
	"$template" >"$dist/PKGBUILD"

echo "Wrote $dist/PKGBUILD for ${arches[*]}"
