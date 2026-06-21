# Releasing Remnants

Remnants is distributed as a **Windows (x64) user installer** (`RemnantsUserSetup.exe`)
attached to a [GitHub Release](https://github.com/dominikkoenitzer/Remnants/releases).
The README's [Install](README.md#install) section points users there.

There are two ways to cut a release: **build locally** (the default — a full Electron
build is heavy) or **build on GitHub Actions** (optional, manual).

## Prerequisites

- A working build environment — see [Build from source](README.md#build-from-source)
  (Node 22+, Python 3.13, VS 2022 C++ Build Tools with the Spectre-mitigated libs).
- The [GitHub CLI](https://cli.github.com/) (`gh`), authenticated against this repo
  (`gh auth login`).

## Versioning

Remnants tracks the upstream Code - OSS version in `package.json` (`version`, e.g.
`1.125.0`). Tag releases as `v<version>`. If you ship more than one build from the same
upstream base, add a fork suffix to the tag: `v1.125.0-remnants.1`.

## Option A — build locally, then publish (default)

```sh
npm install
npm run gulp vscode-win32-x64
npm run gulp vscode-win32-x64-inno-updater
npm run gulp vscode-win32-x64-user-setup
```

The app is emitted to `..\VSCode-win32-x64\Remnants.exe`; the installer lands in
`.build\win32-x64\user-setup\VSCodeSetup.exe` (Inno's output name is hardcoded).
Rename it and publish the release with `gh`:

```powershell
$version = '1.125.0'                                  # match package.json
$src = '.build\win32-x64\user-setup\VSCodeSetup.exe'
$out = ".build\win32-x64\user-setup\RemnantsUserSetup.exe"
Copy-Item $src $out -Force

gh release create "v$version" $out `
  --title "Remnants v$version" `
  --notes "Windows (x64) user installer. AI-free build of Code - OSS $version. Unsigned — on first launch click ``More info -> Run anyway`` past Windows SmartScreen."
```

Users can now download `RemnantsUserSetup.exe` from the release.

## Option B — build on GitHub Actions (optional)

`.github/workflows/release.yml` runs the full Windows packaging build on a
GitHub-hosted runner and uploads the installer to a release. It is **manual only**
(`workflow_dispatch`) — it never runs on push, because the build is heavy (~1 hour).

1. Go to **Actions → Release (Windows installer) → Run workflow**.
2. Enter the version (e.g. `1.125.0`) and run it.
3. The job builds, attaches `RemnantsUserSetup.exe` as a run artifact, and creates the
   `v<version>` GitHub Release.

> ⚠️ This workflow has not yet been validated by a real run. Before relying on it,
> dispatch it once and confirm the Windows runner has everything it needs (native
> module builds, Inno Setup, the Spectre libs). If a step fails, the README's local
> build (Option A) remains the source of truth, and the installer is still recoverable
> from the run's uploaded artifact even if the release step fails.

## After releasing

- Verify the asset downloads and the installer runs on a clean Windows machine.
- The README badge and Install link resolve to the latest release automatically.
