#!/usr/bin/env bash
#
# Copy every asset in <distdir> whose name carries the version to the same name
# without it, so a link to releases/latest/download/<name> always fetches the
# newest release:
#
#   build/stable-names.sh <version> <distdir>
#
#   Remnants-darwin-arm64-1.139.4.dmg  ->  Remnants-darwin-arm64.dmg
#   remnants-1.139.4-amd64.deb         ->  remnants-amd64.deb
#
# The copies are byte-identical, so SHA256SUMS lists both names with the same
# checksum. Running it twice changes nothing.
set -euo pipefail

version=${1:?usage: stable-names.sh <version> <distdir>}
dist=${2:?usage: stable-names.sh <version> <distdir>}

shopt -s nullglob
copied=0
for path in "$dist"/*-"$version".* "$dist"/*-"$version"-*; do
	name=${path##*/}
	stable=${name/-"$version"/}
	if [ -e "$dist/$stable" ] && ! cmp -s "$path" "$dist/$stable"; then
		echo "$stable already exists in $dist with other content." >&2
		exit 1
	fi
	cp -f -- "$path" "$dist/$stable"
	echo "$name -> $stable"
	copied=$((copied + 1))
done

if [ "$copied" -eq 0 ]; then
	echo "No asset in $dist carries version $version."
fi
