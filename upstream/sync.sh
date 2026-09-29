#!/usr/bin/env bash
# Bring an upstream Code - OSS release into Remnants without importing its history.
#
# Usage, from a scratch clone that has the remotes 'upstream' (microsoft/vscode)
# and 'remnants' (this repository):
#
#   upstream/sync.sh 1.140.0
#
# Git only: no npm, no build. The script three-way merges the new upstream tag
# onto remnants/main, using the tag in upstream/BASE as the merge base, then:
#   1. re-applies the removal from remove-dirs.txt and remove-files.txt,
#   2. keeps the Remnants side of every path in owned-paths.txt,
#   3. takes upstream's version of every conflicted package-lock.json,
# and writes the result as one commit on the branch sync/<tag> whose only parent
# is remnants/main. Conflicts stay in the tree as markers for a person to
# resolve. A report lands in upstream/report-<tag>/ (not committed).
set -euo pipefail

NEW=${1:?usage: upstream/sync.sh <upstream-tag>}
HERE=$(cd "$(dirname "$0")" && pwd)
read -r OLD OLD_SHA < "$HERE/BASE"

echo "Committing as: $(git config user.name) <$(git config user.email)>"

git fetch -q --depth=1 upstream tag "$OLD" tag "$NEW" --no-tags
git fetch -q remnants main:refs/remotes/remnants/main
if [ "$(git rev-parse "$OLD^{commit}")" != "$OLD_SHA" ]; then
	echo "upstream/BASE says $OLD is $OLD_SHA, but the fetched tag points elsewhere" >&2
	exit 1
fi

REP="$HERE/report-$NEW"
mkdir -p "$REP"

# 1. Three-way merge with the previous upstream tag as the explicit base.
set +e
git merge-tree --write-tree --merge-base="$OLD" remnants/main "$NEW" > "$REP/merge.txt"
status=$?
set -e
if [ "$status" -gt 1 ]; then
	echo "git merge-tree failed" >&2
	exit 1
fi
TREE=$(head -1 "$REP/merge.txt")
grep '^CONFLICT' "$REP/merge.txt" > "$REP/conflicts.txt" || true

export GIT_INDEX_FILE="$REP/index"
git read-tree "$TREE"

# 2. Re-apply the removal. Directories also drop files upstream added inside them.
grep -hv '^[[:space:]]*$' "$HERE/remove-dirs.txt" "$HERE/remove-files.txt" > "$REP/pathspec"
git rm -r -q --cached --ignore-unmatch --pathspec-from-file="$REP/pathspec"

# 3. Paths Remnants owns keep the Remnants side, conflicts included.
while read -r owned; do
	[ -z "$owned" ] && continue
	git rm -r -q --cached --ignore-unmatch -- "$owned"
	git ls-tree -r remnants/main -- "$owned" | git update-index --index-info
done < "$HERE/owned-paths.txt"

# 4. Conflicted lockfiles: take upstream's and regenerate them afterwards.
grep '^CONFLICT (content)' "$REP/conflicts.txt" | sed 's/.*Merge conflict in //' | grep 'package-lock.json$' > "$REP/locks" || true
if [ -s "$REP/locks" ]; then
	# shellcheck disable=SC2046
	git ls-tree -r "$NEW" -- $(cat "$REP/locks") | git update-index --index-info
fi

SYNCED=$(git write-tree)
unset GIT_INDEX_FILE
COMMIT=$(git commit-tree "$SYNCED" -p remnants/main -m "Bring in upstream $NEW with the removal re-applied, conflicts still unresolved")
git update-ref "refs/heads/sync/$NEW" "$COMMIT"

# 5. Gates for the person resolving the merge.
git grep -l -E '^(<<<<<<<|>>>>>>>)( |$)' "$SYNCED" | sed "s/^$SYNCED://" > "$REP/conflict-markers.txt" || true
python "$HERE/importgate.py" "$SYNCED" "$REP/imports-of-removed-modules.txt" > /dev/null
comm -13 <(git ls-tree -r --name-only "$OLD" | sort) <(git ls-tree -r --name-only "$SYNCED" | sort) > "$REP/new-files.txt"

echo "sync/$NEW -> $COMMIT"
echo "files with conflict markers: $(grep -c . "$REP/conflict-markers.txt" || true)"
echo "files importing removed modules: $(grep -c . "$REP/imports-of-removed-modules.txt" || true)"
echo "new upstream files kept, to triage for AI: $(grep -c . "$REP/new-files.txt" || true)"
