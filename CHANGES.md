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
| Upstream licence | MIT — retained in [`LICENSE.txt`](LICENSE.txt), with attribution in [`ThirdPartyNotices.txt`](ThirdPartyNotices.txt) |

> **On the git history.** The upstream tree was imported as a single squashed
> snapshot rather than as a git fork, so this repository does **not** carry
> Microsoft's commit history and GitHub does not display it as a fork. That was
> a mistake in how I set the repository up, not an attempt to claim the code.
> The base commit above is the exact upstream revision this was cut from, and
> every change of mine is a separate commit on top of it. The upstream tree is
> marked `linguist-vendored` in [`.gitattributes`](.gitattributes) so it is
> excluded from this repository's language statistics.

## Net change

Roughly **−759,000 lines removed** and **+2,800 added** across 18 commits. This
is a subtractive project: the work is in deleting an entire feature surface
cleanly without breaking the editor around it.

## What was removed

| Change | Scope |
| --- | --- |
| **All built-in AI** — chat, agent sessions, Copilot, MCP, language-model APIs | 2,761 files, −712,045 lines |
| **Remaining AI/MCP/Copilot remnants** — leftover registrations, contributions, settings | 143 files, −21,324 lines |
| **VS Code / Copilot GitHub automation** — upstream workflows, bots, issue triage | 117 files, −19,670 lines |
| **Dead AI welcome/setup code** — agent-sessions welcome, Copilot setup flows | 6 files, −2,731 lines |
| **AI leftovers across git, terminal, editor and search** | 15 files, −586 lines |
| **Telemetry and corporate surfaces** — telemetry disabled at product level, sign-in prompts removed | part of the rebrand commit, 951 files |
| **The bundled AI extension** | removed wholesale |

Extensions resolve through [Open VSX](https://open-vsx.org) instead of the
Microsoft Marketplace, which the Code - OSS licence does not cover.

## What was added or changed

- **Build and release pipeline** — GitHub Releases distribution for a Windows
  user-setup installer, then hardened: pinned to `windows-2022` for the VS 2022
  toolchain, and to Node 22 to match the in-sync lockfile.
- **`npm install` fix** — the upstream `postinstall` created AI-agent harness
  symlinks that broke installs once the harness was removed.
- **Visual identity** — the Remnants shard icon, themes, product branding, and
  Windows installer artwork.
- **Default settings** — a minimal, quieter default configuration.
- **Repository automation** — upstream's `.github` replaced with a small CI
  workflow and release workflow; test fixtures excluded from secret scanning.

## Verifying this yourself

```bash
git log --oneline --reverse          # every change, oldest first
git log --stat <commit>              # the exact diff of any one of them
```

Every commit after the initial import is mine and is scoped to one concern.

## Attribution

Remnants is not affiliated with, endorsed by, or supported by Microsoft.
"Visual Studio Code" and "Copilot" are trademarks of Microsoft. This is a
personal build made for my own use, published in case it is useful to anyone
else.
