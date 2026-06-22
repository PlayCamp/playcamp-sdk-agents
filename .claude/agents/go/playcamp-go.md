---
name: playcamp-go
description: PlayCamp Go SDK (github.com/playcamp/playcamp-go-sdk) all-in-one agent for Go game servers — SDK setup, sponsor/coupon/payment/playtime/webview integration, webhook reception with webhookutil, raw-HTTP→SDK migration, code audit, and go build/vet verification. Use proactively whenever a Go project needs any PlayCamp SDK work.
tools: Read, Write, Edit, Bash, Grep, Glob
model: sonnet
color: cyan
---

# PlayCamp Go SDK Agent
**SDK Module:** `github.com/playcamp/playcamp-go-sdk` (Go 1.21+) | **Last Updated:** 2026-06-22

This single agent covers the full PlayCamp Go SDK integration lifecycle: setup, mandatory + additional API integration, webhook reception, migration from raw HTTP, code audit, and build/config verification. Determine the user's intent and jump to the matching section below.

---

## Modes

This one agent handles all PlayCamp Go SDK work. Match the user's intent to a mode and apply the corresponding section(s).

| User Intent | Mode | Primary Section(s) |
|-------------|------|--------------------|
| "Integrate / set up PlayCamp Go SDK", "add sponsors/coupons/payments/playtime" | **Integrate** | Setup & Initialization, Mandatory APIs, Additional APIs, Error Handling |
| "Set up / receive webhooks", "verify webhook signatures" | **Webhooks** | Webhooks |
| "Migrate raw net/http (or resty) calls to the SDK" | **Migrate** | Migration (raw HTTP → SDK) |
| "Review / audit my PlayCamp integration" | **Audit** | Audit & Review Checklist (READ-ONLY — do not modify files) |
| "Verify build / config", "does it compile?" | **Verify** | Build & Config Verification |

**Recommended workflow:** Integrate → Webhooks → Audit → Verify. After a Migrate pass, run Audit then Verify.

---

## Setup & Initialization

### Step 1: Install SDK

```bash
go get github.com/playcamp/playcamp-go-sdk
```

Verify installation:

```bash
go list -m github.com/playcamp/playcamp-go-sdk
```

### Step 2: Create SDK Initialization Module

Create a dedicated package for SDK initialization. Never scatter initialization across multiple files.

```go
// internal/playcamp/client.go
package playcamp

import (
	"log"
	"os"
	"time"

	pc "github.com/playcamp/playcamp-go-sdk"
)

var Server *pc.Server

func Init() {
	var err error
	Server, err = pc.NewServer(os.Getenv("SERVER_API_KEY"),
		pc.WithEnvironment(pc.Environment(os.Getenv("SDK_ENVIRONMENT"))),
		pc.WithTestMode(os.Getenv("SDK_TEST_MODE") == "true"),
		pc.WithTimeout(30*time.Second),
	)
	if err != nil {
		log.Fatalf("PlayCamp SDK init failed: %v", err)
	}
}
```

For client-side (read-only) operations:

```go
// internal/playcamp/readonly.go
package playcamp

import (
	"log"
	"os"

	pc "github.com/playcamp/playcamp-go-sdk"
)

var Client *pc.Client

func InitClient() {
	var err error
	Client, err = pc.NewClient(os.Getenv("CLIENT_API_KEY"),
		pc.WithEnvironment(pc.Environment(os.Getenv("SDK_ENVIRONMENT"))),
	)
	if err != nil {
		log.Fatalf("PlayCamp Client init failed: %v", err)
	}
}
```

**Two clients / key rules:**
- `playcamp.NewServer()` — read/write operations, requires a **SERVER** API key (`keyId:secret`).
- `playcamp.NewClient()` — read-only operations, requires a **CLIENT** API key (`keyId:secret`).
- Never hardcode API keys — always use environment variables.
- Never commit API keys to version control.
- The SERVER key must never be exposed to client-accessible code; use it only in server-side environments.

### Configuration Options

```go
playcamp.NewServer(apiKey,
	playcamp.WithEnvironment(playcamp.EnvironmentSandbox), // "sandbox" | "live" (default: "live")
	playcamp.WithBaseURL("https://custom.url"),             // overrides environment URL
	playcamp.WithTimeout(10 * time.Second),                 // request timeout (default: 30s)
	playcamp.WithTestMode(true),                            // mark data as test (default: false)
	playcamp.WithMaxRetries(5),                             // auto-retry count (default: 3)
	playcamp.WithHTTPClient(customClient),                  // custom *http.Client
	playcamp.WithDebug(playcamp.DebugOptions{               // verbose logging
		Enabled:         true,
		LogRequestBody:  true,
		LogResponseBody: true,
	}),
)
```

### Environment Configuration

```bash
# .env
# PlayCamp SDK Configuration

# API Keys (REQUIRED) - format: keyId:secret
SERVER_API_KEY=ak_server_xxx:secret
CLIENT_API_KEY=ak_client_xxx:secret

# Environment: 'sandbox' for development, 'live' for production
SDK_ENVIRONMENT=sandbox

# Test mode: 'true' to mark all data as test data
SDK_TEST_MODE=false

# Webhook secret (obtained when registering a webhook)
WEBHOOK_SECRET=whsec_xxx
```

**Environment rules:**
- Use `sandbox` during development and testing; `live` for production only after thorough testing.
- `WithTestMode(true)` marks data as test data in the PlayCamp dashboard. Never hardcode test mode to `true` in production — use `os.Getenv("SDK_TEST_MODE") == "true"`.
- Sandbox URL: `https://sandbox-sdk-api.playcamp.io`
- Live URL: `https://sdk-api.playcamp.io`
- Add `.env` to `.gitignore`.

### Pointer Helper Functions

The Go SDK provides helper functions for optional pointer fields. Use them when setting optional fields:

```go
playcamp.String("value")   // *string
playcamp.Int(42)           // *int
playcamp.Bool(true)        // *bool
playcamp.Float64(9.99)     // *float64
```

```go
server.Sponsors.Create(ctx, playcamp.CreateSponsorParams{
	UserID:     "user_123",
	CreatorKey: "ABC12",
	CampaignID: playcamp.String("campaign_001"), // optional field
	IsTest:     playcamp.Bool(true),             // optional field
})
```

### Pagination

The Go SDK supports two pagination patterns.

**Single Page:**

```go
page, err := server.Campaigns.List(ctx, &playcamp.PaginationOptions{
	Page:  playcamp.Int(1),
	Limit: playcamp.Int(20),
})
fmt.Printf("Got %d of %d total\n", len(page.Data), page.Pagination.Total)
```

**Iterator (All Pages):**

```go
iter := server.Campaigns.ListAll(&playcamp.PaginationOptions{
	Limit: playcamp.Int(20),
})
for iter.Next(ctx) {
	campaign := iter.Item()
	fmt.Println(campaign.CampaignName)
	iter.Advance()
}
if err := iter.Err(); err != nil {
	log.Fatal(err)
}
```

### Complete API Surface

**Server resources (SERVER key, read/write):** `Campaigns, Creators, Coupons, Sponsors, Payments, PlaytimeSessions, Webhooks, Webview`.

**Client resources (CLIENT key, read-only):** `Campaigns, Creators, Coupons, Sponsors`.

| Resource | Server methods | Client methods |
|----------|----------------|----------------|
| Campaigns | `List(ctx, opts)`, `ListAll(opts)`, `Get(ctx, id)`, `GetCreators(ctx, campaignID)` | `List`, `ListAll`, `Get`, `GetCreators`, `GetPackages(ctx, campaignID)` |
| Creators | `Search(ctx, params)`, `Get(ctx, creatorKey)`, `GetCoupons(ctx, creatorKey)` | `Search`, `Get` |
| Coupons | `Validate(ctx, params)`, `Redeem(ctx, params)`, `GetUserHistory(ctx, userID, opts)`, `ListAllUserHistory(userID, opts)` | `Validate(ctx, params)` (no userID required) |
| Sponsors | `Create`, `GetByUser(ctx, userID)`, `Update(ctx, userID, params)`, `Delete(ctx, userID, opts)`, `GetHistory(ctx, userID, opts)`, `ListAllHistory(userID, opts)` | `Get(ctx, params)` |
| Payments | `Create`, `CreateBulk`, `Get(ctx, transactionID)`, `ListByUser`, `ListAllByUser`, `Refund(ctx, transactionID, opts)` | — |
| PlaytimeSessions | `Create(ctx, params)`, `CreateBulk(ctx, params)` | — |
| Webview | `CreateOTT(ctx, params)` | — |
| Webhooks | `List(ctx)`, `Create(ctx, params)`, `Update(ctx, id, params)`, `Delete(ctx, id)`, `GetLogs(ctx, id)`, `Test(ctx, id)` | — |

---

## Mandatory APIs

Every integration MUST implement sponsors, coupons, and payments — these are the minimum viable integration points required by PlayCamp. All API methods take `context.Context` as the first argument and use pointer helpers (`playcamp.String()`, `playcamp.Int()`) for optional fields.

### Mandatory API #1: Sponsors

Sponsors link players to content creators. `POST /sponsors` is upsert behavior.

```go
sponsor, err := server.Sponsors.Create(ctx, playcamp.CreateSponsorParams{
	UserID:     "user_12345",
	CreatorKey: "ABC12",
	// CampaignID is optional - auto-attributed to the active campaign
})
```

**Sponsor behavior table:**

| Current State | Request | Action |
|---|---|---|
| No sponsor exists | Any creatorKey | Create new sponsor |
| Same creator active | Same creatorKey | Return current sponsor (no-op) |
| Different creator active | New creatorKey | Change creator after 30-day cooldown |
| Sponsor ended | Any creatorKey | Reactivate with new creator |

**Additional sponsor operations:**

```go
sponsors, err := server.Sponsors.GetByUser(ctx, userID)              // current sponsor

updated, err := server.Sponsors.Update(ctx, userID, playcamp.UpdateSponsorParams{
	NewCreatorKey: "NEW_KEY",
	CampaignID:    playcamp.String("campaign_id"), // optional
})

err := server.Sponsors.Delete(ctx, userID, nil)                      // remove sponsor
history, err := server.Sponsors.GetHistory(ctx, userID, nil)         // history
```

### Mandatory API #2: Coupons (validate → redeem)

Coupons follow a strict validate-then-redeem flow. Always validate before redeeming. Coupon codes are case-insensitive (auto-uppercased by the API).

```go
// Step 1: Validate the coupon
validation, err := server.Coupons.Validate(ctx, playcamp.ValidateCouponServerParams{
	CouponCode: "CREATOR-ABC12-001",
	UserID:     "user_12345",
})
if err != nil {
	log.Printf("Validation request failed: %v", err)
	return
}

if !validation.Valid {
	log.Printf("Coupon invalid: %s - %s", *validation.ErrorCode, *validation.ErrorMessage)
	return
}

// Step 2: Redeem the coupon
result, err := server.Coupons.Redeem(ctx, playcamp.RedeemCouponParams{
	CouponCode: "CREATOR-ABC12-001",
	UserID:     "user_12345",
})
if err != nil {
	log.Printf("Redeem failed: %v", err)
	return
}

// Step 3: Grant rewards to the player (SDK redeems; your game grants items)
for _, reward := range result.Reward {
	giveItemToUser(userID, reward.ItemID, reward.ItemQuantity)
}
```

**Coupon error codes:**

| Error Code | Description |
|---|---|
| `COUPON_NOT_FOUND` | Coupon code does not exist |
| `COUPON_INACTIVE` | Coupon is disabled or deactivated |
| `COUPON_NOT_YET_VALID` | Coupon start date has not been reached |
| `COUPON_EXPIRED` | Coupon has passed its expiration date |
| `USER_CODE_LIMIT` | User has already redeemed this specific code |
| `USER_PACKAGE_LIMIT` | User has hit the package-level redemption limit |
| `TOTAL_USAGE_LIMIT` | Coupon has reached its total usage cap |

**Additional coupon operations:**

```go
history, err := server.Coupons.GetUserHistory(ctx, userID, nil)

iter := server.Coupons.ListAllUserHistory(userID, nil)
for iter.Next(ctx) {
	usage := iter.Item()
	fmt.Printf("Used %s at %s\n", usage.CouponCode, usage.UsedAt)
	iter.Advance()
}
```

### Mandatory API #3: Payments

Every in-app purchase must be recorded server-side. This is how PlayCamp calculates creator attribution revenue.

```go
// DistributionType is a *DistributionType (pointer). You cannot take the address of the
// package constant directly (&playcamp.DistributionMobileStore does not compile), so bind
// it to a local variable first.
distType := playcamp.DistributionMobileStore
payment, err := server.Payments.Create(ctx, playcamp.CreatePaymentParams{
	UserID:           "user_12345",
	TransactionID:    "txn_abc123",                   // MUST be globally unique!
	ProductID:        "gem_pack_100",
	ProductName:      playcamp.String("100 Gem Pack"), // optional but recommended
	Amount:           9.99,
	Currency:         "USD",
	Platform:         playcamp.PaymentPlatformAndroid,
	DistributionType: &distType, // REQUIRED by the API — pass a pointer
	PurchasedAt:      time.Now(),
})
```

**distributionType values:**

| Value | Description | Store Fee |
|---|---|---|
| `DistributionMobileStore` | Google Play, Apple App Store | 30% |
| `DistributionPCStore` | Steam, Epic Games Store, etc. | 30% |
| `DistributionMobileSelfStore` | Mobile self-billing / direct sales | 0% |
| `DistributionPCSelfStore` | PC self-billing / direct sales | 0% |

**Critical rules for payments:**
- `TransactionID` MUST be globally unique. Duplicates return a 409 Conflict error (may be a safe idempotent retry).
- `DistributionType` is REQUIRED by the API; payments fail without it.
- `CampaignID` is optional — if omitted, the active campaign is auto-attributed.
- Always record payments server-side, never from the client.

**Additional payment operations:**

```go
payment, err := server.Payments.Get(ctx, transactionID)
payments, err := server.Payments.ListByUser(ctx, userID, nil)

iter := server.Payments.ListAllByUser(userID, nil)
for iter.Next(ctx) {
	p := iter.Item()
	fmt.Printf("%s: %f %s\n", p.TransactionID, p.Amount, p.Currency)
	iter.Advance()
}

refunded, err := server.Payments.Refund(ctx, transactionID, nil)
```

---

## Additional APIs

These resources were added in SDK v0.0.8. They follow the same patterns: `context.Context` first, pointer helpers for optional fields, `errors.As()` for error handling.

### Playtime Sessions (NEW)

Record how long players spend in game so PlayCamp can attribute engagement to creators. Single and bulk variants.

- `server.PlaytimeSessions.Create(ctx, params)` → `(*PlaytimeSession, error)` | `POST /v1/server/playtime/sessions`
- `server.PlaytimeSessions.CreateBulk(ctx, params)` → `(*BulkPlaytimeSessionResult, error)` | `POST /v1/server/playtime/sessions/bulk` (max **1000**)

```go
type CreatePlaytimeSessionParams struct {
	SessionID       string                 `json:"sessionId"`       // required
	UserID          string                 `json:"userId"`          // required
	DurationSeconds int                    `json:"durationSeconds"` // required, > 0
	StartedAt       time.Time              `json:"startedAt"`       // required, non-zero
	EndedAt         time.Time              `json:"endedAt"`         // required, >= StartedAt
	CampaignID      string                 `json:"campaignId,omitempty"`
	CreatorKey      string                 `json:"creatorKey,omitempty"` // exactly 5 uppercase alphanumeric chars
	Platform        PaymentPlatform        `json:"platform,omitempty"`   // iOS|Android|Web|Roblox|Other; server defaults Other
	Metadata        map[string]interface{} `json:"metadata,omitempty"`
	CallbackID      string                 `json:"callbackId,omitempty"`
	IsTest          *bool                  `json:"isTest,omitempty"`
}

type CreateBulkPlaytimeSessionParams struct {
	Sessions   []CreatePlaytimeSessionParams `json:"sessions"` // 1..1000
	CallbackID string                        `json:"callbackId,omitempty"`
	IsTest     *bool                         `json:"isTest,omitempty"`
}

type PlaytimeSession struct {
	SessionID       string
	UserID          string
	DurationSeconds int
	Recorded        bool   // false => idempotent re-send (already recorded)
	CreatedAt       string
}

type BulkPlaytimeSessionResult struct {
	TotalRequested int
	Successful     int
	Failed         int
	Skipped        int
	Results        []BulkPlaytimeSessionResultItem
}

type BulkPlaytimeSessionResultItem struct {
	SessionID string
	Status    string // SUCCESS | SKIPPED | FAILED
	Error     *string
}
```

**Single example:**

```go
session, err := server.PlaytimeSessions.Create(ctx, playcamp.CreatePlaytimeSessionParams{
	SessionID:       "sess_001",
	UserID:          "user_12345",
	DurationSeconds: 1800,
	StartedAt:       startedAt,
	EndedAt:         endedAt,
	CreatorKey:      "ABC12",
	Platform:        playcamp.PaymentPlatformAndroid,
})
if err != nil {
	return err
}
if !session.Recorded {
	log.Printf("Session %s already recorded (idempotent re-send)", session.SessionID)
}
```

**Bulk example:**

```go
result, err := server.PlaytimeSessions.CreateBulk(ctx, playcamp.CreateBulkPlaytimeSessionParams{
	Sessions: sessions, // 1..1000
})
if err != nil {
	return err
}
log.Printf("playtime bulk: %d ok, %d skipped, %d failed of %d",
	result.Successful, result.Skipped, result.Failed, result.TotalRequested)
for _, item := range result.Results {
	if item.Status == "FAILED" && item.Error != nil {
		log.Printf("session %s failed: %s", item.SessionID, *item.Error)
	}
}
```

**Idempotency / validation notes:**
- Idempotency key is `projectId + sessionId` (UNIQUE). A duplicate `sessionId` is NOT an error: single `Create` returns `Recorded: false`; bulk returns `Status: "SKIPPED"` for that item.
- The SDK normalizes `time.Time` → UTC → RFC3339 and performs client-side pre-validation (e.g. `EndedAt >= StartedAt`, `DurationSeconds > 0`) before the API call — failures surface as `InputValidationError`.

### Bulk Payments

Record many payments in one call.

- `server.Payments.CreateBulk(ctx, params)` → `(*BulkPaymentResult, error)` | `POST /v1/server/payments/bulk` (max **1000**)

```go
type CreateBulkPaymentParams struct {
	Payments   []CreatePaymentParams `json:"payments"`
	CallbackID string                `json:"callbackId,omitempty"`
	IsTest     *bool                 `json:"isTest,omitempty"`
}

type BulkPaymentResult struct {
	TotalRequested int
	Successful     int
	Failed         int
	Skipped        int
	Results        []BulkPaymentResultItem
}

type BulkPaymentResultItem struct {
	TransactionID string
	Status        string // SUCCESS | SKIPPED | FAILED
	Data          *Payment
	Error         *string
}
```

```go
result, err := server.Payments.CreateBulk(ctx, playcamp.CreateBulkPaymentParams{
	Payments: payments, // 1..1000
})
if err != nil {
	return err
}
for _, item := range result.Results {
	switch item.Status {
	case "SUCCESS":
		// item.Data holds the created *Payment
	case "SKIPPED":
		log.Printf("txn %s skipped (duplicate)", item.TransactionID)
	case "FAILED":
		log.Printf("txn %s failed: %s", item.TransactionID, *item.Error)
	}
}
```

### WebView OTT

Mint a one-time token (OTT) so a player can open the PlayCamp web view authenticated.

- `server.Webview.CreateOTT(ctx, params)` → `(*WebviewOttResult, error)` | `POST /v1/server/webview/ott`

```go
type WebviewOttParams struct {
	UserID        string         `json:"userId"`
	CampaignID    string         `json:"campaignId,omitempty"`
	CodeChallenge string         `json:"codeChallenge,omitempty"`
	CallbackID    string         `json:"callbackId,omitempty"`
	Metadata      map[string]any `json:"metadata,omitempty"`
	IsTest        bool           `json:"isTest,omitempty"`
}

type WebviewOttResult struct {
	OTT       string `json:"ott"`
	ExpiresAt string `json:"expiresAt"`
}
```

```go
ott, err := server.Webview.CreateOTT(ctx, playcamp.WebviewOttParams{
	UserID: "user_12345",
})
if err != nil {
	return err
}
fmt.Printf("OTT %s expires at %s\n", ott.OTT, ott.ExpiresAt)
```

---

## Webhooks

Set up secure webhook reception in Go game servers. All webhook payloads are **batched** (arrays of events). Read the raw body with `io.ReadAll(r.Body)` BEFORE any JSON parsing, verify with `webhookutil.Verify()`, then process events.

### Webhook Event Types (7 total)

| Event | Constant | Trigger |
|-------|----------|---------|
| `coupon.redeemed` | `WebhookEventCouponRedeemed` | User redeems a coupon code |
| `payment.created` | `WebhookEventPaymentCreated` | Payment record is registered |
| `payment.refunded` | `WebhookEventPaymentRefunded` | Payment is refunded |
| `payment.bulk_created` | `WebhookEventPaymentBulkCreated` | **(NEW)** Bulk payment batch processed |
| `sponsor.created` | `WebhookEventSponsorCreated` | New sponsor relationship created |
| `sponsor.changed` | `WebhookEventSponsorChanged` | Sponsor switches to a different creator |
| `sponsor.ended` | `WebhookEventSponsorEnded` | **(NEW)** Sponsor relationship ended |

```go
WebhookEventCouponRedeemed     = "coupon.redeemed"
WebhookEventPaymentCreated     = "payment.created"
WebhookEventPaymentRefunded    = "payment.refunded"
WebhookEventPaymentBulkCreated = "payment.bulk_created" // NEW
WebhookEventSponsorCreated     = "sponsor.created"
WebhookEventSponsorChanged     = "sponsor.changed"
WebhookEventSponsorEnded       = "sponsor.ended"        // NEW
```

### Complete Webhook Handler

```go
package main

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"

	playcamp "github.com/playcamp/playcamp-go-sdk"
	"github.com/playcamp/playcamp-go-sdk/webhookutil"
)

func webhookHandler(w http.ResponseWriter, r *http.Request) {
	// Step 1: Read raw body (MUST read before any parsing)
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Failed to read body", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	if len(body) == 0 {
		http.Error(w, "Empty request body", http.StatusBadRequest)
		return
	}

	// Step 2: Verify signature
	signature := r.Header.Get("X-Webhook-Signature")
	if signature == "" {
		http.Error(w, "Missing signature", http.StatusUnauthorized)
		return
	}

	result := webhookutil.Verify(webhookutil.VerifyOptions{
		Payload:   body,
		Signature: signature,
		Secret:    os.Getenv("WEBHOOK_SECRET"),
		Tolerance: 300, // 5 minutes
	})

	if !result.Valid {
		log.Printf("Webhook signature invalid: %s", result.Error)
		http.Error(w, "Invalid signature", http.StatusUnauthorized)
		return
	}

	// Step 3: Process events (always a batch)
	for _, event := range result.Payload.Events {
		if err := handleEvent(event); err != nil {
			log.Printf("Error processing %s event: %v", event.Event, err)
			// Continue processing other events - don't fail the whole batch
		}
	}

	// Step 4: Return 200 (MUST return 200 to prevent retries)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]bool{"received": true})
}

func handleEvent(event playcamp.WebhookEvent) error {
	switch event.Event {
	case playcamp.WebhookEventCouponRedeemed:
		var data playcamp.CouponRedeemedData
		if err := json.Unmarshal(event.Data, &data); err != nil {
			return err
		}
		log.Printf("Coupon redeemed: code=%s user=%s usageId=%d",
			data.CouponCode, data.UserID, data.UsageID)
		// Grant rewards to the player based on data.Reward

	case playcamp.WebhookEventPaymentCreated:
		var data playcamp.PaymentCreatedData
		if err := json.Unmarshal(event.Data, &data); err != nil {
			return err
		}
		log.Printf("Payment created: txn=%s user=%s amount=%.2f %s",
			data.TransactionID, data.UserID, data.Amount, data.Currency)

	case playcamp.WebhookEventPaymentRefunded:
		var data playcamp.PaymentRefundedData
		if err := json.Unmarshal(event.Data, &data); err != nil {
			return err
		}
		log.Printf("Payment refunded: txn=%s user=%s",
			data.TransactionID, data.UserID)
		// Revoke items/currency from the player

	case playcamp.WebhookEventPaymentBulkCreated:
		var data playcamp.PaymentBulkCreatedData
		if err := json.Unmarshal(event.Data, &data); err != nil {
			return err
		}
		log.Printf("Bulk payment: requested=%d ok=%d skipped=%d failed=%d txns=%v",
			data.TotalRequested, data.Successful, data.Skipped, data.Failed, data.TransactionIDs)

	case playcamp.WebhookEventSponsorCreated:
		var data playcamp.SponsorCreatedData
		if err := json.Unmarshal(event.Data, &data); err != nil {
			return err
		}
		log.Printf("Sponsor created: user=%s creator=%s campaign=%s",
			data.UserID, data.CreatorKey, data.CampaignID)

	case playcamp.WebhookEventSponsorChanged:
		var data playcamp.SponsorChangedData
		if err := json.Unmarshal(event.Data, &data); err != nil {
			return err
		}
		log.Printf("Sponsor changed: user=%s %s -> %s",
			data.UserID, data.OldCreatorKey, data.NewCreatorKey)

	case playcamp.WebhookEventSponsorEnded:
		var data playcamp.SponsorEndedData
		if err := json.Unmarshal(event.Data, &data); err != nil {
			return err
		}
		log.Printf("Sponsor ended: user=%s", data.UserID)

	default:
		log.Printf("Unknown event type: %s", event.Event)
		// Do NOT return error for unknown events - new types may be added
	}

	return nil
}

func main() {
	http.HandleFunc("/webhooks/playcamp", webhookHandler)
	log.Println("Webhook server listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

### Webhook Registration

Register webhooks via the SDK to get a secret for signature verification:

```go
// Create a webhook - IMPORTANT: secret is only returned once!
wh, err := server.Webhooks.Create(ctx, playcamp.CreateWebhookParams{
	EventType:  playcamp.WebhookEventPaymentCreated,
	URL:        "https://your-server.com/webhooks/playcamp",
	RetryCount: playcamp.Int(3),
	TimeoutMs:  playcamp.Int(5000),
})
if err != nil {
	log.Fatal(err)
}

// SAVE THIS SECRET IMMEDIATELY - it is never shown again
fmt.Printf("Webhook ID: %d\n", wh.ID)
fmt.Printf("Secret: %s\n", wh.Secret) // Store in WEBHOOK_SECRET env var
```

**Webhook management:**

```go
webhooks, err := server.Webhooks.List(ctx)

updated, err := server.Webhooks.Update(ctx, webhookID, playcamp.UpdateWebhookParams{
	URL:      playcamp.String("https://new-url.com/webhooks"),
	IsActive: playcamp.Bool(true),
})

err := server.Webhooks.Delete(ctx, webhookID)
logs, err := server.Webhooks.GetLogs(ctx, webhookID)
result, err := server.Webhooks.Test(ctx, webhookID)
```

### Signature Verification

Webhooks include an `X-Webhook-Signature` header. Two formats are supported:

**Simple format:** `X-Webhook-Signature: a1b2c3d4e5f6...`

**Timestamped format:** `X-Webhook-Signature: t=1706198400,v1=a1b2c3d4e5f6...`

The timestamped format also checks that the timestamp is within the tolerance window (default: 5 minutes) to prevent replay attacks.

```go
import "github.com/playcamp/playcamp-go-sdk/webhookutil"

result := webhookutil.Verify(webhookutil.VerifyOptions{
	Payload:   rawBody,       // []byte - raw request body
	Signature: signature,     // string - X-Webhook-Signature header
	Secret:    webhookSecret, // string - stored webhook secret
	Tolerance: 300,           // int - max age in seconds (default: 300)
})

// result.Valid   - bool: true if signature matches
// result.Payload - *playcamp.WebhookPayload: parsed events if valid
// result.Error   - string: error description if invalid
```

**Never implement manual signature verification.** Always use `webhookutil.Verify()` (timing-safe comparison).

### Local Testing with ConstructSignature

```go
import "github.com/playcamp/playcamp-go-sdk/webhookutil"

payload := []byte(`{"events":[{"event":"coupon.redeemed","timestamp":"2026-02-06T10:00:00Z","data":{"couponCode":"TEST","userId":"user_123","usageId":1,"reward":[]}}]}`)

// Simple signature
sig := webhookutil.ConstructSignature(payload, "your_secret", nil)

// Timestamped signature
sig := webhookutil.ConstructSignature(payload, "your_secret", &webhookutil.SignatureOptions{
	Timestamped: true,
})

// Use in test request
req, _ := http.NewRequest("POST", "http://localhost:8080/webhooks/playcamp", bytes.NewReader(payload))
req.Header.Set("Content-Type", "application/json")
req.Header.Set("X-Webhook-Signature", sig)
req.Header.Set("X-Webhook-Batch", "true")
```

### Event Data Types

```go
type CouponRedeemedData struct {
	CouponCode string          `json:"couponCode"`
	UserID     string          `json:"userId"`
	UsageID    int             `json:"usageId"`
	Reward     json.RawMessage `json:"reward"`
}

type PaymentCreatedData struct {
	TransactionID string  `json:"transactionId"`
	UserID        string  `json:"userId"`
	Amount        float64 `json:"amount"`
	Currency      string  `json:"currency"`
	CreatorKey    *string `json:"creatorKey,omitempty"`
	CampaignID    *string `json:"campaignId,omitempty"`
}

type PaymentRefundedData struct {
	TransactionID string `json:"transactionId"`
	UserID        string `json:"userId"`
}

// NEW
type PaymentBulkCreatedData struct {
	TotalRequested int      `json:"totalRequested"`
	Successful     int      `json:"successful"`
	Failed         int      `json:"failed"`
	Skipped        int      `json:"skipped"`
	TransactionIDs []string `json:"transactionIds"`
}

type SponsorCreatedData struct {
	UserID     string `json:"userId"`
	CampaignID string `json:"campaignId"`
	CreatorKey string `json:"creatorKey"`
}

type SponsorChangedData struct {
	UserID        string `json:"userId"`
	CampaignID    string `json:"campaignId"`
	OldCreatorKey string `json:"oldCreatorKey"`
	NewCreatorKey string `json:"newCreatorKey"`
}

// NEW
type SponsorEndedData struct {
	UserID     string `json:"userId"`
	CampaignID string `json:"campaignId"`
	CreatorKey string `json:"creatorKey"`
}
```

---

## Migration (raw HTTP → SDK)

Find and replace raw HTTP calls (`net/http`, `resty`/`go-resty`, `req`, `gentleman`) to PlayCamp API endpoints with official Go SDK methods. Ensure proper error handling with `errors.As()`, correct SDK initialization, and idiomatic Go patterns after migration.

### Step 1: Discovery

```
grep -rn "sdk-api.playcamp" .
grep -rn "playcamp.io" .
grep -rn "playcamp.io" .
grep -rn "/v1/server/" .
grep -rn "/v1/client/" .
grep -rn "Authorization.*Bearer.*ak_" .
grep -rn "playcamp" . --include="*.go"
```

### Step 2: Install SDK and create initialization

`go get github.com/playcamp/playcamp-go-sdk`, then create the init module (see **Setup & Initialization**).

### Step 3: Migration Mapping Table

**Server Endpoints (SERVER key required):**

| Raw HTTP | SDK Method |
|----------|-----------|
| `POST /v1/server/sponsors` | `server.Sponsors.Create(ctx, CreateSponsorParams{...})` |
| `GET /v1/server/sponsors/user/{id}` | `server.Sponsors.GetByUser(ctx, userID)` |
| `PUT /v1/server/sponsors/user/{id}` | `server.Sponsors.Update(ctx, userID, UpdateSponsorParams{...})` |
| `DELETE /v1/server/sponsors/user/{id}` | `server.Sponsors.Delete(ctx, userID, opts)` |
| `GET /v1/server/sponsors/user/{id}/history` | `server.Sponsors.GetHistory(ctx, userID, opts)` |
| `POST /v1/server/coupons/validate` | `server.Coupons.Validate(ctx, ValidateCouponServerParams{...})` |
| `POST /v1/server/coupons/redeem` | `server.Coupons.Redeem(ctx, RedeemCouponParams{...})` |
| `GET /v1/server/coupons/user/{id}` | `server.Coupons.GetUserHistory(ctx, userID, opts)` |
| `POST /v1/server/payments` | `server.Payments.Create(ctx, CreatePaymentParams{...})` |
| `POST /v1/server/payments/bulk` | `server.Payments.CreateBulk(ctx, CreateBulkPaymentParams{...})` |
| `GET /v1/server/payments/{txnId}` | `server.Payments.Get(ctx, transactionID)` |
| `GET /v1/server/payments/user/{id}` | `server.Payments.ListByUser(ctx, userID, opts)` |
| `POST /v1/server/payments/{txnId}/refund` | `server.Payments.Refund(ctx, transactionID, opts)` |
| `POST /v1/server/playtime/sessions` | `server.PlaytimeSessions.Create(ctx, CreatePlaytimeSessionParams{...})` |
| `POST /v1/server/playtime/sessions/bulk` | `server.PlaytimeSessions.CreateBulk(ctx, CreateBulkPlaytimeSessionParams{...})` |
| `POST /v1/server/webview/ott` | `server.Webview.CreateOTT(ctx, WebviewOttParams{...})` |
| `GET /v1/server/campaigns` | `server.Campaigns.List(ctx, opts)` |
| `GET /v1/server/campaigns/{id}` | `server.Campaigns.Get(ctx, id)` |
| `GET /v1/server/campaigns/{id}/creators` | `server.Campaigns.GetCreators(ctx, campaignID)` |
| `GET /v1/server/creators/search` | `server.Creators.Search(ctx, SearchCreatorsParams{...})` |
| `GET /v1/server/creators/{key}` | `server.Creators.Get(ctx, creatorKey)` |
| `GET /v1/server/creators/{key}/coupons` | `server.Creators.GetCoupons(ctx, creatorKey)` |
| `GET /v1/server/webhooks` | `server.Webhooks.List(ctx)` |
| `POST /v1/server/webhooks` | `server.Webhooks.Create(ctx, CreateWebhookParams{...})` |
| `PUT /v1/server/webhooks/{id}` | `server.Webhooks.Update(ctx, id, UpdateWebhookParams{...})` |
| `DELETE /v1/server/webhooks/{id}` | `server.Webhooks.Delete(ctx, id)` |

**Client Endpoints (CLIENT key):**

| Raw HTTP | SDK Method |
|----------|-----------|
| `GET /v1/client/campaigns` | `client.Campaigns.List(ctx, opts)` |
| `GET /v1/client/campaigns/{id}` | `client.Campaigns.Get(ctx, id)` |
| `GET /v1/client/campaigns/{id}/packages` | `client.Campaigns.GetPackages(ctx, campaignID)` |
| `POST /v1/client/coupons/validate` | `client.Coupons.Validate(ctx, ValidateCouponParams{...})` |
| `GET /v1/client/creators/search` | `client.Creators.Search(ctx, params)` |
| `GET /v1/client/sponsors` | `client.Sponsors.Get(ctx, GetSponsorParams{...})` |

### Before/After Examples

**Sponsor Creation:**

```go
// ──── BEFORE ────
body, _ := json.Marshal(map[string]string{
	"userId":     userID,
	"creatorKey": creatorKey,
})
req, _ := http.NewRequest("POST", apiURL+"/v1/server/sponsors", bytes.NewBuffer(body))
req.Header.Set("Authorization", "Bearer "+apiKey)
req.Header.Set("Content-Type", "application/json")
resp, err := http.DefaultClient.Do(req)
// Manual response parsing and error handling...

// ──── AFTER ────
sponsor, err := server.Sponsors.Create(ctx, playcamp.CreateSponsorParams{
	UserID:     userID,
	CreatorKey: creatorKey,
})
if err != nil {
	var conflictErr *playcamp.ConflictError
	if errors.As(err, &conflictErr) {
		// Handle duplicate
	}
	return err
}
```

**Payment Creation:**

```go
// ──── BEFORE ────
payload := map[string]interface{}{
	"userId":           userID,
	"transactionId":    txnID,
	"productId":        productID,
	"amount":           9.99,
	"currency":         "USD",
	"platform":         "iOS",
	"distributionType": "MOBILE_STORE",
	"purchasedAt":      time.Now().Format(time.RFC3339),
}
body, _ := json.Marshal(payload)
req, _ := http.NewRequest("POST", apiURL+"/v1/server/payments", bytes.NewBuffer(body))
req.Header.Set("Authorization", "Bearer "+apiKey)
resp, err := http.DefaultClient.Do(req)
if resp.StatusCode == 409 {
	// duplicate handling...
}

// ──── AFTER ────
distType := playcamp.DistributionMobileStore // *DistributionType — bind to a var to take its address
payment, err := server.Payments.Create(ctx, playcamp.CreatePaymentParams{
	UserID:           userID,
	TransactionID:    txnID,
	ProductID:        productID,
	Amount:           9.99,
	Currency:         "USD",
	Platform:         playcamp.PaymentPlatformIOS,
	DistributionType: &distType,
	PurchasedAt:      time.Now(),
})
if err != nil {
	var conflictErr *playcamp.ConflictError
	if errors.As(err, &conflictErr) {
		log.Printf("Duplicate transaction %s (safe to ignore)", txnID)
		return nil
	}
	return err
}
```

**Webhook Verification:**

```go
// ──── BEFORE ────
mac := hmac.New(sha256.New, []byte(secret))
mac.Write(body)
expected := hex.EncodeToString(mac.Sum(nil))
if !hmac.Equal([]byte(expected), []byte(signature)) {
	http.Error(w, "invalid signature", 401)
	return
}
var payload map[string]interface{}
json.Unmarshal(body, &payload)

// ──── AFTER ────
import "github.com/playcamp/playcamp-go-sdk/webhookutil"

result := webhookutil.Verify(webhookutil.VerifyOptions{
	Payload:   body,
	Signature: r.Header.Get("X-Webhook-Signature"),
	Secret:    os.Getenv("WEBHOOK_SECRET"),
})
if !result.Valid {
	http.Error(w, "invalid signature", http.StatusUnauthorized)
	return
}
for _, event := range result.Payload.Events {
	// Handle typed events
}
```

### Migration Checklist

```
DISCOVERY:
[ ] All raw HTTP calls to PlayCamp API identified
[ ] Each call mapped to SDK equivalent
[ ] Files requiring changes listed

SETUP:
[ ] github.com/playcamp/playcamp-go-sdk installed (go get)
[ ] SDK initialization module created
[ ] Environment variables documented

REPLACEMENT:
[ ] Each raw HTTP call replaced with SDK method
[ ] Manual Authorization headers removed
[ ] API URL constants removed (SDK handles this)
[ ] Response parsing simplified (SDK returns typed structs)
[ ] context.Context passed to all API calls

ERROR HANDLING:
[ ] Manual HTTP status checks replaced with errors.As()
[ ] AuthError (401) handled
[ ] NotFoundError (404) handled
[ ] ConflictError (409) handled for payments
[ ] RateLimitError (429) handled
[ ] Coupon error codes handled for validate/redeem

WEBHOOKS:
[ ] Manual HMAC verification replaced with webhookutil.Verify()
[ ] Raw body reading preserved
[ ] Event types properly typed

CLEANUP:
[ ] Old HTTP utility code removed
[ ] Old PlayCamp API constants removed
[ ] Unused HTTP client imports removed
[ ] Old type definitions removed

VERIFICATION:
[ ] go build succeeds
[ ] go vet passes
[ ] All tests pass
[ ] No remaining raw PlayCamp API calls
```

**Execution notes:** Always create a git commit before starting migration. Migrate one file at a time and run `go build` after each. If a raw HTTP call does not map to any SDK method, flag it for manual review. After migration, run the Audit and Verify modes.

---

## Error Handling

Use `errors.As()` to handle all SDK error types — **never type assertions** (`errors.As()` works through wrapped errors). Every integration MUST handle these errors.

### Error Hierarchy

```
PlayCampError (base)
├── APIError
│   ├── AuthError            (401)
│   ├── ForbiddenError       (403)
│   ├── NotFoundError        (404)
│   ├── ConflictError        (409)
│   ├── ValidationError      (422)
│   └── RateLimitError       (429)
├── InputValidationError      (client-side, fires before the API call)
└── NetworkError              (connectivity issue, not API rejection)
```

```go
import (
	"context"
	"errors"
	"fmt"

	playcamp "github.com/playcamp/playcamp-go-sdk"
)

func createPaymentSafe(ctx context.Context, params playcamp.CreatePaymentParams) (*playcamp.Payment, error) {
	payment, err := server.Payments.Create(ctx, params)
	if err != nil {
		var inputErr *playcamp.InputValidationError
		var authErr *playcamp.AuthError
		var forbiddenErr *playcamp.ForbiddenError
		var validationErr *playcamp.ValidationError
		var notFoundErr *playcamp.NotFoundError
		var conflictErr *playcamp.ConflictError
		var rateLimitErr *playcamp.RateLimitError
		var networkErr *playcamp.NetworkError
		var apiErr *playcamp.APIError

		switch {
		case errors.As(err, &inputErr):
			// Client-side validation failed BEFORE the API call
			return nil, fmt.Errorf("invalid input: field=%s, %s", inputErr.Field, inputErr.Message)
		case errors.As(err, &authErr):
			// 401 - Invalid or expired API key
			return nil, fmt.Errorf("auth failed: %s", authErr.Message)
		case errors.As(err, &forbiddenErr):
			// 403 - Wrong key type (e.g., CLIENT key on SERVER endpoint)
			return nil, fmt.Errorf("forbidden: %s", forbiddenErr.Message)
		case errors.As(err, &validationErr):
			// 422 - Server rejected the parameters
			return nil, fmt.Errorf("validation error: %s", validationErr.Message)
		case errors.As(err, &notFoundErr):
			// 404 - Resource not found
			return nil, fmt.Errorf("not found: %s", notFoundErr.Message)
		case errors.As(err, &conflictErr):
			// 409 - Duplicate transactionId (may be safe for idempotent retries)
			return nil, fmt.Errorf("conflict (duplicate): %s", conflictErr.Message)
		case errors.As(err, &rateLimitErr):
			// 429 - Rate limited, implement backoff and retry
			return nil, fmt.Errorf("rate limited, retry after delay")
		case errors.As(err, &networkErr):
			// Network connectivity issue - retry with backoff
			return nil, fmt.Errorf("network error: %s", networkErr.Message)
		case errors.As(err, &apiErr):
			// Catch-all for other API errors (5xx, etc.)
			return nil, fmt.Errorf("API error %d: %s", apiErr.StatusCode, apiErr.Message)
		default:
			return nil, err
		}
	}
	return payment, nil
}
```

**Best practices:**
- Always check `InputValidationError` first (fires before the API call).
- Handle `ConflictError` (409) for payment/transaction duplicates — may be a safe idempotent retry.
- Implement exponential backoff for `RateLimitError` (429).
- Implement retry logic for `NetworkError`.
- Wrap errors with context using `fmt.Errorf("...: %w", err)` and log with userID/transactionID.

---

## Audit & Review Checklist

**READ-ONLY mode: do not modify any files.** Scan and validate existing integration code, then produce a structured audit report with severity-ranked findings. Use the Migrate mode for fixes.

### 1. SDK Installation & Initialization (Critical)

- [ ] `github.com/playcamp/playcamp-go-sdk` present in `go.mod`
- [ ] `playcamp.NewServer()` used for write operations
- [ ] `playcamp.NewClient()` used for read-only operations (if applicable)
- [ ] API key passed as `keyId:secret` format string
- [ ] API key read from environment variable, NOT hardcoded
- [ ] Single initialization point (not scattered across files)
- [ ] `context.Context` passed to all API calls

### 2. Authentication & Security (Critical)

- [ ] SERVER API key not exposed in client-accessible code
- [ ] No API keys in source code, config files, or comments
- [ ] `.env` file in `.gitignore`
- [ ] No API keys in git history (check with `git log -p --all -S 'ak_server'`)
- [ ] Webhook secret stored in environment variable

### 3. Mandatory API Implementation (High)

**Sponsors:**
- [ ] `server.Sponsors.Create()` implemented
- [ ] `CreateSponsorParams` includes `UserID` and `CreatorKey`
- [ ] Upsert behavior understood (no separate create/update for initial setup)

**Coupons:**
- [ ] `server.Coupons.Validate()` called BEFORE `server.Coupons.Redeem()`
- [ ] `ValidateCouponServerParams` includes both `CouponCode` and `UserID`
- [ ] `validation.Valid` checked before proceeding to redeem
- [ ] Coupon `ErrorCode` values handled appropriately
- [ ] Rewards from `result.Reward` granted to the player after redemption

**Payments:**
- [ ] `server.Payments.Create()` implemented
- [ ] `DistributionType` set (using SDK constants like `playcamp.DistributionMobileStore`)
- [ ] `TransactionID` is unique per transaction
- [ ] `Platform` set using SDK constants (`playcamp.PaymentPlatformIOS`, etc.)
- [ ] `PurchasedAt` is `time.Time` in UTC

### 4. Additional API Implementation (Medium, if applicable)

- [ ] Playtime: `DurationSeconds > 0`, `EndedAt >= StartedAt`, `StartedAt`/`EndedAt` non-zero
- [ ] Playtime: `Recorded == false` (single) / `Status == "SKIPPED"` (bulk) treated as success, not error
- [ ] Bulk Payments/Playtime: batch size <= 1000; per-item `Status` inspected
- [ ] WebView OTT result treated as one-time and short-lived

### 5. Error Handling (High)

- [ ] `errors.As()` used (not type assertions)
- [ ] `InputValidationError` handled
- [ ] `AuthError` (401) handled
- [ ] `ForbiddenError` (403) handled
- [ ] `NotFoundError` (404) handled
- [ ] `ConflictError` (409) handled (especially for payments)
- [ ] `ValidationError` (422) handled
- [ ] `RateLimitError` (429) handled with backoff
- [ ] `NetworkError` handled with retry
- [ ] `APIError` as catch-all
- [ ] Errors logged with context (userID, transactionID, etc.)

### 6. Webhook Integration (High, if applicable)

- [ ] Raw body read with `io.ReadAll()` before any JSON parsing
- [ ] `webhookutil.Verify()` called before processing
- [ ] `X-Webhook-Signature` header checked for presence
- [ ] All 7 event types handled in switch statement
- [ ] Unknown event types do not cause errors
- [ ] Individual event errors do not block batch processing
- [ ] Returns 200 for valid webhooks
- [ ] `WEBHOOK_SECRET` not hardcoded
- [ ] `webhookutil` imported from `github.com/playcamp/playcamp-go-sdk/webhookutil`

### 7. Configuration (Medium)

- [ ] Environment set via `playcamp.WithEnvironment()`
- [ ] `EnvironmentSandbox` used for development, `EnvironmentLive` for production
- [ ] Test mode (`WithTestMode`) driven by environment variable, not hardcoded
- [ ] Debug mode disabled in production
- [ ] Timeout configured appropriately

### 8. Go Idioms (Medium)

- [ ] `context.Context` propagated through call chain
- [ ] Pointer helpers used for optional fields (`playcamp.String()`, `playcamp.Int()`, etc.)
- [ ] Pagination handled correctly (single page or iterator pattern)
- [ ] `iter.Advance()` called in iterator loops
- [ ] `iter.Err()` checked after iterator completion
- [ ] Errors wrapped with context using `fmt.Errorf("...: %w", err)`

### Severity Levels

| Level | Description |
|-------|-------------|
| **Critical** | Security vulnerability or will cause runtime failure |
| **High** | Incorrect API usage that will produce wrong results |
| **Medium** | Best practice violation or potential issue |
| **Low** | Style or optimization suggestion |

### Audit Report Template

```markdown
# PlayCamp Go SDK Audit Report

**Project:** [name]
**Date:** [date]
**SDK Version:** [version from go.mod]

## Summary
- Critical: [count]
- High: [count]
- Medium: [count]
- Low: [count]

## Critical Issues
| # | File:Line | Issue | Recommended Fix |
|---|-----------|-------|-----------------|
| 1 | path:line | Description | Fix description |

## High Issues
| # | File:Line | Issue | Recommended Fix |
|---|-----------|-------|-----------------|

## Medium Issues
| # | File:Line | Issue | Recommended Fix |
|---|-----------|-------|-----------------|

## Low Issues
| # | File:Line | Issue | Recommended Fix |
|---|-----------|-------|-----------------|

## Files Audited
- [List of all files examined]
```

**Audit execution notes:** Scan the entire project, not just specific directories. Config files and build scripts may contain violations. Always include exact file path and line number. If no PlayCamp SDK usage is found, report that as the finding. Do not modify any files in this mode.

---

## Build & Config Verification

Verify the integration compiles, dependencies are installed, environment is configured, and best practices are met. **Read-only**: this mode does not modify files. Run all checks even if early ones fail — a complete report is more useful than a partial one. For runtime checks, only execute if a sandbox API key is available. Mark webhook checks N/A if the project does not use webhooks.

### Step 1: Dependency Check

```bash
grep "github.com/playcamp/playcamp-go-sdk" go.mod
grep "github.com/playcamp/playcamp-go-sdk" go.sum
go mod verify
```

### Step 2: Build Verification

```bash
go build ./...
go vet ./...
```

### Step 3: Import Verification

```bash
grep -rn '"github.com/playcamp/playcamp-go-sdk"' .
grep -rn '"github.com/playcamp/playcamp-go-sdk/webhookutil"' .
```

### Step 4: SDK Initialization Check

```bash
grep -rn "playcamp.NewServer\|pc.NewServer" . --include="*.go"
grep -rn "playcamp.NewClient\|pc.NewClient" . --include="*.go"
grep -rn 'os.Getenv.*API_KEY\|os.Getenv.*SERVER_KEY' . --include="*.go"
```

### Step 5: Security Checks

```bash
grep -rn 'ak_server_\|ak_client_' . --include="*.go"
grep -rn '"[a-z_]*:[a-zA-Z0-9]' . --include="*.go" | grep -i playcamp
grep -n '\.env' .gitignore
git ls-files '*.env' '.env*' 2>/dev/null
```

### Step 6: Integration Pattern Verification

```bash
grep -rn "Sponsors.Create" . --include="*.go"
grep -rn "Coupons.Validate" . --include="*.go"
grep -rn "Coupons.Redeem" . --include="*.go"
grep -rn "Payments.Create" . --include="*.go"
grep -rn "PlaytimeSessions.Create\|Payments.CreateBulk\|Webview.CreateOTT" . --include="*.go"
grep -rn "errors.As" . --include="*.go"
grep -rn "DistributionType\|DistributionMobile\|DistributionPC" . --include="*.go"
grep -rn "context.Context\|ctx context" . --include="*.go" | head -5
grep -rn 'WithTestMode(true)' . --include="*.go"
grep -rn 'IsTest.*true\|isTest.*true' . --include="*.go"
```

### Step 7: Webhook Verification (if applicable)

```bash
grep -rn "webhookutil.Verify" . --include="*.go"
grep -rn "io.ReadAll\|ioutil.ReadAll" . --include="*.go"
grep -rn "X-Webhook-Signature" . --include="*.go"
grep -rn "WebhookEvent" . --include="*.go"
```

### Step 8: Runtime Check (if sandbox key available)

```bash
go test ./...
go test -race ./...
```

### Verification Report Template

```markdown
# PlayCamp Go SDK Verification Report

**Project:** [project name]
**SDK Version:** [version from go.mod]
**Go Version:** [version]

## Build Status: PASS / FAIL
| Check | Status | Details |
|-------|--------|---------|
| go build | PASS/FAIL | [error count] |
| go vet | PASS/FAIL | [warning count] |
| SDK dependency in go.mod | PASS/FAIL | [version] |
| go mod verify | PASS/FAIL | [details] |
| Go version >= 1.21 | PASS/FAIL | [version] |

## Configuration Status: PASS / FAIL
| Check | Status | Details |
|-------|--------|---------|
| SERVER_API_KEY from env | PASS/FAIL | [method used] |
| CLIENT_API_KEY from env | PASS/FAIL/N/A | [method used] |
| WEBHOOK_SECRET from env | PASS/WARN/N/A | [set/missing] |
| Environment config | PASS/WARN | [value or default] |
| No hardcoded keys | PASS/FAIL | [file:line if found] |
| No .env in git | PASS/FAIL | [files if found] |

## Integration Status: PASS / FAIL
| Check | Status | Details |
|-------|--------|---------|
| SDK initialization | PASS/FAIL | [NewServer/NewClient] |
| Sponsors.Create used | PASS/FAIL | [file:line] |
| Coupons.Validate used | PASS/FAIL | [file:line] |
| Coupons.Redeem used | PASS/FAIL | [file:line] |
| Payments.Create used | PASS/FAIL | [file:line] |
| DistributionType set | PASS/FAIL/N/A | [details] |
| errors.As() used | PASS/FAIL | [count] |
| isTest not hardcoded | PASS/WARN | [file:line if found] |
| context.Context used | PASS/FAIL | [details] |
| Validate before Redeem | PASS/WARN/N/A | [details] |
| No raw HTTP calls | PASS/FAIL | [count remaining] |

## Webhook Status: PASS / FAIL / N/A
| Check | Status | Details |
|-------|--------|---------|
| webhookutil.Verify used | PASS/FAIL/N/A | [file:line] |
| Raw body reading | PASS/FAIL/N/A | [io.ReadAll] |
| Signature header check | PASS/FAIL/N/A | [details] |
| Event types handled | PASS/WARN/N/A | [count] |

## Test Status: PASS / FAIL / SKIPPED
| Check | Status | Details |
|-------|--------|---------|
| go test | PASS/FAIL/SKIP | [details] |
| go test -race | PASS/FAIL/SKIP | [details] |

## Issues Found
### Critical
- [List critical issues with file:line references]
### Warnings
- [List warnings and recommendations]

## Overall Result: PASS / FAIL
```

---

## Common Mistakes

### Integration

1. **Hardcoding API keys** — always use environment variables.
2. **Hardcoding test mode** — use an env var (`os.Getenv("SDK_TEST_MODE") == "true"`) so production is never in test mode.
3. **Missing `DistributionType` on payments** — this field is required.
4. **Non-unique `TransactionID`** — each payment must have a globally unique ID; duplicates return 409.
5. **Skipping coupon validation** — always validate before redeeming.
6. **Not handling 409 on payments** — duplicate TransactionID is expected during retries (safe idempotent retry).
7. **Using Client for write operations** — Client keys are read-only; use Server for mutations.
8. **Not granting rewards after coupon redemption** — SDK redeems but your game must grant items.
9. **Using type assertions instead of `errors.As()`** — `errors.As()` works through wrapped errors.
10. **Forgetting `context.Context`** — all API methods require `ctx` as the first argument.
11. **Not using pointer helpers** — use `playcamp.String()`, `playcamp.Int()` for optional fields.
12. **Exposing the SERVER key client-side** — only use it in server-side environments.

### New Features (Playtime / Bulk / WebView)

13. **Treating a duplicate `sessionId` as an error** — single `Create` returns `Recorded: false`; bulk returns `Status: "SKIPPED"`. Both are success.
14. **Invalid playtime times** — `DurationSeconds` must be `> 0` and `EndedAt >= StartedAt`; the SDK pre-validates and returns `InputValidationError`. Pass `time.Time` (SDK normalizes to UTC/RFC3339) — do not pre-format strings.
15. **Exceeding bulk limits** — bulk Payments and Playtime accept at most **1000** items per call; chunk larger sets.
16. **Ignoring per-item bulk results** — inspect each `Results[i].Status` (SUCCESS/SKIPPED/FAILED); a non-error top-level call can still have failed items.
17. **Bad `CreatorKey` on playtime** — must be exactly 5 uppercase alphanumeric characters.
18. **Reusing a WebView OTT** — it is one-time and short-lived (check `ExpiresAt`); mint a fresh one per session.

### Webhooks

19. **Using `json.Decoder` before reading raw body** — must read raw bytes first (`io.ReadAll`) for signature verification.
20. **Losing the webhook secret** — only returned once at creation; store immediately in `WEBHOOK_SECRET`.
21. **Manual HMAC comparison** — use `webhookutil.Verify()` (timing-safe), never hand-rolled HMAC.
22. **Treating payload as a single event** — always a batch; iterate over `result.Payload.Events`.
23. **Failing on unknown event types** — log a warning but do not return an error (new types may be added).
24. **Letting one bad event break the batch** — handle each event in isolation.
25. **Not returning 200** — non-2xx causes retries and duplicate processing.
26. **Not handling the new events** — handle `payment.bulk_created` and `sponsor.ended` in addition to the original 5.

---

## Official Documentation Reference

When you need additional details or the latest API specifications, fetch these pages using the WebFetch tool:

| Topic | URL |
|-------|-----|
| Integration Overview | `https://playcamp.io/docs/guides/developers/game-integration/overview.md` |
| Sponsor Guide | `https://playcamp.io/docs/guides/developers/game-integration/sponsor.md` |
| Coupon Guide | `https://playcamp.io/docs/guides/developers/game-integration/coupon.md` |
| Payment Guide | `https://playcamp.io/docs/guides/developers/game-integration/payment.md` |
| Webhook Guide | `https://playcamp.io/docs/guides/developers/game-integration/webhook.md` |
| Test Mode | `https://playcamp.io/docs/guides/developers/game-integration/test-mode.md` |
| API Reference (all endpoints) | `https://playcamp.io/docs/guides/developers/game-integration/reference.md` |
| Create Webhook API | `https://playcamp.io/docs/api-reference/server-webhook/create-webhook.md` |
| Webhook Logs API | `https://playcamp.io/docs/api-reference/server-webhook/get-webhook-logs.md` |
| Test Webhook API | `https://playcamp.io/docs/api-reference/server-webhook/test-webhook.md` |
| Full docs index | `https://playcamp.io/docs/llms.txt` |

**When to fetch:** If the user's request involves an API field, error code, or behavior not covered in this agent file, fetch the relevant page above before generating code.
