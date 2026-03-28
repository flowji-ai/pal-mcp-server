# Multi-Model Orchestration Server v2 — Planning Document

> This document captures the design intent, architecture decisions, and implementation guidance for building a new multi-model orchestration MCP server to replace the current PAL MCP Server fork. It is the output of a deep investigation session on 2026-03-27/28 and incorporates findings from multi-agent architecture reviews.

## Vision

A multi-model orchestration server that is part of the **Spectri family** (alongside Spectri, Spectri Scribe, Spectri Speak, and the Spectri Claude Plugin). Spectri users can opt into multi-model capabilities: consensus reviews, multi-agent code review, cross-model validation, and plan evaluation.

The tool should be:
- **CLI-first** — the primary interface is a CLI tool, not an MCP server. MCP is an optional transport wrapper for IDE integration. CLI is 10-32x cheaper in token overhead and 100% reliable vs MCP's 72% (industry benchmarks, March 2026)
- **Ours** — not a fork with upstream constraints, but a purpose-built tool we own and extend freely
- **Consolidated but not monolithic** — our tool handles orchestration; CLIProxyAPI and qwen-code-oai-proxy remain separate services (different concerns, different languages)
- **Configurable** — consensus panels, review types, and model tiers are user-defined
- **Resilient** — rate limiting, health monitoring, automatic failover, and config that can't be accidentally wiped

### CLI-First Architecture

The industry is moving away from MCP-first designs. Perplexity dropped MCP in March 2026. CLI tools consume 1.3K tokens vs 44K for equivalent MCP tool schemas. Any LLM agent can shell out to a CLI tool natively.

```
Our tool (CLI-native)
├── CLI interface (primary — any agent can call it)
├── MCP wrapper (optional — for Claude Code / IDE integration only)
└── Provider layer (GLM, Gemini, Groq, Mercury, local models via CLIProxyAPI)
```

The core logic (consensus, routing, health monitoring) lives in the CLI. MCP is a thin transport layer that exposes the same tools to IDE-based agents.

## Three-Service Architecture (Confirmed)

All three reviewers agreed: keep the three-service split.

```
Spectri PAL (our MCP server)
    ↓
CLIProxyAPI (localhost:8317) — OAuth management, multi-provider routing, account round-robin
    ↓
├── Gemini (6 Google accounts, OAuth round-robin)
├── Z.ai GLM (API key, coding endpoint)
├── Groq (API key, direct)
├── Mercury (API key, direct)
├── OpenRouter (API key, free tier models)
└── Qwen: qwen-code-oai-proxy (localhost:8090) → Qwen OAuth
```

**Why separate:** CLIProxyAPI is a Go service handling OAuth lifecycle, process management, and account rotation. qwen-code-oai-proxy is a Node.js bridge for Qwen's OAuth. PAL is the Python application layer. Each does fundamentally different work in a different language.

**What v2 changes:** PAL should treat CLIProxyAPI as a black box. Support a "proxy-only" mode where all model access routes through the custom provider — no need to register and then block native providers with hacks like `GOOGLE_ALLOWED_MODELS=_blocked`.

## Available Models (Current State)

### Tier 1 — Strong Reasoning (Plan Reviews, Architecture, Complex Code)

| Model | Provider | Status | Cost | Context | Notes |
|-------|----------|--------|------|---------|-------|
| `g25-pro` | Gemini 2.5 Pro via CLIProxyAPI | **Intermittent** — Google service bug | OAuth (free) | 1M | 6 accounts provisioned; blocked by Google-side bug as of 2026-03-28 |
| `glm-5` | GLM-5 via Z.ai Coding Pro | **Working** | $30/month (quarterly) | 131K | Coding endpoint: `api.z.ai/api/coding/paas/v4`. Strong — on par with top models |
| `glm-5-turbo` | GLM-5 Turbo via Z.ai | **Working** | Included in plan | 131K | Faster variant |

### Tier 2 — Good All-Round (Code Review, General Tasks)

| Model | Provider | Status | Cost | Context | Notes |
|-------|----------|--------|------|---------|-------|
| `gemini-flash` | Gemini 2.5 Flash via CLIProxyAPI | **Working** | OAuth (free) | 1M | Reliable, shares accounts with Pro |
| `groq-qwen` | Qwen3 32B via Groq | **Working** | Free | 32K | Fast reasoning with thinking mode |
| `groq-llama` | Llama 3.3 70B via Groq | **Working** | Free | 32K | Fast, good for reviews |

### Tier 3 — Speed (Drafting, Simple Tasks, Quick Checks)

| Model | Provider | Status | Cost | Context | Notes |
|-------|----------|--------|------|---------|-------|
| `groq-fast` | Llama 3.1 8B via Groq | **Working** | Free | 32K | Trivial tasks only |
| `mercury` | Mercury 2 via Inception Labs | **Working** | API key | — | ~1000 t/s bulk drafting |

### Tier 4 — Currently Down

| Model | Provider | Issue |
|-------|----------|-------|
| `qwen3-coder-plus` | Qwen OAuth | Free quota exhausted daily despite minimal usage |
| `deepseek-r1` | OpenRouter free | Timeout/no response |
| `qwen3-235b` | OpenRouter free | Timeout/no response |

### Local Models (Available via Ollama)

M4 Max with 64GB RAM. Ollama installed.

| Model | Size | Potential |
|-------|------|-----------|
| `llama3.3:70b` | 42 GB | Strong general reasoning |
| `qwen2:72b-instruct` | 41 GB | Strong coder |
| `qwen3-coder:30b` | 18 GB | Code-focused, faster |
| `gemma2:27b` | 15 GB | Mid-tier reviewer |

## Consensus Model Design

### Principles

- **All agents get the same brief** — no differentiated stances (for/against/neutral). Every reviewer sees identical instructions and reviews independently
- **The managing agent compiles results** — presents a consensus table showing what each reviewer flagged, with agreement indicators
- **Configurable panels** — the user defines how many models and which ones, not hardcoded patterns

### Consensus Tiers

| Review Type | Panel Size | Suggested Models | Use Case |
|-------------|-----------|-----------------|----------|
| Quick review | 2 | `gemini-flash` + `groq-llama` | Fast sanity check |
| Standard review | 3 | `glm-5` + `gemini-flash` + `groq-qwen` | Code review, plan review |
| Deep review | 3-5 | `glm-5` + `g25-pro` + `gemini-flash` + local `llama3.3:70b` | Architecture decisions, security audits |
| SEO review | 3 | Models + SEO skill context | Content and site reviews |

### Consensus Output Format

The managing agent (Claude or whichever orchestrator) should present results as:

| Finding | Reviewer 1 | Reviewer 2 | Reviewer 3 | Agreement |
|---------|-----------|-----------|-----------|-----------|
| Issue X | Flagged | Flagged | Not flagged | 2/3 |
| Issue Y | Flagged | Flagged | Flagged | 3/3 (high confidence) |

Items flagged by all reviewers are high confidence. Items flagged by one may be noise.

### Consensus + Claude Agents

The system should support hybrid consensus where:
- Some reviewers are external models via PAL
- Some reviewers are Claude sub-agents
- The orchestrator doesn't share responses between reviewers (blinded)
- Results are compiled into the same consensus table format

## Model Routing (Confirmed)

| Priority | Model | When |
|----------|-------|------|
| Primary | `g25-pro` | Default — strongest free model when available |
| Secondary | `glm-4.5` / `glm-4.6v` | Fallback when Gemini Pro is down; high concurrency (10 each), paid plan with plenty of credits |
| Tertiary | `gemini-flash` | 1M context tasks, or when both Pro and GLM unavailable |
| Complex | `glm-5` | Complex single reasoning tasks only (2 concurrency limit) |
| Speed | `groq-llama` / `groq-qwen` | Fast tier, quick checks |

### Default Consensus Panel

`glm-4.5` + `glm-4.6v` + `gemini-flash` — model diversity, all working, high concurrency. When `g25-pro` is available, swap one GLM for it.

### GLM Models on Coding Pro Plan

Only certain models are available on the coding endpoint. Tested 2026-03-28:

| Model | Coding Endpoint | Concurrency |
|-------|----------------|-------------|
| `glm-4.5` | Works | 10 |
| `glm-4.5v` | Works | 10 |
| `glm-4.6v` | Works | 10 |
| `glm-5` | Works | 2 |
| `glm-4.7` | Works | 2 |
| `glm-5-turbo` | Works | 1 |
| `glm-4-plus` | Not on coding plan | — |

## What to Keep from v1

All three architecture reviewers agreed on these keepers:

| Component | Why |
|-----------|-----|
| `ModelCapabilities` dataclass | Clean, well-typed, drives routing + budgeting |
| `OpenAICompatibleProvider` base | Battle-tested (SSRF protection, proxy suppression, dual-endpoint, 429 classification) |
| `ModelRestrictionService` | Simple allowlist model, effective |
| `TokenAllocation` / `ModelContext` | Well-designed token budgeting |
| JSON-manifest registry pattern | Externalized config, no code changes to add models |
| Retry logic with progressive delays | 1s, 3s, 5s, 8s — tuned through real production issues |
| Provider priority ordering | Explicit, clear semantics |
| Tool-disable mechanism | Simple, correct |

### Specific Code Worth Direct Transplant

- `OpenAICompatibleProvider._is_error_retryable()` — nuanced 429 handling
- `ModelCapabilities.get_effective_capability_rank()` — intelligent model scoring
- Conversation memory threading (continuation_id based stateless-to-stateful bridging)
- Blinded consensus model pattern (prevents cross-contamination between model responses)

## What to Eliminate

| Component | Why |
|-----------|-----|
| `server.py` god-class (800+ lines) | Mixes logging, provider registration, tool dispatch, config |
| `BaseTool` bloat (400+ lines) | 4 subsystems jammed into one base class |
| Three overlapping alias caches | CustomProvider, OpenAICompatible, RestrictionService all cache separately |
| Three identical temperature constants (all `1.0`) | Meaningless distinctions |
| Singleton `ModelProviderRegistry` | Hidden global state, harder testing |
| `PROMPT_TEMPLATES` dict in server.py | Duplicates tool metadata |
| Provider config block in server.py (220 lines) | Violates open-closed principle |
| `build/` directory (duplicate source) | ~50K lines of drift risk |
| `PAL_MCP_FORCE_ENV_OVERRIDE` workaround | Design smell — env vars shouldn't be silently ignored |
| `GOOGLE_ALLOWED_MODELS=_blocked` hack | Workaround, not a design choice |

## What to Add

| Capability | Priority | Why |
|-----------|----------|-----|
| Provider health monitoring | High | Track success/failure/latency, circuit breaker pattern, auto-failover |
| Per-provider rate limiting | High | Token bucket with adaptive rates, not hardcoded delays |
| Structured error types | High | `ProviderError`, `RateLimitError`, `ModelNotFoundError` — no more string parsing |
| Startup config validation | High | Fail fast with clear errors, not silent misconfiguration |
| Provider self-registration | Medium | Declarative config on each provider class, no editing server.py |
| Centralized `ModelResolver` | Medium | One service, one cache, one resolution path for aliases |
| Async-first providers | Medium | Use `AsyncOpenAI` client, not sync |
| Structured observability | Medium | Request tracing, latency, token usage as structured JSON events |
| CLI mode | Medium | Expose as both MCP server and CLI tool (investigate mcp-to-cli bridges) |
| Agent-to-agent chat | Low | Design for it, implement later |
| Config protection | High | `~/.claude.json` must not be wipeable by upstream scripts |

## Config Architecture (v2)

The current config fragility is unacceptable. `run-server.sh` from the upstream PAL fork wiped `~/.claude.json` env vars during this session, breaking all PAL routing.

### v2 Config Rules

- PAL config lives in a **single, version-controlled file** — not scattered across `~/.claude.json` env vars, `config.py`, `custom_models.json`, and `cliproxyapi.conf`
- The MCP server reads its own config file at startup — it does not depend on env vars passed by the host
- `~/.claude.json` should contain only the server command and path — not provider keys or routing config
- A startup validation step checks all config and reports issues before accepting requests

## Spectri Integration Surface

- Spectri users can opt into multi-model consensus via config
- `/spec.implement` could optionally route through consensus review before committing
- Code reviews triggered by Spectri workflows use configurable consensus panels
- The Spectri Claude Plugin could expose consensus as a UI feature

## Gemini Rate Limit Investigation (2026-03-28)

### Findings

- 429 `RESOURCE_EXHAUSTED` with `RATE_LIMIT_EXCEEDED` on `cloudcode-pa.googleapis.com`
- `quotaResetDelay: 0s` — this is a **hard capacity cap**, not time-based
- Tested with 6 accounts across 4 orgs — all fail
- Tested with fresh account that never made a request — fails
- Tested through Mullvad VPN (different IP) — fails
- `gemini-flash` works fine on same accounts
- [GitHub Issue #24004](https://github.com/google-gemini/gemini-cli/issues/24004) — confirmed Google-side bug affecting even paid users
- [GitHub Issue #23362](https://github.com/google-gemini/gemini-cli/issues/23362) — `MODEL_CAPACITY_EXHAUSTED`
- Users with OAuth login get the bug; API key login does not

### Conclusion

Google service-level bug. Will resolve when Google fixes it. Not account, org, or IP-level.

### CLIProxyAPI Auth

- `cliproxyapi -login` (NOT `gemini auth login`) — these are separate auth stores
- Choose option **2 (Google One)** during login, not option 1 (Code Assist)
- CLIProxyAPI auto-refreshes tokens every 15 minutes
- 6 accounts provisioned and active as of 2026-03-28

## GLM Integration (Completed)

- Z.ai GLM-5 working via Coding Pro plan ($90/quarter)
- **Coding endpoint**: `https://api.z.ai/api/coding/paas/v4` (NOT the general endpoint)
- Added to CLIProxyAPI config: `glm-5`, `glm-5-turbo`, `glm-4.7`
- Added to PAL `custom_models.json`
- OpenAI-compatible API format — works through CLIProxyAPI seamlessly

## Qwen Investigation

- Free tier is 1000 API calls/day but reports "insufficient quota" despite minimal usage
- Proxy logs show no significant requests
- The qwen-code-oai-proxy bridge works (models endpoint responds)
- Possible causes: background health checks consuming quota, or Qwen has reduced free tier
- Multi-account support exists in the proxy but is not configured

## Implementation Approach

**"Clean-room rewrite of the frame, transplant the organs."**

| Phase | Scope |
|-------|-------|
| 1 | New repo with Spectri. New skeleton server (<200 lines). Pydantic settings replacing scattered config. Import proven provider layer. |
| 2 | Rebuild tools on a slim base. Consensus as a first-class multi-model tool. Model resolver centralised. |
| 3 | Health monitoring, rate limiting, structured observability. |
| 4 | CLI mode, Spectri integration, agent-to-agent capabilities. |

## v1 Fixes Applied (2026-03-28)

Changes committed and pushed to `flowji-ai/pal-mcp-server` main branch:

- **Consensus inter-model delay** — 5-second configurable delay (`CONSENSUS_INTER_MODEL_DELAY` env var) between model consultations to reduce RPM burst. 868 tests passing, no regressions. Commit `e733ac0`.
- **PAL env vars restored** in `~/.claude.json` after `run-server.sh` wiped them
- **`.claude.json` backup** created in agent-deck canonical config

## Skill Updates Applied (2026-03-28)

Updated `pal-delegation` skill (canonical source in agent-deck, synced to `~/.claude/skills/`):

- All `gemini auth login` references changed to `cliproxyapi -login`
- Account list expanded from 3 to 6
- Warning about separate auth stores (CLIProxyAPI vs Gemini CLI)
- CLIProxyAPI `-login` workflow documented (choose option 2: Google One)
- Auto-refresh interval (15 min) documented
- GLM needs to be added to the skill as a provider

## Groq Qwen vs Qwen Coder Plus

These are frequently confused but are different models:

| | `qwen3-coder-plus` | `groq-qwen` |
|---|---|---|
| Model | Qwen3 Coder Plus (full) | Qwen3 32B |
| Infra | Qwen OAuth → localhost:8090 → CLIProxyAPI | Groq API (direct) |
| Context | 131K | 32K |
| Speed | Moderate | ~800 t/s |
| Strength | Code-specialized, larger | Fast reasoning, smaller |

## Design Preferences (From User)

- **No stances in consensus** — no for/against/neutral differentiation. All reviewers get identical briefs
- **Build our own tools** — don't preserve PAL's built-in consensus/codereview patterns. Design our own workflow from scratch
- **Multi-level reviews** — simple code review, complex code review, plan review, SEO review (using SEO skill), architecture review
- **Hybrid consensus** — some reviewers via PAL external models, some via Claude sub-agents, compiled into one table
- **MCP + CLI** — investigate running as both MCP server and standalone CLI tool
- **Local model support** — reduce reliance on cloud models, use Ollama for some tasks
- **Agent-to-agent chat** — design for this capability even if built later
- **Config cannot be fragile** — the `~/.claude.json` wipe incident must never happen again. Config should be self-contained and version-controlled
- **GLM as a primary model** — $30/month with plenty of credits, should be maxed out
- **Commit early and often** — agents must checkpoint at milestones (this session failed to do so)

## Gemini Account Provisioning

6 accounts active in CLIProxyAPI as of 2026-03-28:

| Account | Org | GCP Project |
|---------|-----|-------------|
| `ananda.ostii@gmail.com` | gmail.com | poetic-dreamer-p2v8s |
| `ostii@flowji.com` | flowji.com | flash-apparatus-wh8fn |
| `ostii@holmgren.com.au` | holmgren.com.au | ambient-cave-2r6pj |
| `admin@holmgren.com.au` | holmgren.com.au | key-willow-jq922 |
| `accounts@holmgren.com.au` | holmgren.com.au | steel-amplifier-7wnhv |
| `beekeepingnaturally@gmail.com` | gmail.com | fit-wall-mwnhv |

User has capacity for 10 accounts within existing Google Workspace orgs.

## Rate Limit Mitigation Brainstorm (From Qwen Coder Plus)

Top recommendations from model brainstorm session:

1. **Adaptive token bucket** at PAL level — track success/failure ratios, adjust burst rates dynamically
2. **Request queue with priority** — model-specific queues that hold requests rather than failing them
3. **Smart failover** — auto-fallback to `gemini-flash` after consecutive 429s, return to primary when limits clear
4. **Predictive rate limit detection** — monitor patterns, preemptively throttle before saturation
5. **Account-level state management** — track individual account utilisation, prefer accounts with lower recent usage

## Open Questions

- Can we use GitHub Copilot credits via CLIProxyAPI's codex-login?
- Should local Ollama models be routed through CLIProxyAPI or directly from PAL?
- What MCP-to-CLI bridge tools exist and would they work for this?
- How does agent-to-agent chat work architecturally — is it a PAL feature or a separate service?
- Should consensus be managed inside the MCP server or by the orchestrating agent?
- What is the actual Qwen free tier daily limit, and why does it exhaust with minimal usage?
- Google AI Pro ($19.99/month) — worth it once the 429 bug is fixed?
- How to prevent upstream scripts from wiping `~/.claude.json` config?
