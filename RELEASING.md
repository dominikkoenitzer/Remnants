# Releasing Remnants

Remnants ships from a single [GitHub Release](https://github.com/dominikkoenitzer/Remnants/releases)
per version, carrying one asset per platform:

| Asset | Platform |
| --- | --- |
| `RemnantsUserSetup.exe` | Windows x64, per-user installer |
| `Remnants-darwin-arm64-<version>.zip` | macOS, Apple silicon |
| `Remnants-darwin-x64-<version>.zip` | macOS, Intel |
| `Remnants-linux-x64-<version>.tar.gz` | Linux x64 |
| `Remnants-linux-arm64-<version>.tar.gz` | Linux arm64 |
| `PKGBUILD` | Arch Linux, builds `remnants-bin` from the x64/arm64 tarball |
| `SHA256SUMS` | checksums for everything above |

The README's [Install](README.md#install) section points users there.

## Versioning

Remnants tracks the upstream Code - OSS version in `package.json` (`version`, e.g.
`1.125.0`). Tag releases as `v<version>`. If you ship more than one build from the
same upstream base, add a fork suffix to the tag: `v1.125.0-remnants.1`.

## Cutting a release (GitHub Actions)

`.github/workflows/release.yml` builds every platform on GitHub-hosted runners and
publishes the release. It is **manual only** (`workflow_dispatch`); it never runs on
push. A full run takes roughly 30-45 minutes, with the platforms in parallel.

1. Go to **Actions -> Release -> Run workflow**.
2. Leave **version** blank to release the current `package.json` version, or type a
   version; it must match `package.json` (the workflow fails fast otherwise, since
   the assets always report the `package.json` version). The tag is `v<version>`.
3. Pick **platforms**: `all`, or one of `windows` / `linux` / `macos` to rebuild
   just that platform's assets. Set **draft** if you want to inspect the release
   before it goes public.
4. The build jobs upload their assets as run artifacts; the `publish` job collects
   them, renders `PKGBUILD` and `SHA256SUMS`, and creates or updates the release.

Re-running for an existing tag is safe: `publish` re-uploads the assets to that
release (`--clobber`) and refreshes the notes instead of failing. Because each
platform is a separate job, a failure on one still ships the others - the `publish`
job runs on `always()` and takes whatever artifacts exist. If it published a partial
set, fix the broken platform and re-run the workflow with **platforms** set to just
that one.

### Pins that must stay

- **Windows on `windows-2022`**, not `windows-latest`. `.npmrc` sets
  `build_from_source=true`, so every native module compiles with node-gyp, and the
  bundled node-gyp cannot use the Visual Studio 18 toolchain on `windows-latest`
  ("find VS unknown version").
- **Node 22 everywhere.** The committed `package-lock.json` is only in sync under
  npm 10's resolver; npm 11 (bundled with Node 24) rejects `npm ci` over the
  `ssh2 > cpu-features` override. `VSCODE_SKIP_NODE_VERSION_CHECK=1` bypasses the
  `.nvmrc` Node 24 pin.
- **Linux on `ubuntu-22.04`**, so the binaries link against an older glibc and stay
  loadable on older distros. glibc is backwards compatible, so this build still runs
  on Arch and current Fedora/Ubuntu.
- **macOS is ad-hoc signed** in `build/darwin/package-zip.sh`. Apple silicon refuses
  to execute an arm64 binary with no valid signature, and the packaging step
  invalidates the one Electron shipped with. Drop that and the app dies at launch
  with "is damaged and can't be opened".

## Building the assets locally

The same scripts the workflow calls, so a local build produces identical layouts.

```sh
npm install
npm run download-builtin-extensions
version=$(node -p "require('./package.json').version")

# Windows (from a Windows machine)
npm run gulp vscode-win32-x64
npm run gulp vscode-win32-x64-inno-updater
npm run gulp vscode-win32-x64-user-setup
# -> .build\win32-x64\user-setup\VSCodeSetup.exe, rename to RemnantsUserSetup.exe

# Linux
npm run gulp vscode-linux-x64
bash build/linux/package-tarball.sh x64 "$version" dist

# macOS (from a Mac; x64 assets need an Intel Mac or Rosetta)
npm run gulp vscode-darwin-arm64
bash build/darwin/package-zip.sh arm64 "$version" dist

# Arch package + checksums, once the tarballs are in dist/
bash build/linux/render-pkgbuild.sh "$version" dist
( cd dist && sha256sum -- * > SHA256SUMS )
```

Then publish with the [GitHub CLI](https://cli.github.com/), authenticated against
this repo (`gh auth login`):

```sh
gh release create "v$version" dist/* \
  --title "Remnants v$version" \
  --notes-file <(bash build/release-notes.sh "$version" dist)
```

## What the packaging scripts do

- **`build/linux/package-tarball.sh`** renames `../VSCode-linux-<arch>` to
  `Remnants-linux-<arch>`, renders the desktop entry, URL handler, icon, AppStream
  metadata, MIME type and shell completions from the templates in `resources/linux`,
  adds `install.sh` / `uninstall.sh`, and tars it. Only the deb/rpm/snap gulp tasks
  generate those integration files otherwise, and those need a Chromium sysroot plus
  `dpkg-shlibdeps` to compute distro dependencies. A tarball needs none of that and
  installs anywhere, so it is what we ship.
- **`build/darwin/package-zip.sh`** ad-hoc signs `Remnants.app`, verifies the
  signature, checks the binary runs headlessly, and zips it with `ditto` so
  symlinks and the signature survive.
- **`build/linux/render-pkgbuild.sh`** fills
  `resources/linux/arch/PKGBUILD.template` in with the version, the release URLs and
  the tarball checksums. It covers only the architectures that actually built, and
  skips itself if no Linux tarball is present.
- **`build/release-notes.sh`** writes the release body, mentioning only the
  platforms present in `dist/`.

## After releasing

- The Linux job already installs the tarball, launches the binary and uninstalls it
  again as a smoke test, so a broken Linux asset fails the build rather than
  shipping. Windows and macOS are not installed end to end in CI; verify those on a
  clean machine.
- The README badge and Install link resolve to the latest release automatically.
