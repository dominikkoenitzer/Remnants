# Remnants

[![CI](https://github.com/dominikkoenitzer/Remnants/actions/workflows/ci.yml/badge.svg)](https://github.com/dominikkoenitzer/Remnants/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
[![Latest release](https://img.shields.io/github/v/release/dominikkoenitzer/Remnants?sort=semver&display_name=tag)](https://github.com/dominikkoenitzer/Remnants/releases/latest)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-blue.svg)](#install)
[![Built on Code - OSS](https://img.shields.io/badge/built%20on-Code%20--%20OSS-1f7abf.svg)](https://github.com/microsoft/vscode)

**A clean, AI-free code editor.** Remnants is a personal build derived from [Code - OSS](https://github.com/microsoft/vscode) (the open-source core of VS Code) with every built-in AI surface, telemetry hook, and corporate integration stripped out. It keeps everything that makes a great editor (fast editing, IntelliSense, an integrated terminal, Git, and debugging) and nothing else.

> No Copilot. No agents. No telemetry. No sign-in. Just the editor.

> [!NOTE]
> Almost all of the code here is Microsoft's. Remnants is derived from upstream
> commit [`93cfdd48`](https://github.com/microsoft/vscode/commit/93cfdd489c3b228840d0f86ec77c3636277c93ea)
> (release 1.125.0); my own contribution is roughly −759,000 / +2,800 lines on
> top of it. **[CHANGES.md](CHANGES.md) documents exactly what I changed** and
> how to verify it.

---

## Why Remnants?

VS Code is an excellent editor wrapped in a growing layer of cloud services, chat panels, agent windows, and account prompts. Remnants removes that layer entirely:

- **No built-in AI**: Copilot, the chat panel, agent sessions, voice, and the bundled AI extension are all removed. (Use [Claude Code](https://claude.com/claude-code) or any tool you like in the terminal instead.)
- **No telemetry**: telemetry is disabled at the product level.
- **No account prompts**: no "Set up Copilot", no sign-in entries in the title bar or status bar.
- **Open marketplace**: extensions resolve through [Open VSX](https://open-vsx.org) rather than the Microsoft Marketplace.
- **Everything else stays**: the editor, language features, terminal, source control, tasks, and the JavaScript/Node debugger all work exactly as you expect.

## Features

| Area | Status |
| --- | --- |
| Code editing, multi-cursor, IntelliSense, refactoring | ✅ Full |
| Integrated terminal | ✅ Full |
| Source control (Git, GitHub auth) | ✅ Full |
| Debugging (JavaScript / Node via `js-debug`) | ✅ Kept |
| Extensions via [Open VSX](https://open-vsx.org) | ✅ Full |
| Themes, keybindings, settings, profiles | ✅ Full |
| Built-in Copilot / Chat / agents / voice | ❌ Removed |
| Telemetry & crash reporting | ❌ Disabled |

## Keyboard shortcuts

Remnants uses the standard VS Code keybindings. A few of the most useful:

| Action | Windows / Linux | macOS |
| --- | --- | --- |
| Command Palette | `Ctrl+Shift+P` | `Shift+Cmd+P` |
| Quick Open (go to file) | `Ctrl+P` | `Cmd+P` |
| Toggle integrated terminal | `` Ctrl+` `` | `` Ctrl+` `` |
| Global search | `Ctrl+Shift+F` | `Shift+Cmd+F` |
| Go to symbol | `Ctrl+Shift+O` | `Shift+Cmd+O` |
| Toggle sidebar | `Ctrl+B` | `Cmd+B` |
| Split editor | `Ctrl+\` | `Cmd+\` |
| Format document | `Shift+Alt+F` | `Shift+Option+F` |

The full reference lives under **Help -> Keyboard Shortcuts Reference** inside the app.

## Install

Download from the [**Releases** page](https://github.com/dominikkoenitzer/Remnants/releases/latest).
Every asset is built by the [release workflow](.github/workflows/release.yml) on GitHub Actions.

| Platform | Asset | Install with |
| --- | --- | --- |
| Windows x64 | `RemnantsUserSetup-x64.exe` | run it (per-user, no admin) |
| Windows arm64 | `RemnantsUserSetup-arm64.exe` | run it (per-user, no admin) |
| macOS (Apple silicon) | `Remnants-darwin-arm64-<version>.dmg` | open, drag to Applications |
| macOS (Intel) | `Remnants-darwin-x64-<version>.dmg` | open, drag to Applications |
| Debian, Ubuntu x64 / arm64 | `remnants-<version>-<amd64,arm64>.deb` | `sudo apt install ./<file>` |
| Fedora, RHEL, openSUSE x64 / arm64 | `remnants-<version>-<x86_64,aarch64>.rpm` | `sudo dnf install ./<file>` |
| Any Linux x64 / arm64 | `Remnants-linux-<arch>-<version>.tar.gz` | `sudo ./install.sh` |
| Arch Linux | `PKGBUILD` | `makepkg -si` |

Remnants does not update itself and phones nowhere to check, so new versions are
announced only on that page. **Watch -> Custom -> Releases** on the repository
turns that into an email.

Each release also carries a machine-wide Windows installer
(`RemnantsSetup-<arch>.exe`), a Windows archive for machines where no installer
may run (`Remnants-win32-<arch>-<version>.zip`) and the macOS app as a plain zip.

| Platform | Needs |
| --- | --- |
| Windows | 10 or later, x64 or arm64 |
| macOS | 12 Monterey or later, Apple silicon or Intel |
| Linux | glibc 2.34 or newer, x64 or arm64 - Ubuntu 22.04+, Debian 12+, Fedora 35+, RHEL 9+ |

Remnants is not code-signed on any platform, so each one asks you to confirm the
first launch once. The steps below say how.

### Windows (x64 and arm64)

1. Download **`RemnantsUserSetup-x64.exe`**, or **`RemnantsUserSetup-arm64.exe`**
   on an ARM machine (Snapdragon laptops, Surface Pro X and later, Windows on a
   Mac VM), and run it. It installs into your user profile, so no administrator
   rights are needed, and adds **Remnants** to the Start menu.
2. SmartScreen may warn *"Windows protected your PC."* Click **More info -> Run
   anyway**.

### macOS (Apple silicon and Intel)

1. Download `Remnants-darwin-arm64-<version>.dmg` (Apple silicon, M1 and later)
   or `Remnants-darwin-x64-<version>.dmg` (Intel).
2. Open it and drag **Remnants** onto the Applications shortcut. (The same build
   is also published as a `.zip` if you prefer that.)
3. The build is ad-hoc signed but not notarized, so clear the download
   quarantine flag once:

   ```sh
   xattr -dr com.apple.quarantine /Applications/Remnants.app
   ```

   Without this, macOS reports that the app "is damaged and can't be opened".
   That message means unnotarized, not corrupted.

To get the `remnants` command in your shell, run **Shell Command: Install
'remnants' command in PATH** from the Command Palette.

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
entry, icon, MIME types and shell completions. `sudo apt remove remnants` or
`sudo dnf remove remnants` takes it all back out. Neither package adds a
repository or an update channel: new versions come from the releases page.

#### Any other distribution

The tarball works on any distribution: it carries the app plus a desktop entry,
icon, MIME types and shell completions.

```sh
tar -xzf Remnants-linux-x64-<version>.tar.gz
cd Remnants-linux-x64
sudo ./install.sh            # into /opt/remnants, plus a /usr/local/bin/remnants symlink
```

No root? `./install.sh --user` installs into `~/.local` instead. Either way,
`./install.sh --help` lists the options, and `uninstall.sh` (with the same flag
you installed with) removes everything again.

#### Arch Linux

Let pacman own the install instead. Download `PKGBUILD` from the release into an
empty directory:

```sh
makepkg -si
```

That builds the `remnants-bin` package from the published tarball, verifies its
checksum, and installs it to `/opt/remnants` with `/usr/bin/remnants` on your
PATH. Remove it later with `sudo pacman -R remnants-bin`.

#### Wayland (Hyprland, Sway, GNOME, KDE)

Remnants runs natively on Wayland out of the box. The desktop entry launches with
`--ozone-platform-hint=auto`, and the `remnants` shell command exports the
equivalent `ELECTRON_OZONE_PLATFORM_HINT=auto`, so it picks Wayland when
`WAYLAND_DISPLAY` is set and X11 otherwise. That matters most under fractional
scaling, where XWayland renders the whole window blurry.

To force XWayland instead, export `ELECTRON_OZONE_PLATFORM_HINT=x11`, or launch
with `remnants --ozone-platform-hint=x11`.

For window rules under Hyprland, confirm the app ID with `hyprctl clients` while
Remnants is open (Electron derives it from the desktop entry, so it should be
`remnants`), then match on it:

```
windowrulev2 = workspace 2, class:^(remnants)$
```

### Verify a download

Each release ships a `SHA256SUMS` file covering every asset:

```sh
sha256sum -c SHA256SUMS --ignore-missing
```

Every asset also carries a signed build provenance attestation. Nothing here is
code-signed, so this is how you prove a file came from the release workflow in
this repository and was not swapped afterwards:

```sh
gh attestation verify <file> -R dominikkoenitzer/Remnants
```

### Where your data lives

Uninstalling never touches these.

| Platform | Settings, keybindings, profiles | Extensions |
| --- | --- | --- |
| Windows | `%APPDATA%\Remnants` | `%USERPROFILE%\.remnants\extensions` |
| macOS | `~/Library/Application Support/Remnants` | `~/.remnants/extensions` |
| Linux | `~/.config/Remnants` | `~/.remnants/extensions` |

## Build from source

Remnants builds with the same toolchain as Code - OSS. CI builds on **Node 22**,
because the committed `package-lock.json` is only in sync under npm 10's
resolver; npm 11 (bundled with Node 24) rejects `npm ci`. Node 24 matches
`.nvmrc` and works for `npm install`.

### Prerequisites

Common to every platform: **Node.js 22 or 24** and **Python 3.13** (node-gyp
compiles the native modules from source, per `.npmrc`).

| Platform | Also needs |
| --- | --- |
| Windows | **Visual Studio 2022 C++ Build Tools** with *Desktop development with C++* and the Spectre-mitigated libraries (`Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre`; not part of `--includeRecommended`, add it explicitly). Building the arm64 installer also needs the ARM64 C++ tools and their Spectre libraries |
| macOS | Xcode Command Line Tools (`xcode-select --install`) |
| Linux | `libkrb5-dev libx11-dev libxkbfile-dev libsecret-1-dev` on Debian/Ubuntu; `krb5 libx11 libxkbfile libsecret` on Arch |

If you build with Node 22, set `VSCODE_SKIP_NODE_VERSION_CHECK=1` first to bypass
the `.nvmrc` Node 24 pin.

### Run a development build

```sh
npm install
npm run transpile                  # fast esbuild build of client + built-in extensions
npm run download-builtin-extensions
scripts/code.sh                    # scripts\code.bat on Windows
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
npm run compile-check-ts-native    # type-checks ./src without emitting
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

## Contributing

This is a personal project, but issues and pull requests are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). Security reports go through [SECURITY.md](SECURITY.md).

## License

Remnants is released under the [MIT License](LICENSE.txt). It is derived from [Code - OSS](https://github.com/microsoft/vscode), which is also MIT-licensed; the original copyright notice is retained in `LICENSE.txt` as the license requires. See [CHANGES.md](CHANGES.md) for the provenance and the full scope of local changes. Remnants is **not** affiliated with or endorsed by Microsoft.
