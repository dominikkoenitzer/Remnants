#!/usr/bin/env bash
#
# Publish the draft release for a version, as the last step of a release run:
#
#   build/finalize-release.sh <version> <draft> <commit>
#
# <draft> is true or false, as the workflow input gives it; true leaves the
# release a draft. <commit> is the commit this run built, and the published
# release gets its tag there. Needs gh with a token that may write releases.
#
# The download page links to releases/latest/download/<name>, so the latest
# release has to carry every platform. A draft that lacks one (it was not
# selected, or its build failed) stays a draft, and the latest release stays
# where it was. The run that adds the last missing platform publishes it.
#
# A release goes public only with its notes and SHA256SUMS in place. It becomes
# the latest release only when its version is above the current latest one, so
# completing an older draft cannot take "latest" back from a newer release.
set -euo pipefail

version=${1:?usage: finalize-release.sh <version> <draft> <commit>}
draft=${2:?usage: finalize-release.sh <version> <draft> <commit>}
commit=${3:?usage: finalize-release.sh <version> <draft> <commit>}

if ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Version $version is not major.minor.patch." >&2
	exit 1
fi

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tag="v$version"
have=$(mktemp)
err=$(mktemp)
trap 'rm -f "$have" "$err"' EXIT

# True when version $1 is above version $2, both major.minor.patch.
above() {
	local a b i
	IFS=. read -r -a a <<< "$1"
	IFS=. read -r -a b <<< "$2"
	for i in 0 1 2; do
		if [ "${a[i]}" -gt "${b[i]}" ]; then return 0; fi
		if [ "${a[i]}" -lt "${b[i]}" ]; then return 1; fi
	done
	return 1
}

is_draft=$(gh release view "$tag" --json isDraft --jq .isDraft)
if [ "$is_draft" != "true" ]; then
	echo "Release $tag is already published - nothing to do."
	exit 0
fi
if [ "$draft" = "true" ]; then
	echo "Release $tag stays a draft, as the draft input asks."
	exit 0
fi

gh release view "$tag" --json assets --jq '.assets[].name' > "$have"
expected=$(bash "$here/release-assets.sh" "$version")
missing=$(grep -vxF -f "$have" <<< "$expected" || true)
if [ -n "$missing" ]; then
	echo "Release $tag lacks these files, so it stays a draft:"
	echo "$missing"
	echo "Run the workflow again for the missing platforms; that run publishes it."
	exit 0
fi

if ! grep -qxF SHA256SUMS "$have"; then
	echo "Release $tag has no SHA256SUMS yet, so it stays a draft." >&2
	exit 1
fi
# "Publishing." is what publish-release.sh creates the draft with.
notes=$(gh release view "$tag" --json body --jq .body)
if [ -z "$notes" ] || [ "$notes" = "Publishing." ]; then
	echo "Release $tag has no release notes yet, so it stays a draft." >&2
	exit 1
fi

# Without a tag, gh shows the latest release. --latest=false is spelled out:
# left to itself, GitHub makes a newly published release the latest one.
if latest=$(gh release view --json tagName --jq .tagName 2> "$err"); then
	if ! [[ $latest =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		echo "The latest release $latest is not v<major.minor.patch>, so $tag cannot be compared with it and stays a draft. Publish it by hand." >&2
		exit 1
	fi
	if above "$version" "${latest#v}"; then
		echo "Release $tag is complete and above $latest - publishing it as the latest release."
		latest_flag="--latest"
	else
		echo "Release $tag is complete but not above $latest - publishing it, and $latest stays the latest release."
		latest_flag="--latest=false"
	fi
elif grep -q "release not found" "$err"; then
	echo "Release $tag is complete and the first release - publishing it as the latest release."
	latest_flag="--latest"
else
	echo "Could not read the latest release, so $tag stays a draft:" >&2
	cat "$err" >&2
	exit 1
fi

gh release edit "$tag" --draft=false "$latest_flag" --target "$commit"
