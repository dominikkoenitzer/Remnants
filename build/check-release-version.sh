#!/usr/bin/env bash
#
# Stop a release run that would build a version it must not:
#
#   build/check-release-version.sh <version> <platforms>
#
# - The version is plain major.minor.patch. The rpm Version and the PKGBUILD
#   pkgver take no hyphen, so a suffix such as 1.139.4-remnants.1 fails twenty
#   minutes into the Linux build.
# - A published release is never built again, not even for one platform: its
#   files stay as people downloaded and verified them, and a fix ships under a
#   new version. A draft may be completed or rebuilt.
#
# Needs gh with a token that may read the repository's releases.
set -euo pipefail

version=${1:?usage: check-release-version.sh <version> <platforms>}
platforms=${2:?usage: check-release-version.sh <version> <platforms>}

if ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Version $version is not major.minor.patch. The rpm and Arch packages take no hyphen in a version; bump the patch number in package.json instead." >&2
	exit 1
fi

tag="v$version"
err=$(mktemp)
trap 'rm -f "$err"' EXIT
if is_draft=$(gh release view "$tag" --json isDraft --jq .isDraft 2> "$err"); then
	if [ "$is_draft" != "true" ]; then
		echo "$tag is already published. Bump the version in package.json for a new release." >&2
		exit 1
	fi
	echo "$tag exists as a draft; this run adds its $platforms files to it."
elif grep -q "release not found" "$err"; then
	echo "$tag is new."
else
	echo "Could not read the release $tag:" >&2
	cat "$err" >&2
	exit 1
fi
