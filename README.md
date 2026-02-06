# PlayCamp SDK - Claude Code Agents

**English** | [한국어](README.ko.md)

AI agents for automating PlayCamp SDK API and Node SDK integration.

## Supported Categories

| Category | Status | Agents |
|----------|--------|--------|
| **Node SDK** | Production | 5 agents |
| **API** | Production | 1 agent |

## Quick Start

### Install All Agents (current project)
```bash
cd your-game-server
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh)
```

### Install Options
```bash
# Install to current project (default)
bash <(curl -fsSL ...) --local

# Install globally (~/.claude/agents/)
bash <(curl -fsSL ...) --global

# Install specific category only
bash <(curl -fsSL ...) --platform=node  # Node SDK agents only
bash <(curl -fsSL ...) --platform=api   # API agents only
```

### Uninstall
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --uninstall
```

### Use Agents
```bash
cd your-game-server
claude
"Use @agent-playcamp-integrator to integrate PlayCamp SDK"
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

## Workflows

### New Node SDK Integration
```
integrator → webhook-specialist → auditor → test-verifier
```

### Direct HTTP Integration (non-Node.js)
```
api-guide
```

### Migration from Raw HTTP
```
migration-assistant → auditor → test-verifier
```

## Key Features

- Fast Integration - Automated Node SDK setup
- Multi-Language Support - Direct HTTP API guide for non-Node.js languages
- Security Validation - API key exposure checks, webhook signature verification
- Build Verification - TypeScript compilation + environment config validation

## Resources

- **Issues**: https://github.com/PlayCamp/playcamp-sdk-agents/issues
- **Claude Code**: https://claude.ai/code
