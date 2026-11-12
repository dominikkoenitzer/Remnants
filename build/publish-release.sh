#!/usr/bin/env bash
#
# Create the GitHub release for a version from the assets in <distdir>, or add
# them to the release when it already exists.
#
#   build/publish-release.sh <version> <distdir> <draft> <commit>
#
# <draft> is true or false, as the workflow input gives it. <commit> is the
# commit a new tag points at. Needs gh with a token that may write releases.
set -euo pipefail

version=${1:?usage: publish-release.sh <version> <distdir> <draft> <commit>}
dist=${2:?usage: publish-release.sh <version> <distdir> <draft> <commit>}
draft=${3:?usage: publish-release.sh <version> <distdir> <draft> <commit>}
commit=${4:?usage: publish-release.sh <version> <distdir> <draft> <commit>}

tag="v$version"
if gh release view "$tag" >/dev/null 2>&1; then
	echo "Release $tag already exists - updating its assets."
	gh release upload "$tag" "$dist"/* --clobber
else
	draft_flag=""
	if [ "$draft" = "true" ]; then draft_flag="--draft"; fi
	gh release create "$tag" "$dist"/* \
		--title "Remnants v$version" \
		--notes "Publishing." \
		--target "$commit" \
		$draft_flag
fi
