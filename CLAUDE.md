# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains specialized Claude Code agents for automating PlayCamp SDK integration into game servers. The agents help game publishers integrate the PlayCamp Node SDK (`@playcamp/node-sdk`) for sponsor management, coupon validation, and payment processing, reducing game server integration time significantly. 6 agents across 2 categories (Node SDK and API).

## Architecture Overview

### Multi-Agent System

The repository implements a specialized multi-agent architecture where each agent handles a specific aspect of PlayCamp SDK integration:

```
User/Main Agent (Coordinator)
    │
    ├──► Node SDK Agents
    │    ├── @agent-playcamp-integrator          (SDK Setup + Core Integration)
    │    ├── @agent-playcamp-auditor             (Code Review + Validation)
    │    ├── @agent-playcamp-webhook-specialist   (Webhook Setup)
    │    ├── @agent-playcamp-migration-assistant  (Raw HTTP → SDK Migration)
    │    └── @agent-playcamp-test-verifier        (Build + Config Verification)
    │
    └──► API Agents
         └── @agent-playcamp-api-guide           (Direct HTTP API Guide)
```

**Agent Definitions**: All agents are defined as markdown files in `.claude/agents/<category>/` with frontmatter specifying:
- `name`: Agent identifier (e.g., `playcamp-integrator`) that maps to Claude invocation `@agent-playcamp-integrator`
- `description`: When to invoke the agent (critical for auto-routing)
- `tools`: Available tools (Read, Write, Edit, Grep, Glob, Bash)
- `model`: Preferred model (sonnet, haiku, opus)

### Key Components

1. **Agent Files** (`.claude/agents/<category>/`)
   - **Node SDK** (`.claude/agents/node/`)
     - `playcamp-integrator.md` → `@agent-playcamp-integrator` (SDK setup, client initialization, core API integration)
     - `playcamp-auditor.md` → `@agent-playcamp-auditor` (validates integration correctness, error handling, security)
     - `playcamp-webhook-specialist.md` → `@agent-playcamp-webhook-specialist` (webhook endpoint setup, signature verification)
     - `playcamp-migration-assistant.md` → `@agent-playcamp-migration-assistant` (migrates raw HTTP calls to SDK methods)
     - `playcamp-test-verifier.md` → `@agent-playcamp-test-verifier` (build verification, config validation, env checks)
   - **API** (`.claude/agents/api/`)
     - `playcamp-api-guide.md` → `@agent-playcamp-api-guide` (direct HTTP API integration for non-Node.js)

2. **Scripts** (`scripts/`)
   - `install.sh` - Installs agents globally or locally

3. **SDK Version Tracking** (`SDK_VERSION.yaml`)
   - Tracks which PlayCamp SDK version the agents are synchronized with
   - Documents mandatory APIs, webhook events, and error hierarchy
   - Lists distribution types and auth configuration

## Recommended Workflows

### New Node SDK Integration
```
integrator → webhook-specialist → auditor → test-verifier
```
1. `@agent-playcamp-integrator` sets up SDK, initializes clients, implements mandatory APIs
2. `@agent-playcamp-webhook-specialist` configures webhook endpoints and signature verification
3. `@agent-playcamp-auditor` reviews the full integration for correctness and security
4. `@agent-playcamp-test-verifier` validates build, config, and environment setup

### Direct HTTP Integration (non-Node.js)
```
api-guide
```
1. `@agent-playcamp-api-guide` provides HTTP endpoint details, auth headers, request/response formats, and webhook verification examples for any language (Python, Go, Java, C#, PHP, curl)

### Migration from Raw HTTP to SDK
```
migration-assistant → auditor → test-verifier
```
1. `@agent-playcamp-migration-assistant` identifies raw HTTP calls and replaces them with SDK methods
2. `@agent-playcamp-auditor` validates the migration is complete and correct
3. `@agent-playcamp-test-verifier` verifies the build and configuration

## PlayCamp SDK Quick Reference

### Package & Clients
- **Package**: `@playcamp/node-sdk`
- **Two clients**:
  - `PlayCampClient` - Read-only operations, uses CLIENT key
  - `PlayCampServer` - Read/write operations, uses SERVER key

### Authentication
- **Format**: `Authorization: Bearer {keyId}:{secret}`
- **Key types**:
  - `CLIENT` - Read-only access
  - `SERVER` - Read/write access (must never be exposed to client-side code)

### Environments
- **Sandbox**: `https://sandbox-sdk-api.playcamp.dev`
- **Live**: `https://sdk-api.playcamp.dev`

### Mandatory APIs (3 required)
```
POST /v1/server/sponsors          # Create/update sponsor (upsert)
POST /v1/server/coupons/validate  # Validate coupon code
POST /v1/server/payments          # Process payment
```

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

### Webhook Events
- `coupon.redeemed`
- `payment.created`
- `payment.refunded`
- `sponsor.created`
- `sponsor.changed`

### Distribution Types
- `MOBILE_STORE` - 30% store fee
- `PC_STORE` - 30% store fee
- `MOBILE_SELF_STORE` - 0% store fee
- `PC_SELF_STORE` - 0% store fee

## Agent Invocation Patterns

**Explicit (Recommended)**:
```
Use @agent-playcamp-integrator to integrate PlayCamp SDK into my Express server
```

**Implicit (Auto-routing)**:
```
Set up PlayCamp payment processing in my Node.js app
→ Claude Code routes to @agent-playcamp-integrator based on description
```

```
Set up webhook endpoints for PlayCamp events
→ Claude Code routes to @agent-playcamp-webhook-specialist based on description
```

```
Migrate my raw fetch() calls to the PlayCamp SDK
→ Claude Code routes to @agent-playcamp-migration-assistant based on description
```

## Agent Coordination

**Sequential (Common)**:
```
Integrator → Webhook Specialist → Auditor → Test Verifier
```

**Iterative (Debugging)**:
```
1. Integrator makes changes
2. Test Verifier tests → FAIL
3. Integrator fixes errors
4. Test Verifier tests → PASS
5. Auditor validates → PASS
```

**Parallel (Advanced)**:
```
Auditor + Test Verifier (both read-only, no conflicts)
```

## SDK Version Synchronization

The agents must stay synchronized with PlayCamp SDK public APIs. When SDK version changes:

1. Update `SDK_VERSION.yaml` with new version information
2. Update agent files with new API names/signatures
3. Update code examples in agent files
4. Test agents against real server projects
5. Update `agents_last_updated` date in `SDK_VERSION.yaml`

## Common Pitfalls

### PlayCamp SDK Integration

1. **Webhook raw body**: Must use `express.raw()` (not `express.json()`) for the webhook endpoint to preserve the raw body needed for signature verification
2. **distributionType is required**: Payments will fail without a valid `distributionType` field
3. **transactionId must be unique**: Duplicate transaction IDs return 409 Conflict
4. **Coupon codes are case-insensitive**: Codes are auto-uppercased by the API
5. **POST /sponsors is upsert**: No separate create/update endpoints needed - single POST handles both
6. **campaignId is optional**: If omitted, the active campaign is auto-attributed
7. **isTest flag**: Must not be hardcoded `true` in production - use environment-based configuration
8. **SERVER key exposure**: SERVER key must never be exposed to client-side code - only use in server-side environments

### Webhook Setup
1. **Missing raw body middleware**: Signature verification requires the unparsed request body
2. **Wrong middleware order**: `express.raw()` must be applied before `express.json()` on the webhook route
3. **Missing event type handling**: Must handle all subscribed webhook event types

### Error Handling
1. **Not catching specific error types**: Use the error hierarchy to handle different failure modes
2. **Missing retry logic for rate limits**: 429 errors should trigger exponential backoff
3. **Ignoring network errors**: `PlayCampNetworkError` indicates connectivity issues, not API rejections

## Development Commands

### Installation
```bash
# Install agents locally to current project (default)
bash scripts/install.sh

# Install agents locally (explicit)
bash scripts/install.sh --local

# Install agents globally (available across all projects)
bash scripts/install.sh --global
```

### Testing Agents
```bash
# Navigate to a test Node.js server project
cd /path/to/node/server

# Launch Claude Code
claude

# Test integration agent
"Use @agent-playcamp-integrator to integrate PlayCamp SDK with server key: test-key"

# Test webhook specialist
"Use @agent-playcamp-webhook-specialist to set up webhook endpoints"

# Test auditor
"Use @agent-playcamp-auditor to review my PlayCamp integration"

# Test migration assistant
"Use @agent-playcamp-migration-assistant to migrate my raw HTTP calls to SDK"

# Test build verifier
"Use @agent-playcamp-test-verifier to verify my project configuration"
```

## Agent Development Guidelines

### When Modifying Agents

1. **Maintain API Accuracy**: All code examples must match SDK version in `SDK_VERSION.yaml`
2. **Test Against Real Projects**: Validate changes with actual Node.js server apps
3. **Update Documentation**: Keep agent files and README in sync with capabilities
4. **Version Tracking**: Update `SDK_VERSION.yaml` when SDK version changes

## File Structure Reference

```
playcamp-sdk-agents/
├── .claude/
│   └── agents/
│       ├── node/                    # Node SDK agent definitions
│       │   ├── playcamp-integrator.md
│       │   ├── playcamp-auditor.md
│       │   ├── playcamp-webhook-specialist.md
│       │   ├── playcamp-migration-assistant.md
│       │   └── playcamp-test-verifier.md
│       └── api/                     # API agent definitions
│           └── playcamp-api-guide.md
├── scripts/
│   └── install.sh                   # Agent installer
├── SDK_VERSION.yaml                 # SDK version tracking
├── CLAUDE.md                        # This file
├── README.md                        # Quick start guide
└── LICENSE                          # MIT License
```
