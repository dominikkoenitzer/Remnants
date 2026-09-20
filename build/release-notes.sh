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

# Bullet for a secondary download format.
alt() {
	if has "$2"; then
		printf -- '- `%s` - %s\n' "$2" "$1"
	fi
}

win_user_x64="RemnantsUserSetup-x64.exe"
win_user_arm64="RemnantsUserSetup-arm64.exe"
win_sys_x64="RemnantsSetup-x64.exe"
win_sys_arm64="RemnantsSetup-arm64.exe"
win_zip_x64="Remnants-win32-x64-$version.zip"
win_zip_arm64="Remnants-win32-arm64-$version.zip"
mac_dmg_arm64="Remnants-darwin-arm64-$version.dmg"
mac_dmg_x64="Remnants-darwin-x64-$version.dmg"
mac_zip_arm64="Remnants-darwin-arm64-$version.zip"
mac_zip_x64="Remnants-darwin-x64-$version.zip"
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
row "Windows x64" "$win_user_x64"
row "Windows arm64" "$win_user_arm64"
row "macOS Apple silicon" "$mac_dmg_arm64"
row "macOS Intel" "$mac_dmg_x64"
row "Debian, Ubuntu x64" "$deb_x64"
row "Debian, Ubuntu arm64" "$deb_arm64"
row "Fedora, RHEL, openSUSE x64" "$rpm_x64"
row "Fedora, RHEL, openSUSE arm64" "$rpm_arm64"
row "Any Linux x64" "$tar_x64"
row "Any Linux arm64" "$tar_arm64"
row "Arch Linux" "PKGBUILD"
echo

if has "$win_sys_x64" || has "$win_sys_arm64" || has "$win_zip_x64" || has "$win_zip_arm64" ||
	has "$mac_zip_arm64" || has "$mac_zip_x64"; then
	echo "Other formats:"
	echo
	alt "Windows machine-wide installer, needs administrator rights" "$win_sys_x64"
	alt "Windows machine-wide installer, needs administrator rights" "$win_sys_arm64"
	alt "Windows without an installer: unzip it and run Remnants.exe" "$win_zip_x64"
	alt "Windows without an installer: unzip it and run Remnants.exe" "$win_zip_arm64"
	alt "macOS app bundle as a zip instead of a disk image" "$mac_zip_arm64"
	alt "macOS app bundle as a zip instead of a disk image" "$mac_zip_x64"
	echo
fi

if has "$win_user_x64" || has "$win_user_arm64"; then
	cat <<-EOF
		## Windows

		Run the installer for your architecture; arm64 is for Snapdragon and Surface ARM
		machines. The user installer needs no administrator rights and installs into your
		profile. Remnants is not code-signed, so SmartScreen may warn "Windows protected
		your PC": click **More info -> Run anyway**.

	EOF
fi

if has "$mac_dmg_arm64" || has "$mac_dmg_x64" || has "$mac_zip_arm64" || has "$mac_zip_x64"; then
	cat <<-EOF
		## macOS

		Open the disk image and drag **Remnants** onto the Applications shortcut. The
		build is ad-hoc signed but not notarized, so clear the download quarantine once
		before the first launch:

		\`\`\`sh
		xattr -dr com.apple.quarantine /Applications/Remnants.app
		\`\`\`

		Without that, macOS claims the app "is damaged". It is not: that message means
		unnotarized.

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
		sudo apt install ./$deb_x64      # Debian, Ubuntu
		sudo dnf install ./$rpm_x64      # Fedora, RHEL
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
	## Requirements

	Windows 10 or later, macOS 12 Monterey or later, or a Linux with glibc 2.34 or
	newer (Ubuntu 22.04+, Debian 12+, Fedora 35+, RHEL 9+). x64 and arm64 on all
	three.

	## Wayland

	The Linux desktop entry launches with \`--ozone-platform-hint=auto\`, so Remnants
	runs natively on Wayland (Hyprland, Sway, GNOME, KDE) and falls back to X11
	elsewhere. Pass \`--ozone-platform-hint=x11\` to force XWayland.

	## Verifying downloads

	\`SHA256SUMS\` lists the checksum of every asset here:

	\`\`\`sh
	sha256sum -c SHA256SUMS --ignore-missing
	\`\`\`

	Every asset also carries a signed provenance attestation, which proves it was
	built by the release workflow in this repository and not rebuilt or swapped
	afterwards:

	\`\`\`sh
	gh attestation verify <file> -R dominikkoenitzer/Remnants
	\`\`\`

	## How this build was checked

	Nothing here is code-signed, so the workflow installs and runs what it is about
	to publish: the Windows installer silently on x64 and on real ARM hardware, the
	archive unpacked, the deb on Debian, the rpm on Fedora, the tarball on Ubuntu,
	and the macOS app from both the zip and the mounted disk image. The Linux build
	is additionally started on a virtual display, so the window is known to come up.
EOF
