# PlayCamp SDK - Claude Code Agents

**English** | [한국어](README.ko.md)

AI agents for automating PlayCamp SDK integration (Node.js, Go, and direct HTTP API).

## Supported Categories

| Category | Status | Agent |
|----------|--------|-------|
| **Node SDK** | Production | `@agent-playcamp-node` |
| **Go SDK** | Production | `@agent-playcamp-go` |
| **API** | Production | `@agent-playcamp-api` |

> One all-in-one agent per language. Each agent covers the full integration lifecycle — setup, mandatory APIs, playtime/webview, webhooks, raw-HTTP migration, code audit, and build verification.

## Quick Start

### 1. Install

```bash
cd your-game-server
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh)
```

### 2. Launch Claude Code

```bash
claude
```

### 3. Ask

```
Integrate PlayCamp SDK with sponsor, coupon, and payment APIs
```

That's it. The agent will automatically set up the SDK, implement the required APIs, and configure error handling.

## Install Options

```bash
# Install to current project (default)
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh)

# Install globally (~/.claude/agents/)
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --global

# Install specific category only
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --platform=node
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --platform=go
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --platform=api

# Uninstall (removes agents + routing rules from CLAUDE.md)
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --uninstall
```

## Agents

Each agent is a single, comprehensive agent that handles every role for its language. Just describe what you need — the agent picks the right mode (integrate / webhook / migrate / audit / verify).

### `@agent-playcamp-node` — Node SDK (`@playcamp/node-sdk`)
Setup & client init · mandatory APIs (sponsor/coupon/payment) · playtime sessions · bulk payments · WebView OTT · webhook reception & signature verification · raw HTTP → SDK migration · code audit · build & config verification.

### `@agent-playcamp-go` — Go SDK (`github.com/playcamp/playcamp-go-sdk`)
Same coverage as the Node agent, with Go idioms — `errors.As()`, `context.Context`, pointer helpers, `webhookutil` signature verification, `go build`/`go vet` verification.

### `@agent-playcamp-api` — Direct HTTP API
For non-SDK languages (Python, Java, C#, PHP, Ruby, curl). Endpoint docs, Bearer auth, request/response examples, webhook verification, error handling.

## Usage Examples

### Node.js

```
Set up PlayCamp SDK in my Express server with payment, coupon, and sponsor endpoints
```

```
Add PlayCamp webhook handling with signature verification to my server
```

```
Record sponsored players' playtime sessions with PlayCamp
```

```
Review my PlayCamp integration for security issues, then verify the build
```

### Go

```
Integrate PlayCamp Go SDK into my game server with sponsor, coupon, and payment APIs
```

```
Set up PlayCamp webhook handling with webhookutil signature verification in my Go server
```

### Direct API (non-SDK languages)

```
Show me how to integrate PlayCamp payment API in Python
```

```
Set up PlayCamp sponsor and coupon APIs in my Java server
```

### Migration

```
Migrate my raw fetch() calls to PlayCamp Node SDK methods
```

```
Migrate my raw net/http calls to PlayCamp Go SDK methods
```

### Explicit Agent Invocation

You can also call the agent directly by name:

```
Use @agent-playcamp-node to integrate PlayCamp SDK with server key configuration
```

```
Use @agent-playcamp-go to set up webhook endpoints and verify the build
```

## Workflow

A typical end-to-end integration with a single agent:

```
1. "Integrate PlayCamp SDK with sponsor, coupon, and payment APIs"   → setup + mandatory APIs
2. "Add webhook handling with signature verification"                → webhook reception
3. "Audit the integration for correctness and security"             → code review (read-only)
4. "Verify the build and environment configuration"                 → build/config verification
```

The same agent handles each step — no hand-off between separate agents required. For migrations, start with *"Migrate my raw HTTP calls to the PlayCamp SDK"* and follow with the audit + verify steps.

## How It Works

The installer adds the agent file to `.claude/agents/` and appends routing rules to your project's `CLAUDE.md`. When you ask Claude Code about PlayCamp integration, the routing rules automatically delegate to the correct language agent.

```
User: "Add PlayCamp payment processing"
  → Claude reads CLAUDE.md routing rules
    → Delegates to @agent-playcamp-node (or -go / -api)
      → Agent implements payment API with SDK
```

## Key Features

- **One agent per language** - No juggling five specialists; one agent covers the whole lifecycle
- **Automated Setup** - SDK installation, client initialization, environment configuration
- **Mandatory + extended APIs** - Sponsor, coupon, payment, plus playtime sessions, bulk payments, and WebView OTT
- **Node + Go SDKs** - Full coverage for both official SDKs (v0.0.8)
- **Multi-Language** - Direct HTTP API guide for Python, Java, C#, PHP, and more
- **Security** - API key exposure checks, webhook signature verification (7 event types), error handling
- **Build Verification** - TypeScript/Go compilation and environment config validation
- **Official Docs** - Agents reference [PlayCamp documentation](https://playcamp.io/docs/guides/developers/game-integration/overview) for latest API specs

## Resources

- **PlayCamp Docs**: https://playcamp.io/docs/guides/developers/game-integration/overview
- **API Reference**: https://playcamp.io/docs/guides/developers/game-integration/reference
- **Issues**: https://github.com/PlayCamp/playcamp-sdk-agents/issues
- **Claude Code**: https://claude.ai/code
