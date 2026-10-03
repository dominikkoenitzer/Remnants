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
repository: **39 as of 2026-10-03** (19 high, 16 medium, 4 low).
That number is worth explaining rather than leaving to interpretation.

They come from upstream. Remnants tracks the VS Code tree at
[`04c0d99f`](https://github.com/microsoft/vscode/commit/04c0d99f4fb0d8afe6ce4f0c58e31e183ac3e4b1)
(release 1.139.1), and it carries that tree's 57 lockfiles with it: the
editor's own dependencies plus those of the build scripts, the bundled
extensions, the CLI, and the test harnesses. Dependabot scans all of them and
attributes every transitive advisory to whoever owns the fork. Upstream carries
the same dependency versions at the same commit.

Where they sit:

| Location | Alerts |
| --- | --- |
| CLI (`Cargo.lock`) | 21 |
| Root lockfile (editor + built-ins) | 9 |
| Build tooling | 4 |
| Bundled extensions | 3 |
| Test harnesses | 2 |
| Remote server | 0 |

Of the 39, 13 are on development-only dependencies that never reach a build.

**None of them were introduced here.** Remnants is a subtractive fork: nothing
was added to the root `package.json` to support anything it does. Against the
upstream release it tracks, this one takes **7** direct dependencies out, the
AI SDKs and the Dev Container CLI, and puts none back. The lockfile has moved
since, but only behind in-range refreshes, which carry their own transitive
entries with them.
Compare the two manifests yourself:

```bash
base=04c0d99f4fb0d8afe6ce4f0c58e31e183ac3e4b1
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

What is actually done about them: Dependabot's alerts are on, its security pull
requests are not. Advisories with a fix reachable inside the existing version
ranges are closed by hand, lockfile by lockfile, without touching any
`package.json`. The sweep on 2026-09-16 closed 49 of them, the only critical
one among them, and a second pass on 2026-10-03 closed 83 more.

What is left has no fix inside those ranges. All 21 in the CLI trace back to
`russh`, which the CLI takes as a git dependency on Microsoft's own fork,
[`microsoft/vscode-russh`](https://github.com/microsoft/vscode-russh), locked at
0.37.1. The patched versions are crates.io releases, and a git dependency does
not move to them with `cargo update`. In the root lockfile, the patched
`postcss` is reachable only by downgrading `gulp-sourcemaps`, already at its
latest release; `braces` and `decode-uri-component` come in through gulp 4 and
that same `gulp-sourcemaps`; and `uuid` 3 is what
`@microsoft/dev-tunnels-connections` requires, even in its latest release.
No patched release exists at all for `extract-zip` in the build tooling,
`http-cache-semantics` in the root and build lockfiles, `braces` 3.0.3 in the
npm and Mermaid extensions, or `node-forge` in the API tests. The Emmet
extension pins `image-size` 1.0 and the sanity tests get `diff` 7 through
mocha 11; both fixes are a major version away. These are resolved by rebasing
onto a newer upstream release, which is the only honest way to fix a dependency
you do not own. If you need an editor with a fully patched dependency tree
today, build from [upstream VS Code](https://github.com/microsoft/vscode)
directly.

## Supported versions

As a personal fork, only the latest build from `main` is supported.
