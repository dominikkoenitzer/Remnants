#!/usr/bin/env bash
#
# Create the GitHub release for a version from the assets in <distdir> as a
# draft, or add them to it while it is still a draft. A published release is
# left alone.
#
#   build/publish-release.sh <version> <distdir> <commit>
#
# <commit> is the commit a new tag points at. Needs gh with a token that may
# write releases.
#
# This never makes a release public. The workflow writes the notes and
# SHA256SUMS next, and build/finalize-release.sh publishes the draft last.
set -euo pipefail

version=${1:?usage: publish-release.sh <version> <distdir> <commit>}
dist=${2:?usage: publish-release.sh <version> <distdir> <commit>}
commit=${3:?usage: publish-release.sh <version> <distdir> <commit>}

tag="v$version"

if is_draft=$(gh release view "$tag" --json isDraft --jq .isDraft 2>/dev/null); then
	if [ "$is_draft" != "true" ]; then
		echo "Release $tag is already published, so its files stay as they are. A fix ships under a new version." >&2
		exit 1
	fi
	echo "Draft release $tag already exists - adding this run's assets."
	gh release upload "$tag" "$dist"/* --clobber
else
	# finalize-release.sh takes these notes as the sign that the real ones are
	# still missing.
	gh release create "$tag" "$dist"/* \
		--title "Remnants v$version" \
		--notes "Publishing." \
		--target "$commit" \
		--draft
fi
