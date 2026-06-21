# Remnants — Agent Instructions

Remnants is a personal, AI-free fork of [Code - OSS](https://github.com/microsoft/vscode) (the open-source core of VS Code). It removes the bundled AI extension and hides every built-in Copilot, chat, agent, voice, telemetry, and corporate sign-in surface, while keeping the editor, IntelliSense, integrated terminal, Git, and JavaScript/Node debugging.

For the project overview, architecture, build steps, and contribution guidelines, see [README.md](README.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

Constraints when working in this tree:

- **Keep it AI-free.** Do not re-introduce Copilot/chat/agent UI or telemetry. Built-in AI is off by default via `chat.disableAIFeatures` (default `true`) and `chat.agentHost.enabled` (default `false`).
- **Open marketplace.** Extensions resolve through [Open VSX](https://open-vsx.org), not the Microsoft Marketplace.
- **Type-check before packaging:** `npm run compile-check-ts-native` (the CI gate).
