# Releasing Remnants

Remnants ships from a single [GitHub Release](https://github.com/dominikkoenitzer/Remnants/releases)
per version, carrying every platform it supports:

| Asset | Platform |
| --- | --- |
| `RemnantsUserSetup-x64.exe` | Windows x64, per-user installer |
| `RemnantsUserSetup-arm64.exe` | Windows arm64, per-user installer |
| `RemnantsSetup-<arch>.exe` | Windows machine-wide installer |
| `Remnants-win32-<arch>-<version>.zip` | Windows, no installer |
| `Remnants-darwin-arm64-<version>.dmg` | macOS disk image, Apple silicon |
| `Remnants-darwin-x64-<version>.dmg` | macOS disk image, Intel |
| `Remnants-darwin-arm64-<version>.zip` | macOS, Apple silicon |
| `Remnants-darwin-x64-<version>.zip` | macOS, Intel |
| `remnants-<version>-amd64.deb` | Debian, Ubuntu x64 |
| `remnants-<version>-arm64.deb` | Debian, Ubuntu arm64 |
| `remnants-<version>-x86_64.rpm` | Fedora, RHEL, openSUSE x64 |
| `remnants-<version>-aarch64.rpm` | Fedora, RHEL, openSUSE arm64 |
| `Remnants-linux-x64-<version>.tar.gz` | any Linux x64 |
| `Remnants-linux-arm64-<version>.tar.gz` | any Linux arm64 |
| `PKGBUILD` | Arch Linux, builds `remnants-bin` from the x64/arm64 tarball |
| `SHA256SUMS` | checksums for everything above |

Every asset also gets a signed provenance attestation
(`actions/attest-build-provenance`), so a download can be traced back to this
workflow with `gh attestation verify <file> -R dominikkoenitzer/Remnants` even
though none of the binaries is code-signed.

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
- **`npm_config_arch` on the Windows job.** Both installers are built on the same
  x64 runner; that variable is what makes node-gyp compile the native modules for
  arm64. Without it the arm64 installer would carry x64 `.node` files. The job
  reads the PE header of the packaged `Remnants.exe` afterwards to prove the
  architecture is the one it claims.
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

# Windows (from a Windows machine; swap x64 for arm64 to cross-build the ARM
# installer, with npm_config_arch=arm64 set before npm install)
npm run gulp vscode-win32-x64
npm run gulp vscode-win32-x64-inno-updater
npm run gulp vscode-win32-x64-user-setup
# -> .build\win32-x64\user-setup\VSCodeSetup.exe, rename to RemnantsUserSetup-x64.exe

# Linux tarball
npm run gulp vscode-linux-x64
bash build/linux/package-tarball.sh x64 "$version" dist

# Linux packages (needs dpkg-dev, fakeroot and rpm)
npm run gulp vscode-linux-x64-prepare-deb && npm run gulp vscode-linux-x64-build-deb
npm run gulp vscode-linux-x64-prepare-rpm && npm run gulp vscode-linux-x64-build-rpm
cp .build/linux/deb/amd64/deb/*.deb "dist/remnants-$version-amd64.deb"
cp .build/linux/rpm/x86_64/*.rpm "dist/remnants-$version-x86_64.rpm"

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
  --notes-file <(ls dist > /tmp/assets && bash build/release-notes.sh "$version" /tmp/assets)
```

## What the packaging scripts do

- **`build/linux/package-tarball.sh`** renames `../VSCode-linux-<arch>` to
  `Remnants-linux-<arch>`, renders the desktop entry, URL handler, icon, AppStream
  metadata, MIME type and shell completions from the templates in `resources/linux`,
  adds `install.sh` / `uninstall.sh`, and tars it. It needs no sysroot and installs
  on any distribution, which is why it ships next to the deb and the rpm.
- **The deb and rpm gulp tasks** package the same build for apt and dnf. The deb
  task downloads a Chromium sysroot and runs `dpkg-shlibdeps` to compute the distro
  dependencies; `build/linux/dependencies-generator.ts` skips binaries this fork
  does not build (the tunnel CLI) and warns about dependency drift instead of
  failing the build. The Debian and RPM templates in `resources/linux` carry no
  Microsoft repository, key or branding: installing a Remnants package changes no
  apt or yum source.
- **`build/darwin/package-zip.sh`** ad-hoc signs `Remnants.app`, verifies the
  signature, checks the binary runs headlessly, and zips it with `ditto` so
  symlinks and the signature survive. The disk image is built afterwards in the
  workflow with plain `hdiutil` from that same signed bundle, plus a symlink to
  `/Applications` to drag onto.
- **`build/linux/render-pkgbuild.sh`** fills
  `resources/linux/arch/PKGBUILD.template` in with the version, the release URLs and
  the tarball checksums. It covers only the architectures that actually built, and
  skips itself if no Linux tarball is present.
- **`build/release-notes.sh`** writes the release body from a list of asset names,
  mentioning only the platforms the release actually has. The publish job feeds it
  the release's own asset list, so re-running one platform never drops the others
  from the notes or from `SHA256SUMS`.

## Supported platform floors

The Linux job prints the highest glibc symbol version anything in the build needs
("Needs at least GLIBC_2.34" at the time of writing) and the macOS job prints the
bundle's `LSMinimumSystemVersion`. Both end up in the README and the release notes,
so read them out of the log after a dependency or Electron bump rather than
assuming they held: a single bundled library is enough to move the floor, and the
main executable on its own reports a much older one than the build really needs.

## After releasing

- Every asset is exercised before or right after it is published, on hardware of its
  own architecture wherever a runner exists for it:

  | Asset | What the run proves |
  | --- | --- |
  | Windows x64 installer | silent install, then `remnants --version` from the installed copy |
  | Windows arm64 installer | PE header says ARM64, then a separate `windows-11-arm` job installs and runs it |
  | Windows archive | unpacked and run without any installer |
  | Windows system installer | built and published; the payload is the one the user installer ships |
  | macOS zip and dmg | ad-hoc signature verified, app launched, image mounted back and re-verified |
  | Linux tarball | install/uninstall round trip plus `remnants --version` |
  | deb | installed on the build host and again in a Debian 12 container |
  | rpm | installed in a Fedora container, so dnf has to resolve the computed dependencies |

  Both macOS jobs and both Linux jobs run on their target architecture, so those
  builds are executed natively. The only assets never run end to end are the
  Windows arm64 archive and system installer, which carry the same payload as the
  arm64 user installer that is.
- The README badge and Install link resolve to the latest release automatically.
