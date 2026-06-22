# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains specialized Claude Code agents for automating PlayCamp SDK integration into game servers. The agents help game publishers integrate the PlayCamp Node SDK (`@playcamp/node-sdk`) and Go SDK (`github.com/playcamp/playcamp-go-sdk`) for sponsor management, coupon validation, payment processing, playtime tracking, and WebView token issuance, reducing game server integration time significantly.

**3 agents, one per language/platform** (Node SDK, Go SDK, and direct HTTP API). Each agent is an all-in-one agent covering the full integration lifecycle — setup, mandatory + extended APIs, webhooks, raw-HTTP migration, code audit, and build verification.

> **History:** This repo previously had 11 role-split agents (integrator / auditor / webhook-specialist / migration-assistant / test-verifier, ×Node/Go, + api-guide). On 2026-06-22 they were consolidated to 3 language agents to eliminate Node/Go content duplication and the resulting sync drift. The role distinctions now live as **mode sections** inside each agent file.

## Architecture Overview

### Agent System

```
User/Main Agent (Coordinator)
    │
    ├──► @agent-playcamp-node   (Node SDK — all roles)
    ├──► @agent-playcamp-go     (Go SDK — all roles)
    └──► @agent-playcamp-api    (Direct HTTP API — non-SDK languages)
```

Each language agent internally covers these **modes**:

| Mode | What it does |
|------|--------------|
| Integrate | SDK install, client init, mandatory + extended APIs |
| Webhooks | Endpoint setup, signature verification, batch event handling |
| Migrate | Raw HTTP (fetch/axios/net/http/resty) → SDK methods |
| Audit | Read-only code review for correctness, security, best practices |
| Verify | Build/compile, dependency, and environment-config checks |

**Agent Definitions**: All agents are defined as markdown files in `.claude/agents/<category>/` with frontmatter:
- `name`: Agent identifier (e.g., `playcamp-node`) that maps to invocation `@agent-playcamp-node`
- `description`: When to invoke (critical for auto-routing; includes "Use proactively")
- `tools`: `Read, Write, Edit, Bash, Grep, Glob`
- `model`: `sonnet`
- `color`: UI color (node=blue, go=cyan, api=orange)

> **Subdirectories are organizational only.** Claude Code scans `.claude/agents/` recursively; the folder path (`node/`, `go/`, `api/`) does NOT affect the agent's identity or invocation — only the `name` field does. (Verified against the official Claude Code subagent spec, 2026-06.)

### Key Components

1. **Agent Files** (`.claude/agents/<category>/`)
   - `node/playcamp-node.md` → `@agent-playcamp-node`
   - `go/playcamp-go.md` → `@agent-playcamp-go`
   - `api/playcamp-api.md` → `@agent-playcamp-api`

2. **Scripts** (`scripts/`)
   - `install.sh` — installs agents globally or locally, injects/removes CLAUDE.md routing rules

3. **SDK Version Tracking** (`SDK_VERSION.yaml`)
   - Tracks the SDK version (currently **0.0.8**) the agents are synchronized with
   - Documents mandatory + additional APIs, webhook events, resource surface, and error hierarchy

## Recommended Workflow

A full integration runs through one agent, switching modes as you ask:

```
1. "Integrate PlayCamp SDK with sponsor, coupon, payment APIs"   → Integrate
2. "Add webhook handling with signature verification"            → Webhooks
3. "Audit the integration for correctness and security"          → Audit (read-only)
4. "Verify the build and environment configuration"              → Verify
```

- **Node** → `@agent-playcamp-node` for all four steps
- **Go** → `@agent-playcamp-go` for all four steps
- **Migration** → start with "Migrate my raw HTTP calls to the PlayCamp SDK", then Audit + Verify
- **Non-SDK languages (Python/Java/C#/PHP/curl)** → `@agent-playcamp-api`

## PlayCamp SDK Quick Reference

### Node SDK
- **Package**: `@playcamp/node-sdk` (v0.0.8)
- **Two clients**:
  - `PlayCampClient` — Read-only operations, uses CLIENT key
  - `PlayCampServer` — Read/write operations, uses SERVER key

### Go SDK
- **Module**: `github.com/playcamp/playcamp-go-sdk` (Go 1.21+, v0.0.8)
- **Two clients**:
  - `playcamp.NewClient()` — Read-only operations, uses CLIENT key
  - `playcamp.NewServer()` — Read/write operations, uses SERVER key
- **Key patterns**: `errors.As()` for error handling, `context.Context` for all API calls, pointer helpers (`playcamp.String()`, `playcamp.Int()`)

### Authentication
- **Format**: `Authorization: Bearer {keyId}:{secret}`
- **Key types**: `CLIENT` (read-only), `SERVER` (read/write — must never be exposed to client-side code)

### Environments
- **Sandbox**: `https://sandbox-sdk-api.playcamp.io`
- **Live**: `https://sdk-api.playcamp.io`

### Mandatory APIs (3 required)
```
POST /v1/server/sponsors          # Create/update sponsor (upsert)
POST /v1/server/coupons/validate  # Validate coupon code
POST /v1/server/payments          # Process payment
```

### Additional APIs (optional, v0.0.6–v0.0.8)
```
POST /v1/server/payments/bulk            # Bulk payments (max 1000)
POST /v1/server/playtime/sessions        # Playtime session (single)        [added v0.0.7]
POST /v1/server/playtime/sessions/bulk   # Playtime sessions (bulk, max 1000) [added v0.0.7]
POST /v1/server/webview/ott              # WebView one-time token (OTT)      [added v0.0.6]
```

### Resource Surface
- **Server** (`PlayCampServer` / `playcamp.NewServer()`): `campaigns, creators, coupons, sponsors, payments, playtimeSessions, webhooks, webview`
- **Client** (`PlayCampClient` / `playcamp.NewClient()`, read-only): `campaigns, creators, coupons, sponsors`

### Error Hierarchy
```
PlayCampError (base)
├── PlayCampApiError
│   ├── PlayCampAuthError (401)
│   ├── PlayCampForbiddenError (403)
│   ├── PlayCampNotFoundError (404)
│   ├── PlayCampConflictError (409)
│   ├── PlayCampValidationError (422)
│   └── PlayCampRateLimitError (429)
├── PlayCampInputValidationError
└── PlayCampNetworkError
```

### Webhook Events (7)
- `coupon.redeemed`
- `payment.created`
- `payment.refunded`
- `payment.bulk_created`   <!-- added with bulk payments -->
- `sponsor.created`
- `sponsor.changed`
- `sponsor.ended`          <!-- added -->

### Distribution Types
- `MOBILE_STORE` — 30% store fee
- `PC_STORE` — 30% store fee
- `MOBILE_SELF_STORE` — 0% store fee
- `PC_SELF_STORE` — 0% store fee

### Platforms
`iOS` · `Android` · `Web` · `Roblox` · `Other`

## Agent Invocation Patterns

**Explicit (Recommended)**:
```
Use @agent-playcamp-node to integrate PlayCamp SDK into my Express server
Use @agent-playcamp-go to set up webhooks and verify the build
```

**Implicit (Auto-routing)** — Claude routes by the project language and the agent `description`:
```
Set up PlayCamp payment processing in my Node.js app      → @agent-playcamp-node
Integrate PlayCamp Go SDK into my game server             → @agent-playcamp-go
Show me PlayCamp coupon API in Python                      → @agent-playcamp-api
```

## SDK Version Synchronization

The agents must stay synchronized with PlayCamp SDK public APIs. When SDK version changes:

1. Update `SDK_VERSION.yaml` (`version`, `last_verified`, APIs, webhook events, resources)
2. Update the affected agent file(s) with new API names/signatures and code examples
3. Test agents against real Node.js / Go server projects
4. Update `agents_last_updated` in `SDK_VERSION.yaml`

> Reference SDK source lives in the workspace at `../playcamp-sdk-libs` (`playcamp-node-sdk`, `playcamp-go-sdk`) with a `CHANGELOG.md` — the authoritative source for version diffs.

## Common Pitfalls

### Integration (Node)
1. **Webhook raw body**: Use `express.raw()` (not `express.json()`) on the webhook route to preserve the raw body for signature verification.
2. **distributionType is required**: Payments fail without a valid `distributionType`.
3. **transactionId must be unique**: Duplicates return 409 Conflict.
4. **Coupon codes are case-insensitive**: Auto-uppercased by the API.
5. **POST /sponsors is upsert**: No separate create/update endpoints.
6. **campaignId is optional**: If omitted, the active campaign is auto-attributed.
7. **isTest flag**: Never hardcode `true` in production — use env config.
8. **SERVER key exposure**: Never expose the SERVER key to client-side code.

### Integration (Go)
1. **Error handling with `errors.As()`**: Use `errors.As()`, not type assertions.
2. **`context.Context` required**: All SDK API calls take `context.Context` as the first parameter.
3. **Webhook raw body**: Use `io.ReadAll(r.Body)` before any JSON parsing.
4. **Pointer helpers**: Use `playcamp.String()`, `playcamp.Int()`, etc. for optional fields.
5. **isTest from env**: `os.Getenv("SDK_TEST_MODE") == "true"`, never hardcode `true`.

### Playtime Sessions (Node + Go)
1. **`endedAt >= startedAt`** and **`durationSeconds >= 1`** — both SDKs pre-validate client-side.
2. **Idempotency**: `projectId + sessionId` is UNIQUE. A duplicate `sessionId` is NOT an error — single returns `recorded: false`, bulk returns `status: "SKIPPED"`.
3. **`creatorKey`**: optional, but if provided must be exactly 5 uppercase alphanumeric chars (`[A-Z0-9]{5}`).
4. **Bulk cap**: max 1000 sessions per `createBulk` / `CreateBulk` call. Same cap for bulk payments.
5. **Timestamps**: Node auto-serializes `Date` → ISO8601; Go normalizes `time.Time` → UTC → RFC3339.

### Webhooks
1. **Missing raw body middleware**: signature verification needs the unparsed body.
2. **Batch events**: webhook payloads contain **arrays** of events, not single events.
3. **Handle all subscribed event types** — including the newer `payment.bulk_created` and `sponsor.ended`.

### Error Handling
1. **Catch specific error types** using the error hierarchy.
2. **Retry on rate limits** (429) with exponential backoff.
3. **`PlayCampNetworkError`** indicates connectivity issues, not API rejection.

## Development Commands

### Installation
```bash
bash scripts/install.sh                  # all agents, local (default)
bash scripts/install.sh --global         # all agents, global
bash scripts/install.sh --platform=node  # node agent only
bash scripts/install.sh --platform=go    # go agent only
bash scripts/install.sh --platform=api   # api agent only
bash scripts/install.sh --uninstall      # remove agents + routing rules
```

### Testing Agents
```bash
cd /path/to/server && claude

# Node
"Use @agent-playcamp-node to integrate PlayCamp SDK with server key: test-key"
"Use @agent-playcamp-node to set up webhook endpoints, then audit and verify"

# Go
"Use @agent-playcamp-go to integrate PlayCamp Go SDK into my server"
"Use @agent-playcamp-go to migrate my raw net/http calls to the Go SDK"

# Direct HTTP (non-SDK languages)
"Use @agent-playcamp-api to integrate PlayCamp payment API in Python"
```

## Agent Development Guidelines

### When Modifying Agents
1. **Maintain API Accuracy**: All code examples must match the SDK version in `SDK_VERSION.yaml`.
2. **Test Against Real Projects**: Validate changes with actual Node.js / Go server apps.
3. **Update Documentation**: Keep agent files, `README.md`, and `README.ko.md` in sync.
4. **Version Tracking**: Update `SDK_VERSION.yaml` when the SDK version changes.
5. **Keep mode sections complete**: Each agent must retain all five modes (Integrate / Webhooks / Migrate / Audit / Verify).

## File Structure Reference

```
playcamp-sdk-agents/
├── .claude/
│   └── agents/
│       ├── node/
│       │   └── playcamp-node.md     # @agent-playcamp-node (Node SDK, all roles)
│       ├── go/
│       │   └── playcamp-go.md       # @agent-playcamp-go (Go SDK, all roles)
│       └── api/
│           └── playcamp-api.md      # @agent-playcamp-api (direct HTTP API)
├── scripts/
│   └── install.sh                   # Agent installer
├── SDK_VERSION.yaml                 # SDK version tracking
├── CLAUDE.md                        # This file
├── README.md                        # Quick start guide (English)
├── README.ko.md                     # Quick start guide (Korean)
└── LICENSE                          # MIT License
```
