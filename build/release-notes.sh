#!/usr/bin/env bash
#
# Print the GitHub release notes for a release, covering only the assets that
# actually built.
#
#   build/release-notes.sh <version> <distdir>
set -euo pipefail

version=${1:?usage: release-notes.sh <version> <distdir>}
dist=${2:?usage: release-notes.sh <version> <distdir>}

has() { [ -f "$dist/$1" ]; }

echo "AI-free build of Code - OSS $version. Nothing here signs in, phones home, or ships a chat panel."
echo
echo "## Install"
echo

if has RemnantsUserSetup.exe; then
	cat <<-EOF
		**Windows (x64)** - download \`RemnantsUserSetup.exe\` and run it. It is a per-user
		installer, so no administrator rights are needed. Remnants is not code-signed, so
		SmartScreen may warn "Windows protected your PC": click **More info -> Run anyway**.

	EOF
fi

if has "Remnants-darwin-arm64-$version.zip" || has "Remnants-darwin-x64-$version.zip"; then
	cat <<-EOF
		**macOS** - download \`Remnants-darwin-arm64-$version.zip\` for Apple silicon or
		\`Remnants-darwin-x64-$version.zip\` for Intel, unzip it, and move \`Remnants.app\`
		to \`/Applications\`. The build is ad-hoc signed but not notarized, so clear the
		download quarantine once before the first launch:

		\`\`\`sh
		xattr -dr com.apple.quarantine /Applications/Remnants.app
		\`\`\`

	EOF
fi

if has "Remnants-linux-x64-$version.tar.gz" || has "Remnants-linux-arm64-$version.tar.gz"; then
	cat <<-EOF
		**Linux** - download \`Remnants-linux-x64-$version.tar.gz\` (or \`-arm64-\`), then:

		\`\`\`sh
		tar -xzf Remnants-linux-x64-$version.tar.gz
		cd Remnants-linux-x64
		sudo ./install.sh          # or ./install.sh --user for a rootless install
		\`\`\`

		That installs the app, the \`remnants\` command, the desktop entry and the icon.
		\`sudo /opt/remnants/uninstall.sh\` removes it again.

	EOF
fi

if has PKGBUILD; then
	cat <<-EOF
		**Arch Linux** - download \`PKGBUILD\` into an empty directory and let pacman own
		the install:

		\`\`\`sh
		makepkg -si
		\`\`\`

	EOF
fi

cat <<-EOF
	## Wayland

	The Linux desktop entry launches with \`--ozone-platform-hint=auto\`, so Remnants
	runs natively on Wayland (Hyprland, Sway, GNOME, KDE) and falls back to X11
	elsewhere. Pass \`--ozone-platform-hint=x11\` to force XWayland.

	## Verifying downloads

	\`SHA256SUMS\` lists the checksum of every asset here:

	\`\`\`sh
	sha256sum -c SHA256SUMS --ignore-missing
	\`\`\`
EOF
