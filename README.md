# Remnants

Remnants is a code editor built from Code - OSS, the open-source core of VS Code, with every built-in AI feature and all telemetry removed.

[![CI](https://github.com/dominikkoenitzer/Remnants/actions/workflows/ci.yml/badge.svg)](https://github.com/dominikkoenitzer/Remnants/actions/workflows/ci.yml)

## Download

**[Download Remnants for Windows](https://github.com/dominikkoenitzer/Remnants/releases/latest/download/RemnantsUserSetup-x64.exe)**, then double-click it and follow the setup.
Windows may say "Windows protected your PC"; click More info, then Run anyway.

For an ARM PC, macOS or Linux, see [Other ways to install](#other-ways-to-install).

## What it does

| Area | In Remnants |
| --- | --- |
| Code editing, multi-cursor, IntelliSense, refactoring | Kept |
| Integrated terminal and tasks | Kept |
| Source control (Git, GitHub sign-in) | Kept |
| Debugging (JavaScript and Node via `js-debug`) | Kept |
| Themes, keybindings, settings, profiles | Kept |
| Extensions | Installed from [Open VSX](https://open-vsx.org) |
| Built-in AI: chat panel, agent sessions, voice, the bundled AI extension | Removed |
| Sign-in prompts in the title bar and status bar | Removed |
| Telemetry and crash reporting | Off |

By default the activity bar is hidden and the status bar switches the side bar
views, the terminal and settings instead; on Windows and Linux the menu bar
appears when you press Alt. These are ordinary default settings, so any value
you set wins.

Keybindings are the standard VS Code ones. `Ctrl+Shift+P` (`Shift+Cmd+P` on
macOS) opens the Command Palette, and `Ctrl+K Ctrl+S` (`Cmd+K Cmd+S`) lists every
shortcut.

> [!NOTE]
> Almost all of the code here is Microsoft's. Remnants is derived from upstream
> commit [`93cfdd48`](https://github.com/microsoft/vscode/commit/93cfdd489c3b228840d0f86ec77c3636277c93ea)
> (release 1.125.0); my own contribution is roughly −759,000 / +2,800 lines on
> top of it. [CHANGES.md](CHANGES.md) documents exactly what I changed and how to
> verify it.

## Other ways to install

Every asset is built by the [release workflow](.github/workflows/release.yml) on
GitHub Actions and attached to the [latest release](https://github.com/dominikkoenitzer/Remnants/releases/latest).

| Platform | Asset | Install with |
| --- | --- | --- |
| Windows x64 | [`RemnantsUserSetup-x64.exe`](https://github.com/dominikkoenitzer/Remnants/releases/latest/download/RemnantsUserSetup-x64.exe) | run it (per-user, no admin) |
| Windows arm64 | [`RemnantsUserSetup-arm64.exe`](https://github.com/dominikkoenitzer/Remnants/releases/latest/download/RemnantsUserSetup-arm64.exe) | run it (per-user, no admin) |
| macOS (Apple silicon) | `Remnants-darwin-arm64-<version>.dmg` | open, drag to Applications |
| macOS (Intel) | `Remnants-darwin-x64-<version>.dmg` | open, drag to Applications |
| Debian, Ubuntu x64 / arm64 | `remnants-<version>-<amd64,arm64>.deb` | `sudo apt install ./<file>` |
| Fedora, RHEL, openSUSE x64 / arm64 | `remnants-<version>-<x86_64,aarch64>.rpm` | `sudo dnf install ./<file>` |
| Any Linux x64 / arm64 | `Remnants-linux-<arch>-<version>.tar.gz` | `sudo ./install.sh` |
| Arch Linux | [`PKGBUILD`](https://github.com/dominikkoenitzer/Remnants/releases/latest/download/PKGBUILD) | `makepkg -si` |

Each release also carries a machine-wide Windows installer
([x64](https://github.com/dominikkoenitzer/Remnants/releases/latest/download/RemnantsSetup-x64.exe), [arm64](https://github.com/dominikkoenitzer/Remnants/releases/latest/download/RemnantsSetup-arm64.exe)), a Windows archive for machines where no installer
may run (`Remnants-win32-<arch>-<version>.zip`) and the macOS app as a plain zip.

It runs on:

| Platform | Needs |
| --- | --- |
| Windows | 10 or later, x64 or arm64 |
| macOS | 12 Monterey or later, Apple silicon or Intel |
| Linux | glibc 2.34 or newer, x64 or arm64: Ubuntu 22.04+, Debian 12+, Fedora 35+, RHEL 9+ |

Remnants is not code-signed, so Windows and macOS ask you to confirm the first
launch once. On Windows, click More info, then Run anyway; on macOS, step 3
below says how.

### Windows (x64 and arm64)

On an ARM PC, take [`RemnantsUserSetup-arm64.exe`](https://github.com/dominikkoenitzer/Remnants/releases/latest/download/RemnantsUserSetup-arm64.exe)
instead of the x64 installer. To check which one you have, open Settings > System >
About: System type says x64-based or ARM-based processor.

Both installers put Remnants into your user profile (`%LOCALAPPDATA%\Programs\Remnants`),
so no administrator rights are needed, and add it to the Start menu. The
machine-wide `RemnantsSetup-<arch>.exe` installs into Program Files for every user
and asks for administrator rights.

### macOS (Apple silicon and Intel)

1. Download `Remnants-darwin-arm64-<version>.dmg` (Apple silicon, M1 and later)
   or `Remnants-darwin-x64-<version>.dmg` (Intel).
2. Open it and drag Remnants onto the Applications shortcut. (The same build
   is also published as a `.zip` if you prefer that.)
3. The build is ad-hoc signed but not notarized, so clear the download
   quarantine flag once:

   ```sh
   xattr -dr com.apple.quarantine /Applications/Remnants.app
   ```

   Without this, macOS reports that the app "is damaged and can't be opened".
   That message only means the app is not notarized.

To get the `remnants` command in your shell, run Shell Command: Install
'remnants' command in PATH from the Command Palette.

### Linux (x64 and arm64)

On Debian, Ubuntu, Fedora, RHEL or openSUSE, install the package for your distro
and let the package manager own it:

```sh
sudo apt install ./remnants-<version>-amd64.deb       # Debian, Ubuntu, Mint
sudo dnf install ./remnants-<version>-x86_64.rpm      # Fedora, RHEL
sudo zypper install ./remnants-<version>-x86_64.rpm   # openSUSE
```

Use the `arm64` / `aarch64` files on ARM hardware. Both packages install the app
to `/usr/share/remnants`, put `remnants` on your PATH, and register the desktop
entry, icon, MIME types and shell completions. Neither package adds a repository
or an update channel: new versions come from the releases page.

#### Any other distribution

The tarball works on any distribution: it carries the app plus a desktop entry,
icon, MIME types and shell completions.

```sh
tar -xzf Remnants-linux-x64-<version>.tar.gz
cd Remnants-linux-x64
sudo ./install.sh            # into /opt/remnants, plus a /usr/local/bin/remnants symlink
```

No root? `./install.sh --user` installs into `~/.local` instead. `./install.sh --help`
lists the options, and the installer prints the matching uninstall command when
it is done.

#### Arch Linux

Let pacman own the install instead. Download `PKGBUILD` from the release into an
empty directory:

```sh
makepkg -si
```

That builds the `remnants-bin` package from the published tarball, verifies its
checksum, and installs it to `/opt/remnants` with `/usr/bin/remnants` on your
PATH.

#### Wayland

Remnants uses Wayland natively. The desktop entry launches with
`--ozone-platform-hint=auto`, and the `remnants` shell command exports the
equivalent `ELECTRON_OZONE_PLATFORM_HINT=auto`, so it picks Wayland when
`WAYLAND_DISPLAY` is set and X11 otherwise. That matters most under fractional
scaling, where XWayland renders the whole window blurry.

To force XWayland instead, export `ELECTRON_OZONE_PLATFORM_HINT=x11`, or launch
with `remnants --ozone-platform-hint=x11`. For window rules, read the app ID from
your compositor while Remnants is open; Electron derives it from the desktop entry.

### Verify a download

Each release ships a [`SHA256SUMS`](https://github.com/dominikkoenitzer/Remnants/releases/latest/download/SHA256SUMS) file covering every asset:

```sh
sha256sum -c SHA256SUMS --ignore-missing
```

Every asset also carries a signed build provenance attestation. Nothing here is
code-signed, so this is how you prove a file came from the release workflow in
this repository and was not swapped afterwards:

```sh
gh attestation verify <file> -R dominikkoenitzer/Remnants
```

## Your data, updates and removal

### Where your data lives

| Platform | Settings, keybindings, profiles | Extensions |
| --- | --- | --- |
| Windows | `%APPDATA%\Remnants` | `%USERPROFILE%\.remnants\extensions` |
| macOS | `~/Library/Application Support/Remnants` | `~/.remnants/extensions` |
| Linux | `~/.config/Remnants` | `~/.remnants/extensions` |

Uninstalling never touches these folders.

### Updates

Remnants never updates itself. To update, install the new release the same way
as the first one; your settings and extensions live outside the app and stay.

Turn on the `remnants.checkForUpdates` setting and Remnants asks its download
site, which forwards to GitHub, once a day for the latest release. When that is
newer than the running version, it shows a notification with a link to the
download page. Nothing is downloaded or installed. Otherwise new versions are
announced only on the releases page; Watch > Custom > Releases on the repository
turns that into an email.

### Removing it

| Installed with | Remove with |
| --- | --- |
| Windows installer | uninstall Remnants under Settings > Apps |
| macOS dmg or zip | move Remnants from Applications to the Trash |
| `.deb` | `sudo apt remove remnants` |
| `.rpm` | `sudo dnf remove remnants` or `sudo zypper remove remnants` |
| Tarball | `sudo /opt/remnants/uninstall.sh`, or `~/.local/lib/remnants/uninstall.sh --user` |
| Arch `PKGBUILD` | `sudo pacman -R remnants-bin` |

To remove everything, delete the data folders listed above as well.

## Build from source

Remnants builds with the same toolchain as Code - OSS. Use **Node.js 22**: the
committed `package-lock.json` is only in sync under npm 10's resolver, and npm 11
(bundled with Node 24) rejects `npm ci`. `.nvmrc` asks for Node 24, so set
`VSCODE_SKIP_NODE_VERSION_CHECK=1` to skip that check, as the release build does.

### Windows, step by step

Open PowerShell and paste one block at a time. Accept the administrator prompts.

1. Install Git, Node.js 22, Python 3.13 and the Visual Studio 2022 C++ build tools.
   The build tools are a few GB and take a while.

   ```powershell
   winget install --id Git.Git -e
   winget install --id OpenJS.NodeJS.22 -e
   winget install --id Python.Python.3.13 -e
   winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --includeRecommended"
   ```

   It has to be Visual Studio 2022: node-gyp here cannot use the newer Visual
   Studio 18 toolchain. The Spectre-mitigated libraries are not part of
   `--includeRecommended`, so they are added by name. To cross-build the arm64
   installer, also add the ARM64 C++ tools and their Spectre libraries.

2. Close PowerShell and open a new window, so the new tools are on your PATH. Then
   let PowerShell run npm's script wrapper (once per user):

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```

3. Get the source and check the tools:

   ```powershell
   cd $HOME
   git clone https://github.com/dominikkoenitzer/Remnants.git
   cd Remnants
   .\scripts\setup.ps1
   ```

   `setup.ps1` only checks. It prints the install command for anything still
   missing and installs nothing.

4. Install the dependencies:

   ```powershell
   $env:VSCODE_SKIP_NODE_VERSION_CHECK = "1"
   npm ci
   ```

5. Build and start it:

   ```powershell
   npm run transpile-client
   npm run build-fast-extensions
   .\scripts\code.bat
   ```

   The first start downloads Electron and the built-in extensions, then opens a
   window titled **Remnants Dev**.

`npm ci` and the first start download files from GitHub. If either stops with a
rate limit error (HTTP 403), set a token in the same window and run it again:
`$env:GITHUB_TOKEN = "<token>"`. A token without any scopes is enough. Create one
on GitHub under **Settings > Developer settings > Personal access tokens**, or use
`$env:GITHUB_TOKEN = gh auth token` if GitHub CLI is signed in.

`$env:` variables only last for the current window, so set them again in a new
one. For day-to-day work, keep `npm run watch` running in a second window and run
**Developer: Reload Window** in the dev build after a change.

### macOS and Linux

Install Node.js 22 and Python 3.13, plus:

| Platform | Also needs |
| --- | --- |
| macOS | Xcode Command Line Tools (`xcode-select --install`) |
| Linux | `libkrb5-dev libx11-dev libxkbfile-dev libsecret-1-dev` on Debian/Ubuntu; `krb5 libx11 libxkbfile libsecret` on Arch |

Then:

```sh
git clone https://github.com/dominikkoenitzer/Remnants.git
cd Remnants
export VSCODE_SKIP_NODE_VERSION_CHECK=1
npm ci
npm run transpile-client
npm run build-fast-extensions
./scripts/code.sh
```

### Produce the release artifacts

Each packaging task emits the app next to the repository, as `../VSCode-<platform>-<arch>`.

```sh
# Windows installer -> .build\win32-x64\user-setup\VSCodeSetup.exe
npm run gulp vscode-win32-x64
npm run gulp vscode-win32-x64-inno-updater
npm run gulp vscode-win32-x64-user-setup
# swap x64 for arm64 to cross-build the ARM installer on the same machine

# Linux tarball -> dist/Remnants-linux-x64-<version>.tar.gz
npm run gulp vscode-linux-x64
bash build/linux/package-tarball.sh x64 "$(node -p "require('./package.json').version")" dist

# Linux packages -> .build/linux/deb/amd64/deb/*.deb and .build/linux/rpm/x86_64/*.rpm
# (needs dpkg-dev, fakeroot and rpm; the deb task downloads a Chromium sysroot)
npm run gulp vscode-linux-x64-prepare-deb && npm run gulp vscode-linux-x64-build-deb
npm run gulp vscode-linux-x64-prepare-rpm && npm run gulp vscode-linux-x64-build-rpm

# macOS app -> dist/Remnants-darwin-arm64-<version>.zip
npm run gulp vscode-darwin-arm64
bash build/darwin/package-zip.sh arm64 "$(node -p "require('./package.json').version")" dist
```

`build/linux/package-tarball.sh` renders the desktop entry, icon, MIME types and
completions into the tarball and adds `install.sh`; `build/darwin/package-zip.sh`
ad-hoc signs the bundle (required on Apple silicon) before zipping it with
`ditto`. See [RELEASING.md](RELEASING.md) for cutting an actual release.

### Type-check

```sh
npm run typecheck-client           # type-checks ./src without emitting
```

## Project structure

Remnants follows the Code - OSS layered architecture.

| Path | What lives here |
| --- | --- |
| `src/vs/base/` | Foundation utilities and cross-platform abstractions |
| `src/vs/platform/` | Platform services and dependency-injection infrastructure |
| `src/vs/editor/` | The Monaco text editor: language services, highlighting, editing |
| `src/vs/workbench/` | The application workbench (UI parts, services, feature contributions) |
| `src/vs/code/` | Electron main-process entry points |
| `src/vs/server/` | Server / remote implementation |
| `extensions/` | Built-in extensions (Git, language features, themes, debugging) |
| `build/` | Gulp build, packaging, and CI tooling |
| `resources/` | Icons, installer assets, platform resources |

## Docs

- [CHANGES.md](CHANGES.md): what Remnants changes against upstream, and how to check it.
- [RELEASING.md](RELEASING.md): how a release is cut and checked.

## Contributing

This is a personal project, but issues and pull requests are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). Security reports go through [SECURITY.md](SECURITY.md).

## License

Remnants is released under the [MIT License](LICENSE.txt). It is derived from [Code - OSS](https://github.com/microsoft/vscode), which is also MIT-licensed; the original copyright notice is retained in `LICENSE.txt` as the license requires. See [CHANGES.md](CHANGES.md) for the provenance and the full scope of local changes. Remnants is not affiliated with or endorsed by Microsoft.
