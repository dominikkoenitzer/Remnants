# What Remnants changes

Remnants is derived from [Code - OSS](https://github.com/microsoft/vscode), the
open-source core of Visual Studio Code. **The overwhelming majority of the code
in this repository is Microsoft's, not mine.** This file documents exactly what
I changed, so that contribution is easy to audit rather than something you have
to take on faith.

## Provenance

| | |
| --- | --- |
| Upstream | [microsoft/vscode](https://github.com/microsoft/vscode) |
| Base commit | [`93cfdd48`](https://github.com/microsoft/vscode/commit/93cfdd489c3b228840d0f86ec77c3636277c93ea) (2026-06-15) |
| Upstream release | 1.125.0 |
| Upstream licence | MIT, retained in [`LICENSE.txt`](LICENSE.txt), with attribution in [`ThirdPartyNotices.txt`](ThirdPartyNotices.txt) |

> **On the git history.** The upstream tree was imported as a single squashed
> snapshot rather than as a git fork, so this repository does **not** carry
> Microsoft's commit history and GitHub does not display it as a fork. That was
> a mistake in how I set the repository up, not an attempt to claim the code.
> The base commit above is the exact upstream revision this was cut from. The
> history was later reset, so the initial commit here is the tree with the
> removals already applied, not the upstream import. None of the deletions
> described below are visible as commits, and this repository cannot evidence
> them on its own. What it can be checked against is upstream itself, which is
> what the last section does. The upstream tree is marked `linguist-vendored`
> in [`.gitattributes`](.gitattributes) so it is excluded from this
> repository's language statistics.

## Net change

Roughly **−759,000 lines removed** and **+2,800 added**. This is a subtractive
project: the work is in deleting an entire feature surface cleanly without
breaking the editor around it. The figures below are what the removals
measured when they were made; since the history reset they are a record
rather than something this repository can reproduce.

## What was removed

| Change | Scope |
| --- | --- |
| **All built-in AI**: chat, agent sessions, Copilot, MCP, language-model APIs | 2,761 files, −712,045 lines |
| **Remaining AI/MCP/Copilot remnants**: leftover registrations, contributions, settings | 143 files, −21,324 lines |
| **VS Code / Copilot GitHub automation**: upstream workflows, bots, issue triage | 117 files, −19,670 lines |
| **Dead AI welcome/setup code**: agent-sessions welcome, Copilot setup flows | 6 files, −2,731 lines |
| **AI leftovers across git, terminal, editor and search** | 15 files, −586 lines |
| **Telemetry and corporate surfaces**: telemetry disabled at product level, sign-in prompts removed | part of the rebrand commit, 951 files |
| **The bundled AI extension** | removed wholesale |

Extensions resolve through [Open VSX](https://open-vsx.org) instead of the
Microsoft Marketplace, which the Code - OSS licence does not cover.

## What was added or changed

- **Build and release pipeline**: GitHub Releases distribution for Windows
  (x64 and arm64: per-user installer, machine-wide installer, plain archive),
  macOS (disk image and zip, Apple silicon and Intel) and Linux (deb, rpm,
  tarball, Arch `PKGBUILD`, x64 and arm64), built per platform on GitHub-hosted
  runners and published as one release with a checksum file and a signed
  provenance attestation per asset. Pinned to `windows-2022` for the VS 2022
  toolchain and to Node 22 to match the in-sync lockfile. Adds the packaging
  scripts upstream has no equivalent of: a Linux tarball with its desktop
  integration rendered in and an `install.sh` that works on any distro, the Arch
  `PKGBUILD`, and ad-hoc signing for the macOS bundle so it launches on Apple
  silicon. Every asset is installed and run by the workflow that builds it,
  including the arm64 Windows installer on real ARM hardware and the deb and rpm
  in Debian and Fedora containers.
- **Fixes to upstream build scripts**, all of which upstream carries latently and
  only a newer dependency exposes: `gulp-rename` callbacks no longer implicitly
  return the assigned path; `build/package.json` declares the `glob` version its
  scripts import rather than relying on hoisting; the Debian and RPM packaging
  templates no longer register the Microsoft apt or yum repository and its
  signing key; `build/linux/dependencies-generator.ts` skips binaries this fork
  does not build; three extensions declare the
  `@microsoft/applicationinsights-common` that `@vscode/extension-telemetry`
  imports without declaring.
- **`npm install` fix**: the upstream `postinstall` created AI-agent harness
  symlinks that broke installs once the harness was removed.
- **Visual identity**: the Remnants shard icon, themes, product branding, and
  Windows installer artwork.
- **Default settings**: a minimal, quieter default configuration.
- **Repository automation**: upstream's `.github` replaced with a small CI
  workflow and release workflow; test fixtures excluded from secret scanning.

## Verifying this yourself

The removals predate this repository's history, so `git log` will not show
them. What can be checked is this tree against the upstream revision it was
cut from. Comparing the two manifests shows the dependency side of the
removal, six AI SDKs taken out and nothing put back:

```bash
base=93cfdd489c3b228840d0f86ec77c3636277c93ea
curl -s "https://raw.githubusercontent.com/microsoft/vscode/$base/package.json" -o upstream.json
node -e '
const up = require("./upstream.json"), me = require("./package.json");
const names = o => new Set([...Object.keys(o.dependencies || {}), ...Object.keys(o.devDependencies || {})]);
const [U, M] = [names(up), names(me)];
console.log("removed:", [...U].filter(n => !M.has(n)).join(", ") || "none");
console.log("added:", [...M].filter(n => !U.has(n)).join(", ") || "none");
'
rm upstream.json
```

For the rest, clone upstream at that commit and diff the two trees.

## Attribution

Remnants is not affiliated with, endorsed by, or supported by Microsoft.
"Visual Studio Code" and "Copilot" are trademarks of Microsoft. This is a
personal build made for my own use, published in case it is useful to anyone
else.
