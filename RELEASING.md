# Releasing Remnants

Remnants is distributed as a **Windows (x64) user installer** (`RemnantsUserSetup.exe`)
attached to a [GitHub Release](https://github.com/dominikkoenitzer/Remnants/releases).
The README's [Install](README.md#install) section points users there.

There are two ways to cut a release: **build locally** (the default — a full Electron
build is heavy) or **build on GitHub Actions** (optional, manual).

## Prerequisites

- A working build environment — see [Build from source](README.md#build-from-source)
  (Node 24, Python 3.13, VS 2022 C++ Build Tools with the Spectre-mitigated libs).
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
(`workflow_dispatch`) — it never runs on push. A full run takes ~15–20 minutes.

1. Go to **Actions → Release (Windows installer) → Run workflow**.
2. Leave **version** blank to release the current `package.json` version, or type a
   version — it must match `package.json` (the workflow fails fast otherwise, since the
   installer always reports the `package.json` version). The tag is `v<version>`.
3. The job builds, attaches `RemnantsUserSetup.exe` as a run artifact, and creates the
   `v<version>` GitHub Release. Re-running for an existing tag is safe: it re-uploads the
   installer to that release (`--clobber`) instead of failing.

> ✅ Validated: `v1.125.0` was cut this way. Two pins make it work and must stay:
> the job runs on **`windows-2022`** (the VS 2022 C++ toolchain node-gyp needs —
> `windows-latest` ships VS 18, which the bundled node-gyp can't use) and on **Node 22**
> (npm 10 — the committed `package-lock.json` is only in sync under npm 10's resolver;
> npm 11 from Node 24 rejects `npm ci`). If a step fails, the installer is still
> recoverable from the run's uploaded artifact even if the release step fails.

## After releasing

- Verify the asset downloads and the installer runs on a clean Windows machine.
- The README badge and Install link resolve to the latest release automatically.
