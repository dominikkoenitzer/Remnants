# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in Remnants, please report it **privately**; do not open a public issue.

- Use GitHub's [private vulnerability reporting](https://github.com/dominikkoenitzer/Remnants/security/advisories/new) for this repository, **or**
- Email the maintainer at the address on the [GitHub profile](https://github.com/dominikkoenitzer).

Please include:

- A description of the issue and its impact
- Steps to reproduce (proof of concept if possible)
- The affected version or commit, and your platform

You can expect an acknowledgement within a reasonable time. Please give a reasonable window to address the issue before any public disclosure.

## Scope

Remnants is a fork of [Code - OSS](https://github.com/microsoft/vscode). Vulnerabilities that originate in upstream VS Code are best reported to [Microsoft's VS Code security process](https://github.com/microsoft/vscode/blob/main/SECURITY.md); this policy covers issues specific to the Remnants fork (its build, packaging, branding, and removed/modified components).

## Dependency advisories

GitHub's Dependabot reports a large number of open advisories against this
repository: **42 as of 2026-09-16** (19 high, 21 medium, 2 low).
That number is worth explaining rather than leaving to interpretation.

They come from upstream. Remnants is a snapshot of the VS Code tree at
[`93cfdd48`](https://github.com/microsoft/vscode/commit/93cfdd489c3b228840d0f86ec77c3636277c93ea)
(release 1.125.0), and it carries that tree's 20-odd lockfiles with it: the
editor's own dependencies plus those of the build scripts, the bundled
extensions, the CLI, and the test harnesses. Dependabot scans all of them and
attributes every transitive advisory to whoever owns the fork. Upstream carries
the same dependency versions at the same commit.

Where they sit:

| Location | Alerts |
| --- | --- |
| CLI (`Cargo.lock`) | 16 |
| Root lockfile (editor + built-ins) | 10 |
| Bundled extensions | 8 |
| Build tooling | 7 |
| Test harnesses | 1 |
| Remote server | 0 |

Of the 42, 16 are on development-only dependencies that never reach a build.

**None of them were introduced here.** Remnants is a subtractive fork: nothing
was added to the root `package.json` to support anything it does. Against the
upstream tree it was taken from, this one takes **6** direct dependencies out,
all of them AI SDKs, and puts none back. The lockfile has moved since, but only
behind in-range refreshes, which carry their own transitive entries with them.
Compare the two manifests yourself:

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

What is actually done about them: Dependabot's alerts are on, its pull requests
are not. Advisories with a fix reachable inside the existing version ranges are
closed by hand, by refreshing every lockfile in one pass. The sweep on
2026-09-16 closed 49 of them, the only critical one among them.
A few cannot produce a pull request at all: the patched `postcss` is reachable
only by downgrading `gulp-sourcemaps`, so the security updater reports that
conflict instead of opening one. The rest are resolved by rebasing onto a newer
upstream release, which is the only honest way to fix a dependency you do not
own. If you need an editor with a fully patched dependency tree today, build
from [upstream VS Code](https://github.com/microsoft/vscode) directly.

## Supported versions

As a personal fork, only the latest build from `main` is supported.
