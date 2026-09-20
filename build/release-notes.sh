#!/usr/bin/env bash
#
# Print the GitHub release notes for a release, covering only the assets the
# release actually has.
#
#   build/release-notes.sh <version> <asset-list>
#
# <asset-list> is a file with one asset file name per line, as published on the
# release, so a re-run that rebuilds a single platform still documents all of
# them.
set -euo pipefail

version=${1:?usage: release-notes.sh <version> <asset-list>}
assets=${2:?usage: release-notes.sh <version> <asset-list>}

has() { grep -qxF "$1" "$assets"; }

# Table row for an asset, skipped when the asset is not part of the release.
row() {
	if has "$2"; then
		printf '| %s | `%s` |\n' "$1" "$2"
	fi
}

win_x64="RemnantsUserSetup-x64.exe"
win_arm64="RemnantsUserSetup-arm64.exe"
mac_arm64="Remnants-darwin-arm64-$version.zip"
mac_x64="Remnants-darwin-x64-$version.zip"
deb_x64="remnants-$version-amd64.deb"
deb_arm64="remnants-$version-arm64.deb"
rpm_x64="remnants-$version-x86_64.rpm"
rpm_arm64="remnants-$version-aarch64.rpm"
tar_x64="Remnants-linux-x64-$version.tar.gz"
tar_arm64="Remnants-linux-arm64-$version.tar.gz"

echo "AI-free build of Code - OSS $version. Nothing here signs in, phones home, or ships a chat panel."
echo
echo "## Downloads"
echo
echo "| Platform | File |"
echo "| --- | --- |"
row "Windows x64" "$win_x64"
row "Windows arm64" "$win_arm64"
row "macOS Apple silicon" "$mac_arm64"
row "macOS Intel" "$mac_x64"
row "Debian, Ubuntu x64" "$deb_x64"
row "Debian, Ubuntu arm64" "$deb_arm64"
row "Fedora, RHEL, openSUSE x64" "$rpm_x64"
row "Fedora, RHEL, openSUSE arm64" "$rpm_arm64"
row "Any Linux x64" "$tar_x64"
row "Any Linux arm64" "$tar_arm64"
row "Arch Linux" "PKGBUILD"
echo

if has "$win_x64" || has "$win_arm64"; then
	cat <<-EOF
		## Windows

		Run the installer for your architecture. Both are per-user installers, so no
		administrator rights are needed. Remnants is not code-signed, so SmartScreen may
		warn "Windows protected your PC": click **More info -> Run anyway**.

	EOF
fi

if has "$mac_arm64" || has "$mac_x64"; then
	cat <<-EOF
		## macOS

		Unzip the download and move \`Remnants.app\` to \`/Applications\`. The build is
		ad-hoc signed but not notarized, so clear the download quarantine once before the
		first launch:

		\`\`\`sh
		xattr -dr com.apple.quarantine /Applications/Remnants.app
		\`\`\`

	EOF
fi

if has "$deb_x64" || has "$deb_arm64" || has "$rpm_x64" || has "$rpm_arm64"; then
	cat <<-EOF
		## Debian, Ubuntu, Fedora, RHEL, openSUSE

		Install the package for your distro and architecture. It installs the app, the
		\`remnants\` command, the desktop entry, the icon and the shell completions, and
		\`apt remove remnants\` or \`dnf remove remnants\` takes it all back out. The
		packages set up no repository and no update channel, so new versions come from
		this releases page.

		\`\`\`sh
		sudo apt install ./$deb_x64   # Debian, Ubuntu
		sudo dnf install ./$rpm_x64   # Fedora, RHEL
		sudo zypper install ./$rpm_x64   # openSUSE
		\`\`\`

	EOF
fi

if has "$tar_x64" || has "$tar_arm64"; then
	cat <<-EOF
		## Any other Linux

		The tarball runs on every distro and needs no package manager:

		\`\`\`sh
		tar -xzf $tar_x64
		cd Remnants-linux-x64
		sudo ./install.sh          # or ./install.sh --user for a rootless install
		\`\`\`

		\`sudo /opt/remnants/uninstall.sh\` removes it again.

	EOF
fi

if has PKGBUILD; then
	cat <<-EOF
		## Arch Linux

		Download \`PKGBUILD\` into an empty directory and let pacman own the install:

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
