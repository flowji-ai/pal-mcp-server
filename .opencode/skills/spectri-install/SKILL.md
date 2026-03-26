---
name: spectri-install
description: "Use when a user asks how to install Spectri, set up a new project, or troubleshoot installation issues."
metadata:
  version: "1.0"
  date-created: "2026-03-08"
  date-updated: "2026-03-08"
  created-by: "claude-opus-4-6"
  managed-by: "spectri"
  ships-with-product: "true"
  spectri-pattern: "guidance"
---

# Install Spectri

Directional guide for installing Spectri and initialising a project. Points to the right tool at each step — does not replace the tools' own output.

## Prerequisites

**Python 3.10+** is required. Verify with `python3 --version`.

**pipx** is the recommended installer (isolates Spectri in its own virtualenv):

```bash
# macOS — install pipx via Homebrew first
brew install pipx
pipx ensurepath

# Linux — use your package manager or pip
python3 -m pip install --user pipx
pipx ensurepath
```

Alternative: `uv tool install spectri` if the project already uses [uv](https://docs.astral.sh/uv/).

## Install the CLI

```bash
pipx install spectri
```

Verify: `spectri --help` should display available commands.

## Remove Predecessor Frameworks

If the repo previously used OpenSpec, Spec Kit, or another specification framework, remove its artifacts before initialising. Spectri's init detects existing infrastructure and will refuse to overwrite it. Clean up old `.spectri/`, `specs/`, or framework-specific directories first.

## Initialise a Project

Run `spectri init` in the project root. The command handles folder creation, template deployment, and AGENTS.md injection. Use `--dry-run` to preview what will be created.

After init, run `spectri sync-canonical` to deploy commands and skills to agent directories (`.claude/`, `.qwen/`, etc.).

## Updating

After upgrading the Spectri package (`pipx upgrade spectri`), run `spectri update` in each initialised project to re-deploy framework files. The update command preserves user content and only overwrites framework-managed files.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `command not found: spectri` | Run `pipx ensurepath` and restart your shell |
| `spectri init` refuses to run | Check for existing `.spectri/` or `specs/` directories — remove or migrate first |
| Permission errors on macOS | Use `pipx` instead of bare `pip` (PEP 668 blocks system-level installs) |
