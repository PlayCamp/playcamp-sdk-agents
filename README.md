# PlayCamp SDK - Claude Code Agents

PlayCamp SDK API 및 Node SDK 연동을 위한 AI 에이전트.

## Supported Categories

| Category | Status | Agents |
|----------|--------|--------|
| **Node SDK** | Production | 5 agents |
| **API** | Production | 1 agent |

## Quick Start

### Install All Agents
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agent/main/scripts/install.sh)
```

### Install by Category
```bash
bash scripts/install.sh --platform=node  # Node SDK agents only
bash scripts/install.sh --platform=api   # API agents only
```

### Use Agents
```bash
cd your-game-server
claude
"Use @agent-playcamp-integrator to integrate PlayCamp SDK"
```

## Agents

### Node SDK Agents (5)
- **@agent-playcamp-integrator** - SDK 설치 + 필수 API 연동
- **@agent-playcamp-auditor** - 연동 코드 검증
- **@agent-playcamp-webhook-specialist** - 웹훅 수신 설정
- **@agent-playcamp-migration-assistant** - Raw HTTP → SDK 전환
- **@agent-playcamp-test-verifier** - 빌드/설정 검증

### API Agents (1)
- **@agent-playcamp-api-guide** - 직접 HTTP API 호출 가이드

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

- Fast Integration - Node SDK 자동 설정
- Multi-Language Support - Node.js 외 언어도 직접 API 가이드
- Security Validation - API 키 노출, 웹훅 서명 검증
- Build Verification - TypeScript 컴파일 + 환경 설정 확인

## Resources

- **Issues**: https://github.com/PlayCamp/playcamp-sdk-agent/issues
- **Claude Code**: https://claude.ai/code
