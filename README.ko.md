# PlayCamp SDK - Claude Code 에이전트

PlayCamp SDK API 및 Node SDK 연동을 자동화하는 AI 에이전트 모음입니다.

[English](README.md) | **한국어**

## 지원 카테고리

| 카테고리 | 상태 | 에이전트 수 |
|----------|------|-------------|
| **Node SDK** | Production | 5개 |
| **API** | Production | 1개 |

## 빠른 시작

### 전체 에이전트 설치
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh)
```

### 카테고리별 설치
```bash
bash scripts/install.sh --platform=node  # Node SDK 에이전트만
bash scripts/install.sh --platform=api   # API 에이전트만
```

### 에이전트 사용
```bash
cd your-game-server
claude
"@agent-playcamp-integrator 로 PlayCamp SDK 연동해줘"
```

## 에이전트 목록

### Node SDK 에이전트 (5개)
- **@agent-playcamp-integrator** - SDK 설치 및 필수 API 연동 (스폰서, 쿠폰, 결제)
- **@agent-playcamp-auditor** - 연동 코드 품질 검증 및 보안 점검
- **@agent-playcamp-webhook-specialist** - 웹훅 엔드포인트 설정 및 서명 검증
- **@agent-playcamp-migration-assistant** - 기존 Raw HTTP 호출을 SDK로 전환
- **@agent-playcamp-test-verifier** - 빌드 확인, 환경 설정 검증

### API 에이전트 (1개)
- **@agent-playcamp-api-guide** - Node.js 외 언어(Python, Go, Java 등)를 위한 직접 HTTP API 가이드

## 권장 워크플로우

### 신규 Node SDK 연동
```
integrator → webhook-specialist → auditor → test-verifier
```
1. **integrator**가 SDK 설치, 클라이언트 초기화, 필수 API 구현
2. **webhook-specialist**가 웹훅 엔드포인트 및 서명 검증 설정
3. **auditor**가 전체 연동 코드 검토 및 보안 점검
4. **test-verifier**가 빌드, 설정, 환경 변수 검증

### 직접 HTTP 연동 (Node.js 외)
```
api-guide
```
1. **api-guide**가 HTTP 엔드포인트, 인증 헤더, 요청/응답 형식, 웹훅 검증 예제 제공

### Raw HTTP에서 SDK로 마이그레이션
```
migration-assistant → auditor → test-verifier
```
1. **migration-assistant**가 기존 fetch/axios 호출을 SDK 메서드로 변환
2. **auditor**가 마이그레이션 완료 여부 및 정확성 검증
3. **test-verifier**가 빌드 및 설정 확인

## 주요 기능

- **빠른 연동** - Node SDK 자동 설정 및 필수 API 구현
- **다국어 지원** - Node.js 외 언어도 직접 HTTP API 가이드 제공
- **보안 검증** - API 키 노출 방지, 웹훅 서명 검증, 에러 처리 점검
- **빌드 확인** - TypeScript 컴파일 및 환경 설정 자동 검증

## 필수 API (3개)

| 엔드포인트 | 설명 |
|-----------|------|
| `POST /v1/server/sponsors` | 스폰서 생성/수정 (upsert) |
| `POST /v1/server/coupons/validate` | 쿠폰 코드 검증 |
| `POST /v1/server/payments` | 결제 처리 |

## 링크

- **이슈**: https://github.com/PlayCamp/playcamp-sdk-agents/issues
- **Claude Code**: https://claude.ai/code
