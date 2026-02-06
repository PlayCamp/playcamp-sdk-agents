# PlayCamp SDK - Claude Code Agents

**English** | [한국어](README.ko.md)

AI agents for automating PlayCamp SDK API and Node SDK integration.

## Supported Categories

| Category | Status | Agents |
|----------|--------|--------|
| **Node SDK** | Production | 5 agents |
| **API** | Production | 1 agent |

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
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --platform=api

# Uninstall (removes agents + routing rules from CLAUDE.md)
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --uninstall
```

## Agents

### Node SDK Agents (5)
- **@agent-playcamp-integrator** - SDK setup + mandatory API integration
- **@agent-playcamp-auditor** - Integration code review and validation
- **@agent-playcamp-webhook-specialist** - Webhook endpoint setup
- **@agent-playcamp-migration-assistant** - Raw HTTP → SDK migration
- **@agent-playcamp-test-verifier** - Build and config verification

### API Agents (1)
- **@agent-playcamp-api-guide** - Direct HTTP API integration guide

## Usage Examples

### New Integration (Node.js)

```
Set up PlayCamp SDK in my Express server with payment, coupon, and sponsor endpoints
```

```
Add PlayCamp webhook handling with signature verification to my server
```

```
Review my PlayCamp integration for security issues and best practices
```

```
Verify my PlayCamp SDK build and environment configuration
```

### Direct API Integration (non-Node.js)

```
Show me how to integrate PlayCamp payment API in Python
```

```
Set up PlayCamp sponsor and coupon APIs in my Go server
```

### Migration

```
Migrate my raw fetch() calls to PlayCamp SDK methods
```

### Explicit Agent Invocation

You can also call agents directly by name:

```
Use @agent-playcamp-integrator to integrate PlayCamp SDK with server key configuration
```

```
Use @agent-playcamp-webhook-specialist to set up webhook endpoints
```

```
Use @agent-playcamp-auditor to review my PlayCamp integration
```

## Workflows

### New Node SDK Integration
```
integrator → webhook-specialist → auditor → test-verifier
```
1. **integrator** installs SDK, initializes clients, implements mandatory APIs
2. **webhook-specialist** configures webhook endpoints and signature verification
3. **auditor** reviews full integration for correctness and security
4. **test-verifier** validates build, config, and environment setup

### Direct HTTP Integration (non-Node.js)
```
api-guide
```
1. **api-guide** provides HTTP endpoints, auth headers, request/response formats, and webhook verification examples for any language

### Migration from Raw HTTP
```
migration-assistant → auditor → test-verifier
```
1. **migration-assistant** converts fetch/axios calls to SDK methods
2. **auditor** validates migration completeness and correctness
3. **test-verifier** verifies build and configuration

## How It Works

The installer adds agent files to `.claude/agents/` and appends routing rules to your project's `CLAUDE.md`. When you ask Claude Code about PlayCamp integration, the routing rules automatically delegate to the correct specialized agent.

```
User: "Add PlayCamp payment processing"
  → Claude reads CLAUDE.md routing rules
    → Delegates to @agent-playcamp-integrator
      → Agent implements payment API with SDK
```

## Key Features

- **Automated Setup** - SDK installation, client initialization, environment configuration
- **3 Mandatory APIs** - Sponsor, coupon, and payment integration out of the box
- **Multi-Language** - Direct HTTP API guide for Python, Go, Java, C#, PHP, and more
- **Security** - API key exposure checks, webhook signature verification, error handling
- **Build Verification** - TypeScript compilation and environment config validation
- **Official Docs** - Agents reference [PlayCamp documentation](https://playcamp.io/docs/guides/developers/game-integration/overview) for latest API specs

## Resources

- **PlayCamp Docs**: https://playcamp.io/docs/guides/developers/game-integration/overview
- **API Reference**: https://playcamp.io/docs/guides/developers/game-integration/reference
- **Issues**: https://github.com/PlayCamp/playcamp-sdk-agents/issues
- **Claude Code**: https://claude.ai/code
