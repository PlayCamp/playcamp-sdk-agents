# PlayCamp SDK - Claude Code 에이전트

PlayCamp SDK API 및 Node SDK 연동을 자동화하는 AI 에이전트 모음입니다.

[English](README.md) | **한국어**

## 지원 카테고리

| 카테고리 | 상태 | 에이전트 수 |
|----------|------|-------------|
| **Node SDK** | Production | 5개 |
| **API** | Production | 1개 |

## 빠른 시작

### 1. 설치

```bash
cd your-game-server
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh)
```

### 2. Claude Code 실행

```bash
claude
```

### 3. 요청

```
PlayCamp SDK 연동해줘. 스폰서, 쿠폰, 결제 API 필요해
```

끝입니다. 에이전트가 자동으로 SDK 설치, 필수 API 구현, 에러 처리 설정까지 해줍니다.

## 설치 옵션

```bash
# 현재 프로젝트에 설치 (기본값)
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh)

# 글로벌 설치 (~/.claude/agents/)
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --global

# 특정 카테고리만 설치
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --platform=node
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --platform=api

# 삭제 (에이전트 파일 + CLAUDE.md 라우팅 규칙 제거)
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --uninstall
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

## 사용 예시

### 신규 연동 (Node.js)

```
Express 서버에 PlayCamp SDK 연동해줘. 결제, 쿠폰, 스폰서 API 필요해
```

```
PlayCamp 웹훅 수신 엔드포인트 만들어줘. 서명 검증 포함해서
```

```
PlayCamp 연동 코드 보안 점검해줘
```

```
PlayCamp SDK 빌드랑 환경 설정 확인해줘
```

### 직접 API 연동 (non-Node.js)

```
Python으로 PlayCamp 결제 API 연동하는 방법 알려줘
```

```
Go 서버에 PlayCamp 스폰서, 쿠폰 API 연동해줘
```

### 마이그레이션

```
기존 fetch() 호출을 PlayCamp SDK 메서드로 전환해줘
```

### 에이전트 직접 호출

에이전트 이름을 명시적으로 지정할 수도 있습니다:

```
@agent-playcamp-integrator 로 PlayCamp SDK 연동해줘
```

```
@agent-playcamp-webhook-specialist 로 웹훅 엔드포인트 설정해줘
```

```
@agent-playcamp-auditor 로 PlayCamp 연동 코드 리뷰해줘
```

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

## 동작 원리

설치 스크립트가 `.claude/agents/`에 에이전트 파일을 추가하고, 프로젝트의 `CLAUDE.md`에 라우팅 규칙을 자동 추가합니다. PlayCamp 관련 요청 시 Claude Code가 자동으로 적합한 에이전트에 위임합니다.

```
사용자: "PlayCamp 결제 처리 추가해줘"
  → Claude가 CLAUDE.md 라우팅 규칙 확인
    → @agent-playcamp-integrator 에 위임
      → 에이전트가 SDK로 결제 API 구현
```

## 주요 기능

- **자동 설정** - SDK 설치, 클라이언트 초기화, 환경 설정
- **필수 API 3개** - 스폰서, 쿠폰, 결제 연동 자동화
- **다국어 지원** - Python, Go, Java, C#, PHP 등 직접 HTTP API 가이드
- **보안 검증** - API 키 노출 방지, 웹훅 서명 검증, 에러 처리 점검
- **빌드 확인** - TypeScript 컴파일 및 환경 설정 자동 검증
- **공식 문서 연동** - 에이전트가 [PlayCamp 문서](https://playcamp.io/docs/guides/developers/game-integration/overview)를 실시간 참조

## 필수 API (3개)

| 엔드포인트 | 설명 |
|-----------|------|
| `POST /v1/server/sponsors` | 스폰서 생성/수정 (upsert) |
| `POST /v1/server/coupons/validate` | 쿠폰 코드 검증 |
| `POST /v1/server/payments` | 결제 처리 |

## 링크

- **PlayCamp 문서**: https://playcamp.io/docs/guides/developers/game-integration/overview
- **API 레퍼런스**: https://playcamp.io/docs/guides/developers/game-integration/reference
- **이슈**: https://github.com/PlayCamp/playcamp-sdk-agents/issues
- **Claude Code**: https://claude.ai/code
