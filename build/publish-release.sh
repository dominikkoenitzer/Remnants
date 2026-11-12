#!/usr/bin/env bash
#
# Create the GitHub release for a version from the assets in <distdir>, or add
# them to the release when it already exists.
#
#   build/publish-release.sh <version> <distdir> <draft> <commit>
#
# <draft> is true or false, as the workflow input gives it. <commit> is the
# commit a new tag points at. Needs gh with a token that may write releases.
#
# The download page links to releases/latest/download/<name>, so the latest
# release has to carry every platform. A new release that lacks one (it was not
# selected, or its build failed) is created as a draft, and the latest release
# stays where it was. The run that adds the last missing platform publishes it.
set -euo pipefail

version=${1:?usage: publish-release.sh <version> <distdir> <draft> <commit>}
dist=${2:?usage: publish-release.sh <version> <distdir> <draft> <commit>}
draft=${3:?usage: publish-release.sh <version> <distdir> <draft> <commit>}
commit=${4:?usage: publish-release.sh <version> <distdir> <draft> <commit>}

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tag="v$version"
expected=$(mktemp)
have=$(mktemp)
trap 'rm -f "$expected" "$have"' EXIT
bash "$here/release-assets.sh" "$version" > "$expected"
(cd "$dist" && ls -1) > "$have"

# Names a complete release has and the files in $have lack, one per line.
missing() { grep -vxF -f "$have" "$expected" || true; }

if gh release view "$tag" >/dev/null 2>&1; then
	echo "Release $tag already exists - updating its assets."
	gh release upload "$tag" "$dist"/* --clobber
	gh release view "$tag" --json assets --jq '.assets[].name' >> "$have"
	if [ -z "$(missing)" ] && [ "$draft" != "true" ] &&
		[ "$(gh release view "$tag" --json isDraft --jq .isDraft)" = "true" ]; then
		echo "Release $tag now has every platform - publishing it as the latest release."
		gh release edit "$tag" --draft=false --latest
	fi
else
	draft_flag=""
	if [ "$draft" = "true" ]; then
		draft_flag="--draft"
	elif [ -n "$(missing)" ]; then
		echo "Release $tag lacks these files, so it is created as a draft:"
		missing
		echo "Run the workflow again for the missing platforms; that run publishes it."
		draft_flag="--draft"
	fi
	gh release create "$tag" "$dist"/* \
		--title "Remnants v$version" \
		--notes "Publishing." \
		--target "$commit" \
		$draft_flag
fi
