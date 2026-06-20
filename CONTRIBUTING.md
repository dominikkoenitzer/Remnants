# Contributing to Remnants

Thanks for your interest! Remnants is a personal, AI-free fork of [Code - OSS](https://github.com/microsoft/vscode). Issues and pull requests are welcome.

## Before you start

Remnants intentionally **removes** built-in AI (Copilot, chat, agents, voice), telemetry, and Microsoft account integrations. Please don't open PRs that re-add those — they're out of scope by design. Bug fixes, editor improvements, performance, and quality-of-life changes are all fair game.

## Reporting issues

- Search [existing issues](https://github.com/dominikkoenitzer/Remnants/issues) first.
- Use the **Bug report** or **Feature request** form when opening a new issue.
- Include your OS, how you installed/built Remnants, and clear steps to reproduce.

For security issues, **do not** open a public issue — follow [SECURITY.md](SECURITY.md).

## Development setup

See [Build from source](README.md#build-from-source) in the README for prerequisites and commands. In short:

```sh
npm install
npm run transpile
npm run download-builtin-extensions
scripts\code.bat
```

For day-to-day work, `npm run watch` gives an incremental build.

## Before submitting a pull request

1. **Type-check** — `npm run compile-check-ts-native` must pass with no errors. This is the same gate CI runs.
2. **Match the existing style** — the codebase uses **tabs**, PascalCase for types/enums, camelCase for functions/variables, and double quotes only for user-facing (localized) strings. See the upstream [coding guidelines](https://github.com/microsoft/vscode/wiki/Coding-Guidelines) for the full conventions.
3. **Keep commits focused** with clear messages.
4. **Don't commit build output** — `out/`, `.build/`, and `node_modules/` are ignored; keep them that way.

## Pull request process

- Branch from `main`.
- Fill in the PR template checklist.
- Keep the diff scoped to one logical change where possible.

## Relationship to upstream

Remnants tracks [microsoft/vscode](https://github.com/microsoft/vscode) as `upstream`. Changes that are generally useful and not Remnants-specific are best contributed to upstream VS Code directly.
