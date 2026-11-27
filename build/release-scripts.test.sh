#!/usr/bin/env bash
#
# Tests for the release scripts, with a stand-in gh that answers from files and
# writes down every call, so nothing reaches GitHub:
#
#   bash build/release-scripts.test.sh
set -euo pipefail
export LC_ALL=C

build=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir "$work/bin"
cat > "$work/bin/gh" <<'EOF'
#!/usr/bin/env bash
# Stand-in gh. $GH_STATE is none, draft, published or broken; $GH_ASSETS lists the
# release's assets; $GH_NOTES is its notes; $GH_LATEST is the tag of the latest
# release, empty for none or broken; $GH_SUMS is the release's SHA256SUMS, if
# it has one; every call is appended to $GH_LOG.
echo "$*" >> "$GH_LOG"
if [ "$1 $2" = "release download" ]; then
	if [ "$GH_STATE" = "none" ] || [ "$GH_STATE" = "broken" ] || [ ! -f "${GH_SUMS:-}" ]; then
		echo "release not found" >&2
		exit 1
	fi
	while [ $# -gt 0 ]; do
		if [ "$1" = "-O" ]; then cp "$GH_SUMS" "$2"; fi
		shift
	done
	exit 0
fi
if [ "$1 $2" = "release view" ]; then
	# No tag: the latest release.
	if [ "$3" = "--json" ]; then
		if [ "$GH_LATEST" = "broken" ]; then
			echo "HTTP 502: Bad Gateway" >&2
			exit 1
		fi
		if [ -z "$GH_LATEST" ]; then
			echo "release not found" >&2
			exit 1
		fi
		echo "$GH_LATEST"
		exit 0
	fi
	if [ "$GH_STATE" = "none" ]; then
		echo "release not found" >&2
		exit 1
	fi
	if [ "$GH_STATE" = "broken" ]; then
		echo "HTTP 502: Bad Gateway" >&2
		exit 1
	fi
	case "$*" in
	*isDraft*) if [ "$GH_STATE" = "draft" ]; then echo true; else echo false; fi ;;
	*assets*) cat "$GH_ASSETS" ;;
	*body*) echo "$GH_NOTES" ;;
	esac
fi
exit 0
EOF
chmod +x "$work/bin/gh"
export PATH="$work/bin:$PATH" GH_LOG="$work/gh.log" GH_ASSETS="$work/assets"

failed=0
check() {
	if [ "$2" = "$3" ]; then
		echo "ok   $1"
	else
		echo "FAIL $1"
		echo "     expected: $3"
		echo "     got:      $2"
		failed=1
	fi
}

# A dist folder holding the named assets, and a release state for gh.
setup() {
	GH_STATE=$1
	export GH_STATE GH_NOTES="Publishing." GH_LATEST=""
	shift
	rm -rf "$work/dist" "$GH_LOG"
	: > "$GH_ASSETS"
	: > "$GH_LOG"
	mkdir "$work/dist"
	for name in "$@"; do : > "$work/dist/$name"; done
}

all=$(bash "$build/release-assets.sh" 1.0.0)
# shellcheck disable=SC2206
everything=($all)
no_mac=()
for name in "${everything[@]}"; do
	case "$name" in Remnants-darwin-*) ;; *) no_mac+=("$name") ;; esac
done
mac_only=()
for name in "${everything[@]}"; do
	case "$name" in Remnants-darwin-*) mac_only+=("$name") ;; esac
done

publish() {
	status=0
	bash "$build/publish-release.sh" 1.0.0 "$work/dist" abc123 > "$work/out" 2>&1 || status=$?
}
calls() { grep -E "^release (create|upload|edit)" "$GH_LOG" | sed -E "s| $work/dist/[^ ]+||g" | tr '\n' ';' || true; }

# publish-release.sh: it only ever makes or fills a draft.
setup none "${everything[@]}"
publish
check "a complete new release is created as a draft" "$status $(calls)" \
	"0 release create v1.0.0 --title Remnants v1.0.0 --notes Publishing. --target abc123 --draft;"

setup none "${no_mac[@]}"
publish
check "a new release without macOS is created as a draft" "$status $(calls)" \
	"0 release create v1.0.0 --title Remnants v1.0.0 --notes Publishing. --target abc123 --draft;"

setup draft "${mac_only[@]}"
printf '%s\n' "${no_mac[@]}" SHA256SUMS > "$GH_ASSETS"
publish
check "the run that completes a draft uploads and publishes nothing" "$status $(calls)" \
	"0 release upload v1.0.0 --clobber;"

setup published "${mac_only[@]}"
printf '%s\n' "${no_mac[@]}" SHA256SUMS > "$GH_ASSETS"
publish
check "a run over a published release stops and uploads nothing" "$status $(calls)" "1 "

# finalize-release.sh: the draft goes public last, and takes "latest" only from
# an older release.
finish() {
	status=0
	bash "$build/finalize-release.sh" "${2:-1.0.0}" "$1" "${3:-def456}" > "$work/out" 2>&1 || status=$?
}
# A draft of version $2 as the run leaves it before the last step - every
# platform, notes, SHA256SUMS - with $1 as the latest release.
ready() {
	setup draft
	{ bash "$build/release-assets.sh" "${2:-1.0.0}"; echo SHA256SUMS; } > "$GH_ASSETS"
	export GH_NOTES="## Downloads" GH_LATEST=$1
}

ready ""
finish false
check "the first release is published as the latest" "$status $(calls)" \
	"0 release edit v1.0.0 --draft=false --latest --target def456;"

ready v0.9.9
finish false
check "a release above the latest one is published as the latest" "$status $(calls)" \
	"0 release edit v1.0.0 --draft=false --latest --target def456;"

ready v1.0.1
finish false
check "an older draft is published without taking latest back" "$status $(calls)" \
	"0 release edit v1.0.0 --draft=false --latest=false --target def456;"

ready v1.9.0 1.10.0
finish false 1.10.0
check "1.10.0 is above 1.9.0" "$status $(calls)" \
	"0 release edit v1.10.0 --draft=false --latest --target def456;"

ready v1.10.0 1.9.0
finish false 1.9.0
check "1.9.0 is not above 1.10.0" "$status $(calls)" \
	"0 release edit v1.9.0 --draft=false --latest=false --target def456;"

ready v0.9.9
finish false 1.0.0 abc789
check "a release is published with its tag on the commit this run built" "$status $(calls)" \
	"0 release edit v1.0.0 --draft=false --latest --target abc789;"

ready v0.9.9
finish true
check "a complete draft stays a draft when the draft input asks for one" "$status $(calls)" "0 "

ready v0.9.9
printf '%s\n' "${no_mac[@]}" SHA256SUMS > "$GH_ASSETS"
finish false
check "a draft still missing platforms stays a draft" "$status $(calls)" "0 "

ready v0.9.9
printf '%s\n' "${everything[@]}" > "$GH_ASSETS"
finish false
check "a draft without SHA256SUMS stops and stays a draft" "$status $(calls)" "1 "

ready v0.9.9
export GH_NOTES="Publishing."
finish false
check "a draft without its notes stops and stays a draft" "$status $(calls)" "1 "

ready broken
finish false
check "an unreadable latest release stops and the draft stays" "$status $(calls)" "1 "

ready nightly
finish false
check "a latest release that is no version stops and the draft stays" "$status $(calls)" "1 "

ready v0.9.9
export GH_STATE=broken
finish false
check "an unreadable draft stops and nothing is published" "$status $(calls)" "1 "

ready v0.9.9
export GH_STATE=published
finish false
check "a published release is left alone" "$status $(calls)" "0 "

# release.yml: draft first, then notes and checksums, publishing last.
steps=$(grep -oE 'build/publish-release\.sh|release edit "\$tag" --notes-file|release upload "\$tag" SHA256SUMS|build/finalize-release\.sh' \
	"$build/../.github/workflows/release.yml" | tr '\n' ';')
check "the workflow publishes after the notes and SHA256SUMS" "$steps" \
	'build/publish-release.sh;release edit "$tag" --notes-file;release upload "$tag" SHA256SUMS;build/finalize-release.sh;'

# check-release-version.sh: no run over a published version, no suffix.
version_check() {
	GH_STATE=$3
	export GH_STATE
	if bash "$build/check-release-version.sh" "$1" "$2" > /dev/null 2>&1; then echo pass; else echo stop; fi
}
check "a full run over a published version stops" "$(version_check 1.0.0 all published)" stop
check "a full run over a new version goes ahead" "$(version_check 1.0.1 all none)" pass
check "a full run over a draft goes ahead" "$(version_check 1.0.0 all draft)" pass
check "a one-platform run over a published version stops" "$(version_check 1.0.0 linux published)" stop
check "a one-platform run over a draft goes ahead" "$(version_check 1.0.0 linux draft)" pass
check "a version with a suffix stops" "$(version_check 1.0.0-remnants.1 all none)" stop
check "an unreadable release stops" "$(version_check 1.0.0 all broken)" stop

# stable-names.sh: one unversioned copy of every versioned asset.
setup none "${everything[@]}"
bash "$build/stable-names.sh" 1.0.0 "$work/dist" > /dev/null
copies=$(cd "$work/dist" && ls -1 | grep -vxF -f <(printf '%s
' "${everything[@]}") | sort | tr '
' ' ')
check "every versioned asset gets a copy without the version" "$copies" 	"Remnants-darwin-arm64.dmg Remnants-darwin-arm64.zip Remnants-darwin-x64.dmg Remnants-darwin-x64.zip Remnants-linux-arm64.tar.gz Remnants-linux-x64.tar.gz Remnants-win32-arm64.zip Remnants-win32-x64.zip remnants-aarch64.rpm remnants-amd64.deb remnants-arm64.deb remnants-x86_64.rpm "
before=$(ls -1 "$work/dist" | wc -l)
bash "$build/stable-names.sh" 1.0.0 "$work/dist" > /dev/null
check "a second run changes nothing" "$(ls -1 "$work/dist" | wc -l)" "$before"
echo other > "$work/dist/remnants-amd64.deb"
if bash "$build/stable-names.sh" 1.0.0 "$work/dist" > /dev/null 2>&1; then result=pass; else result=stop; fi
check "a copy name already taken by other bytes stops" "$result" stop

# render-pkgbuild.sh: an architecture this run did not build keeps its checksum
# from the release's SHA256SUMS, so a partial re-run cannot drop it.
empty=$(sha256sum < /dev/null | cut -d' ' -f1)
older=1111111111111111111111111111111111111111111111111111111111111111
render() {
	rm -f "$work/sums"
	if [ $# -gt 0 ]; then printf '%s\n' "$@" > "$work/sums"; fi
	export GH_SUMS="$work/sums"
	status=0
	bash "$build/linux/render-pkgbuild.sh" 1.0.0 "$work/dist" > "$work/out" 2>&1 || status=$?
}
pkgbuild() {
	if [ -f "$work/dist/PKGBUILD" ]; then
		grep -E '^(arch|sha256sums_[a-z0-9_]+)=' "$work/dist/PKGBUILD" | tr '\n' ';'
	else
		echo none
	fi
}

setup draft Remnants-linux-x64-1.0.0.tar.gz Remnants-linux-arm64-1.0.0.tar.gz
render "$older  Remnants-linux-x64-1.0.0.tar.gz" "$older  Remnants-linux-arm64-1.0.0.tar.gz"
check "a PKGBUILD for both built tarballs uses this run's checksums" "$status $(pkgbuild)" \
	"0 arch=('x86_64' 'aarch64');sha256sums_x86_64=('$empty');sha256sums_aarch64=('$empty');"

setup draft Remnants-linux-x64-1.0.0.tar.gz
render "$older  Remnants-linux-arm64-1.0.0.tar.gz" "$older  Remnants-linux-arm64.tar.gz"
check "a PKGBUILD from an x64-only re-run keeps arm64 from the release" "$status $(pkgbuild)" \
	"0 arch=('x86_64' 'aarch64');sha256sums_x86_64=('$empty');sha256sums_aarch64=('$older');"

setup draft Remnants-linux-arm64-1.0.0.tar.gz
render "$older  Remnants-linux-x64-1.0.0.tar.gz"
check "a PKGBUILD from an arm64-only re-run keeps x64 from the release" "$status $(pkgbuild)" \
	"0 arch=('x86_64' 'aarch64');sha256sums_x86_64=('$older');sha256sums_aarch64=('$empty');"

setup draft Remnants-linux-x64-1.0.0.tar.gz
render "$older  Remnants-linux-x64.tar.gz" "$older  Remnants-linux-arm64-0.9.9.tar.gz"
check "a PKGBUILD takes no checksum for another name or version" "$status $(pkgbuild)" \
	"0 arch=('x86_64');sha256sums_x86_64=('$empty');"

setup none Remnants-linux-x64-1.0.0.tar.gz
render
check "a PKGBUILD for a new release covers what this run built" "$status $(pkgbuild)" \
	"0 arch=('x86_64');sha256sums_x86_64=('$empty');"

setup draft "${mac_only[@]}"
render "$older  Remnants-linux-x64-1.0.0.tar.gz" "$older  Remnants-linux-arm64-1.0.0.tar.gz"
check "a run without Linux writes no PKGBUILD over the release's one" "$status $(pkgbuild)" "0 none"

# release-notes.sh documents exactly the files release-assets.sh names.
printf '%s\n' "${everything[@]}" > "$work/list"
noted=$(bash "$build/release-notes.sh" 1.0.0 "$work/list" | grep -oE '`[^`]+`' | tr -d '`' |
	grep -E '^(PKGBUILD|[Rr]emnants[^ /]*\.(exe|zip|dmg|deb|rpm|tar\.gz))$' | sort -u | tr '\n' ' ')
check "the release notes name every asset and no other file" "$noted" "$(printf '%s\n' "${everything[@]}" | sort -u | tr '\n' ' ')"

# site.yml: a change to a file outside site/ that the site tests read starts the site job.
norm() {
	local IFS=/ part out=()
	for part in $1; do
		case $part in
		'' | .) ;;
		..) if [ ${#out[@]} -gt 0 ]; then unset 'out[-1]'; fi ;;
		*) out+=("$part") ;;
		esac
	done
	echo "${out[*]}"
}

# Paths one script in the folder $1 (relative to the repo root) reads: new URL() from import.meta.url
# or from a name set to one, join() of such a name with string parts, and a plain relative path,
# which the site job reads from its working directory, site/test.
file_reads() {
	local dir=$1 f=$2 name rel call path arg
	local -A at=()
	while IFS=$'\t' read -r name rel; do
		at[$name]=$(norm "$dir/$rel")
	done < <(grep -oE "(const|let|var) +[A-Za-z_\$][A-Za-z0-9_\$]* *= *(fileURLToPath\()?new URL\([\"'][^\"']*[\"'], *import\.meta\.url\)" "$f" |
		sed -E "s/^(const|let|var) +([^ =]+) *= *(fileURLToPath\()?new URL\([\"']([^\"']*)[\"'].*/\2\t\4/" || true)
	while read -r rel; do
		norm "$dir/$rel"
	done < <(grep -oE "new URL\([\"'][^\"']*[\"'], *import\.meta\.url\)" "$f" | sed -E "s/^new URL\([\"']([^\"']*)[\"'].*/\1/" || true)
	while IFS=$'\t' read -r name rel; do
		if [ -n "${at[$name]-}" ]; then norm "${at[$name]}/$rel"; fi
	done < <(grep -oE "new URL\([\"'][^\"']*[\"'], *[A-Za-z_\$][A-Za-z0-9_\$]*\)" "$f" |
		sed -E "s/^new URL\([\"']([^\"']*)[\"'], *([^)]*)\)/\2\t\1/" || true)
	while read -r call; do
		name=$(sed -E 's/^join\(([^,]*),.*/\1/' <<< "$call")
		if [ -z "${at[$name]-}" ]; then continue; fi
		path=${at[$name]}
		while read -r arg; do path+="/$arg"; done < <(grep -oE "[\"'][^\"']*[\"']" <<< "${call#*,}" | tr -d "\"'")
		norm "$path"
	done < <(grep -oE "join\([A-Za-z_\$][A-Za-z0-9_\$]*(, *[\"'][^\"']*[\"'])+\)" "$f" || true)
	while read -r rel; do
		norm "site/test/$rel"
	done < <(grep -oE "(readFileSync|existsSync|statSync|readdirSync|createReadStream)\([\"']\.\.?/[^\"']*[\"']" "$f" |
		sed -E "s/^[^(]*\([\"']([^\"']*)[\"']/\1/" || true)
	return 0
}

# Every path outside site/ that a script in the folder $2 under the repo root $1 reads, one per line.
site_reads() {
	local f
	for f in "$1/$2"/*.mjs "$1/$2"/*.js; do
		if [ -f "$f" ]; then file_reads "$2" "$f"; fi
	done | { grep -vE '^site(/|$)' || true; } | sort -u
}

# The paths list of one event in a workflow file.
event_paths() {
	sed -n "/^  $2:/,/^  [a-z_]*:/p" "$1" | grep -m1 'paths:' | grep -oE "'[^']*'|\"[^\"]*\"" | tr -d "'\"" || true
}

# Whether the path $1 is in the list that follows, by name or under a dir/** entry.
covered() {
	local file=$1 item
	shift
	for item in "$@"; do
		case $item in
		*'/**') if [[ $file == "${item%'/**'}"/* ]]; then return 0; fi ;;
		*) if [ "$file" = "$item" ]; then return 0; fi ;;
		esac
	done
	return 1
}

mkdir -p "$work/tree/site/test"
cat > "$work/tree/site/test/a.spec.mjs" <<'EOF'
const site = new URL("../", import.meta.url);
const here = fileURLToPath(new URL(".", import.meta.url));
readFileSync(new URL("../../build/x.sh", import.meta.url));
readFileSync(new URL("page.json", site));
readFileSync(new URL('../README.md', site));
readdirSync(join(here, "..", "diag", "vendor"));
readFileSync(join(here, "..", "..", "build", "y.sh"));
readFileSync("../../z.json");
readFileSync(join(here, name));
EOF
check "the scan finds what a site test reads outside site/" "$(site_reads "$work/tree" site/test | tr '\n' ' ')" \
	"README.md build/x.sh build/y.sh z.json "
check "a dir/** entry covers the files under it, and only those" \
	"$(covered site/a.html 'site/**' && echo in) $(covered siteb/a.html 'site/**' || echo out)" "in out"

root=$(cd "$build/.." && pwd)
site_yml="$root/.github/workflows/site.yml"
reads=$(site_reads "$root" site/test)
mapfile -t on_push < <(event_paths "$site_yml" push)
mapfile -t on_pr < <(event_paths "$site_yml" pull_request)
missing=""
for file in $reads; do
	covered "$file" "${on_push[@]}" || missing+="push:$file "
	covered "$file" "${on_pr[@]}" || missing+="pull_request:$file "
done
check "the scan finds the files outside site/ that the site tests read" "$(if [ -n "$reads" ]; then echo some; else echo none; fi)" some
check "every file outside site/ that the site tests read starts the site job" "$missing" ""

exit "$failed"
