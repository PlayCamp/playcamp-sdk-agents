# PlayCamp SDK - Claude Code 에이전트

PlayCamp SDK 연동을 자동화하는 AI 에이전트 모음입니다 (Node.js, Go, 직접 HTTP API).

[English](README.md) | **한국어**

## 지원 카테고리

| 카테고리 | 상태 | 에이전트 |
|----------|------|----------|
| **Node SDK** | Production | `@agent-playcamp-node` |
| **Go SDK** | Production | `@agent-playcamp-go` |
| **API** | Production | `@agent-playcamp-api` |

> 언어별로 통합된 올인원 에이전트 1개씩. 각 에이전트가 설치 → 필수 API → 플레이타임/웹뷰 → 웹훅 → 마이그레이션 → 코드 감사 → 빌드 검증까지 전체 연동 과정을 담당합니다.

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
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --platform=go
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --platform=api

# 삭제 (에이전트 파일 + CLAUDE.md 라우팅 규칙 제거)
bash <(curl -fsSL https://raw.githubusercontent.com/PlayCamp/playcamp-sdk-agents/main/scripts/install.sh) --uninstall
```

## 에이전트 목록

각 에이전트는 해당 언어의 모든 역할을 담당하는 단일 통합 에이전트입니다. 필요한 작업만 설명하면 에이전트가 알맞은 모드(연동 / 웹훅 / 마이그레이션 / 감사 / 검증)를 선택합니다.

### `@agent-playcamp-node` — Node SDK (`@playcamp/node-sdk`)
설치 및 클라이언트 초기화 · 필수 API(스폰서/쿠폰/결제) · 플레이타임 세션 · 벌크 결제 · WebView OTT · 웹훅 수신 및 서명 검증 · Raw HTTP → SDK 마이그레이션 · 코드 감사 · 빌드/환경 검증.

### `@agent-playcamp-go` — Go SDK (`github.com/playcamp/playcamp-go-sdk`)
Node 에이전트와 동일한 범위를 Go 관용구로 제공 — `errors.As()`, `context.Context`, 포인터 헬퍼, `webhookutil` 서명 검증, `go build`/`go vet` 검증.

### `@agent-playcamp-api` — 직접 HTTP API
SDK 미지원 언어(Python, Java, C#, PHP, Ruby, curl)용. 엔드포인트 문서, Bearer 인증, 요청/응답 예제, 웹훅 검증, 에러 처리.

## 사용 예시

### Node.js

```
Express 서버에 PlayCamp SDK 연동해줘. 결제, 쿠폰, 스폰서 API 필요해
```

```
PlayCamp 웹훅 수신 엔드포인트 만들어줘. 서명 검증 포함해서
```

```
후원 유저 플레이타임 세션 수집 기능 추가해줘
```

```
PlayCamp 연동 코드 보안 점검하고 빌드까지 확인해줘
```

### Go

```
Go 게임 서버에 PlayCamp Go SDK 연동해줘. 스폰서, 쿠폰, 결제 API 필요해
```

```
Go 서버에 PlayCamp 웹훅 수신 엔드포인트 만들어줘. webhookutil 서명 검증 포함해서
```

### 직접 API 연동 (SDK 미지원 언어)

```
Python으로 PlayCamp 결제 API 연동하는 방법 알려줘
```

```
Java 서버에 PlayCamp 스폰서, 쿠폰 API 연동해줘
```

### 마이그레이션

```
기존 fetch() 호출을 PlayCamp Node SDK 메서드로 전환해줘
```

```
기존 net/http 호출을 PlayCamp Go SDK 메서드로 전환해줘
```

### 에이전트 직접 호출

에이전트 이름을 명시적으로 지정할 수도 있습니다:

```
@agent-playcamp-node 로 PlayCamp SDK 연동하고 서버 키 설정해줘
```

```
@agent-playcamp-go 로 웹훅 엔드포인트 설정하고 빌드 검증까지 해줘
```

## 워크플로우

단일 에이전트로 처음부터 끝까지 진행하는 일반적인 흐름:

```
1. "PlayCamp SDK 연동해줘. 스폰서, 쿠폰, 결제 API 필요해"   → 설치 + 필수 API
2. "웹훅 수신 + 서명 검증 추가해줘"                          → 웹훅 수신
3. "연동 코드 정확성/보안 감사해줘"                          → 코드 검토 (읽기 전용)
4. "빌드랑 환경 설정 검증해줘"                               → 빌드/환경 검증
```

같은 에이전트가 각 단계를 모두 처리하므로 별도 에이전트 간 인계가 필요 없습니다. 마이그레이션은 *"기존 HTTP 호출을 PlayCamp SDK로 전환해줘"*로 시작한 뒤 감사 + 검증 단계로 이어가면 됩니다.

## 동작 원리

설치 스크립트가 `.claude/agents/`에 에이전트 파일을 추가하고, 프로젝트의 `CLAUDE.md`에 라우팅 규칙을 자동 추가합니다. PlayCamp 관련 요청 시 Claude Code가 자동으로 해당 언어 에이전트에 위임합니다.

```
사용자: "PlayCamp 결제 처리 추가해줘"
  → Claude가 CLAUDE.md 라우팅 규칙 확인
    → @agent-playcamp-node (또는 -go / -api) 에 위임
      → 에이전트가 SDK로 결제 API 구현
```

## 주요 기능

- **언어별 단일 에이전트** - 5개 전문 에이전트를 오가지 않고 하나가 전체 과정 담당
- **자동 설정** - SDK 설치, 클라이언트 초기화, 환경 설정
- **필수 + 확장 API** - 스폰서, 쿠폰, 결제 + 플레이타임 세션, 벌크 결제, WebView OTT
- **Node + Go SDK** - 두 공식 SDK(v0.0.8) 전체 지원
- **다국어 지원** - Python, Java, C#, PHP 등 직접 HTTP API 가이드
- **보안 검증** - API 키 노출 방지, 웹훅 서명 검증(이벤트 7종), 에러 처리 점검
- **빌드 확인** - TypeScript/Go 컴파일 및 환경 설정 자동 검증
- **공식 문서 연동** - 에이전트가 [PlayCamp 문서](https://playcamp.io/docs/guides/developers/game-integration/overview)를 실시간 참조

## 필수 API (3개)

| 엔드포인트 | 설명 |
|-----------|------|
| `POST /v1/server/sponsors` | 스폰서 생성/수정 (upsert) |
| `POST /v1/server/coupons/validate` | 쿠폰 코드 검증 |
| `POST /v1/server/payments` | 결제 처리 |

## 확장 API (선택)

| 엔드포인트 | 설명 |
|-----------|------|
| `POST /v1/server/payments/bulk` | 벌크 결제 (최대 1000건) |
| `POST /v1/server/playtime/sessions` | 플레이타임 세션 수집 (단건) |
| `POST /v1/server/playtime/sessions/bulk` | 플레이타임 세션 수집 (벌크, 최대 1000건) |
| `POST /v1/server/webview/ott` | WebView 일회용 토큰(OTT) 발급 |

## 링크

- **PlayCamp 문서**: https://playcamp.io/docs/guides/developers/game-integration/overview
- **API 레퍼런스**: https://playcamp.io/docs/guides/developers/game-integration/reference
- **이슈**: https://github.com/PlayCamp/playcamp-sdk-agents/issues
- **Claude Code**: https://claude.ai/code
