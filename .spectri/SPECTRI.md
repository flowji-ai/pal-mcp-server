# [.SPECTRI/] SPECTRI INFRASTRUCTURE
<!-- target: .spectri/ -->

## Purpose

This is where Spectri's core infrastructure lives. System automation, project memory, and build tooling reside here - not user content.

## Directory Structure

### canonical/

Source of truth for commands and skills. **Never edit agent directories directly** (e.g. `.claude/commands/`, `.qwen/commands/`) — edit `.spectri/canonical/commands/` (commands) or `.spectri/canonical/skills/` (skills), then sync to agent directories.

### Drift Protection

The sync system detects uncommitted changes in agent directories before overwriting and creates timestamped backups. Always edit source files in `.spectri/canonical/`, not agent directory files.

### coordination/

Project knowledge accumulates here. Check before creating new artifacts:
- `constitution.md` - Development governance principles and articles
- `threads/` - Continuation context for handoffs
- `prompts/` - Persistent agent handoff prompts

Additional knowledge folders live in `spectri/` (not `.spectri/`):
- `spectri/adr/` - Architecture Decision Records
- `spectri/rfc/` - Request for Comments
- `spectri/research/` - Investigation notes
- `spectri/coordination/reviews/` - Code and spec reviews

### scripts/

Automation for build, sync, and validation. Use commands and scripts for infrastructure operations.

### templates/

Starting points for creating specs, ADRs, RFCs, and commands. Organized by command group (spectri-core, spectri-trail, etc.).

### manifests/

Command build configuration. Defines which injections apply to which commands.

### config/

System configuration files.

### lib/

Shared library code for scripts and automation.
