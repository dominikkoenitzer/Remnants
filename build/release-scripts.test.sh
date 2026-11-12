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
# release's assets; every call is appended to $GH_LOG.
echo "$*" >> "$GH_LOG"
if [ "$1 $2" = "release view" ]; then
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
	export GH_STATE
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
	bash "$build/publish-release.sh" 1.0.0 "$work/dist" "$1" abc123 > "$work/out" 2>&1
}
calls() { grep -E "^release (create|upload|edit)" "$GH_LOG" | sed -E "s| $work/dist/[^ ]+||g" | tr '\n' ';' || true; }

# publish-release.sh: a new release becomes the latest only with every platform.
setup none "${everything[@]}"
publish false
check "a complete new release is published" "$(calls)" \
	"release create v1.0.0 --title Remnants v1.0.0 --notes Publishing. --target abc123;"

setup none "${no_mac[@]}"
publish false
check "a new release without macOS is created as a draft" "$(calls)" \
	"release create v1.0.0 --title Remnants v1.0.0 --notes Publishing. --target abc123 --draft;"

setup none "${everything[@]}"
publish true
check "the draft input still makes a draft" "$(calls)" \
	"release create v1.0.0 --title Remnants v1.0.0 --notes Publishing. --target abc123 --draft;"

setup draft "${mac_only[@]}"
printf '%s\n' "${no_mac[@]}" SHA256SUMS > "$GH_ASSETS"
publish false
check "the run that completes a draft publishes it as the latest" "$(calls)" \
	"release upload v1.0.0 --clobber;release edit v1.0.0 --draft=false --latest;"

setup draft "${mac_only[@]}"
printf '%s\n' "${no_mac[@]}" SHA256SUMS > "$GH_ASSETS"
publish true
check "a completed draft stays a draft when the draft input asks for one" "$(calls)" \
	"release upload v1.0.0 --clobber;"

setup draft "${mac_only[@]}"
publish false
check "a draft still missing platforms stays a draft" "$(calls)" \
	"release upload v1.0.0 --clobber;"

setup published "${mac_only[@]}"
printf '%s\n' "${no_mac[@]}" SHA256SUMS > "$GH_ASSETS"
publish false
check "a published release only gets its assets replaced" "$(calls)" \
	"release upload v1.0.0 --clobber;"

# check-release-version.sh: no full run over a published version, no suffix.
version_check() {
	GH_STATE=$3
	export GH_STATE
	if bash "$build/check-release-version.sh" "$1" "$2" > /dev/null 2>&1; then echo pass; else echo stop; fi
}
check "a full run over a published version stops" "$(version_check 1.0.0 all published)" stop
check "a full run over a new version goes ahead" "$(version_check 1.0.1 all none)" pass
check "a full run over a draft goes ahead" "$(version_check 1.0.0 all draft)" pass
check "a one-platform run over a published version goes ahead" "$(version_check 1.0.0 linux published)" pass
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

# release-notes.sh documents exactly the files release-assets.sh names.
printf '%s\n' "${everything[@]}" > "$work/list"
noted=$(bash "$build/release-notes.sh" 1.0.0 "$work/list" | grep -oE '`[^`]+`' | tr -d '`' |
	grep -E '^(PKGBUILD|[Rr]emnants[^ /]*\.(exe|zip|dmg|deb|rpm|tar\.gz))$' | sort -u | tr '\n' ' ')
check "the release notes name every asset and no other file" "$noted" "$(printf '%s\n' "${everything[@]}" | sort -u | tr '\n' ' ')"

exit "$failed"
