# Remnants

[![CI](https://github.com/dominikkoenitzer/Remnants/actions/workflows/ci.yml/badge.svg)](https://github.com/dominikkoenitzer/Remnants/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
[![Latest release](https://img.shields.io/github/v/release/dominikkoenitzer/Remnants?sort=semver&display_name=tag)](https://github.com/dominikkoenitzer/Remnants/releases/latest)
[![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)](#install)
[![Built on Code - OSS](https://img.shields.io/badge/built%20on-Code%20--%20OSS-1f7abf.svg)](https://github.com/microsoft/vscode)

**A clean, AI-free code editor.** Remnants is a personal fork of [Code - OSS](https://github.com/microsoft/vscode) (the open-source core of VS Code) with every built-in AI surface, telemetry hook, and corporate integration stripped out. It keeps everything that makes a great editor — fast editing, IntelliSense, an integrated terminal, Git, and debugging — and nothing else.

> No Copilot. No agents. No telemetry. No sign-in. Just the editor.

---

## Why Remnants?

VS Code is an excellent editor wrapped in a growing layer of cloud services, chat panels, agent windows, and account prompts. Remnants removes that layer entirely:

- **No built-in AI** — Copilot, the chat panel, agent sessions, voice, and the bundled AI extension are all removed. (Use [Claude Code](https://claude.com/claude-code) or any tool you like in the terminal instead.)
- **No telemetry** — telemetry is disabled at the product level.
- **No account prompts** — no "Set up Copilot", no sign-in entries in the title bar or status bar.
- **Open marketplace** — extensions resolve through [Open VSX](https://open-vsx.org) rather than the Microsoft Marketplace.
- **Everything else stays** — the editor, language features, terminal, source control, tasks, and the JavaScript/Node debugger all work exactly as you expect.

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

| Action | Windows |
| --- | --- |
| Command Palette | `Ctrl+Shift+P` |
| Quick Open (go to file) | `Ctrl+P` |
| Toggle integrated terminal | `` Ctrl+` `` |
| Global search | `Ctrl+Shift+F` |
| Go to symbol | `Ctrl+Shift+O` |
| Toggle sidebar | `Ctrl+B` |
| Split editor | `Ctrl+\` |
| Format document | `Shift+Alt+F` |

The full reference lives under **Help → Keyboard Shortcuts Reference** inside the app.

## Install

### Windows (x64)

1. Download the latest **`RemnantsUserSetup.exe`** from the [**Releases** page](https://github.com/dominikkoenitzer/Remnants/releases/latest).
2. Run it. It's a per-user installer — no administrator rights needed; it installs into your user profile and adds **Remnants** to the Start menu.
3. Remnants is not code-signed, so Windows SmartScreen may warn *"Windows protected your PC."* Click **More info → Run anyway** to continue.

> **First run:** Remnants behaves like VS Code, minus the AI and sign-in. There's nothing to log into. Install extensions from the built-in **Extensions** view — they resolve through [Open VSX](https://open-vsx.org). Your settings, keybindings, and extensions live under `%USERPROFILE%\.remnants`.

No release published yet, or want a bleeding-edge build? [Build from source](#build-from-source) to produce the installer yourself.

### macOS / Linux

macOS and Linux are inherited from Code - OSS and should build from source, but are **not currently verified** in this fork, and there are no prebuilt downloads for them yet.

## Build from source

Remnants builds with the same toolchain as Code - OSS.

### Prerequisites (Windows)

- **Node.js 22+** (the tree targets Node 24; on Node 22 set `VSCODE_SKIP_NODE_VERSION_CHECK=1`)
- **Python 3.13**
- **Visual Studio 2022 C++ Build Tools** with the *Desktop development with C++* workload **and** the Spectre-mitigated libraries (`Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre` — this is not in `--includeRecommended`, add it explicitly)

### Run a development build

```sh
npm install
npm run transpile                  # fast esbuild build of client + built-in extensions
npm run download-builtin-extensions
scripts\code.bat                   # launches the dev build
```

### Produce the Windows installer

```sh
npm run gulp vscode-win32-x64
npm run gulp vscode-win32-x64-inno-updater
npm run gulp vscode-win32-x64-user-setup
```

The app is emitted to `..\VSCode-win32-x64\Remnants.exe`; the installer lands in `.build\win32-x64\user-setup\` (Inno's hardcoded output name is `VSCodeSetup.exe` — rename it to `RemnantsUserSetup.exe`).

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

This is a personal fork, but issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Security reports go through [SECURITY.md](SECURITY.md).

## License

Remnants is released under the [MIT License](LICENSE.txt). It is a fork of [Code - OSS](https://github.com/microsoft/vscode), which is also MIT-licensed; the original copyright notice is retained in `LICENSE.txt` as the license requires. Remnants is **not** affiliated with or endorsed by Microsoft.
