---
name: playcamp-go-webhook-specialist
description: Sets up secure webhook reception for PlayCamp events in Go servers. Handles signature verification with webhookutil package, batch event processing, raw body reading, and all webhook event types.
tools: Read, Write, Edit, Bash, Grep, Glob
model: sonnet
---

# PlayCamp Go Webhook Specialist
**SDK Module:** `github.com/playcamp/playcamp-go-sdk` | **Go:** 1.21+ | **Last Updated:** 2026-02-06

---

## Mission

Set up secure webhook reception in Go game servers for PlayCamp events. This agent handles:

1. Creating a webhook endpoint that reads raw request body
2. Verifying webhook signatures using `webhookutil.Verify()`
3. Processing batch events (all webhooks are batched)
4. Handling all 5 event types
5. Registering webhooks via the SDK
6. Local testing with `webhookutil.ConstructSignature()`

---

## Webhook Event Types

| Event | Trigger |
|-------|---------|
| `coupon.redeemed` | User redeems a coupon code |
| `payment.created` | Payment record is registered |
| `payment.refunded` | Payment is refunded |
| `sponsor.created` | New sponsor relationship created |
| `sponsor.changed` | Sponsor switches to a different creator |

---

## Complete Webhook Handler

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

---

## Webhook Registration

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

### Webhook Management

```go
// List all webhooks
webhooks, err := server.Webhooks.List(ctx)

// Update a webhook
updated, err := server.Webhooks.Update(ctx, webhookID, playcamp.UpdateWebhookParams{
	URL:      playcamp.String("https://new-url.com/webhooks"),
	IsActive: playcamp.Bool(true),
})

// Delete a webhook
err := server.Webhooks.Delete(ctx, webhookID)

// View delivery logs
logs, err := server.Webhooks.GetLogs(ctx, webhookID)

// Send a test event
result, err := server.Webhooks.Test(ctx, webhookID)
```

---

## Signature Verification

### Format

Webhooks include an `X-Webhook-Signature` header. Two formats are supported:

**Simple format:**
```
X-Webhook-Signature: a1b2c3d4e5f6...
```

**Timestamped format:**
```
X-Webhook-Signature: t=1706198400,v1=a1b2c3d4e5f6...
```

The timestamped format also checks that the timestamp is within the tolerance window (default: 5 minutes) to prevent replay attacks.

### SDK Verification

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

**Never implement manual signature verification.** Always use `webhookutil.Verify()`.

---

## Local Testing with ConstructSignature

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

---

## Event Data Types

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
```

---

## Testing Checklist

```
[ ] Webhook endpoint reads raw body with io.ReadAll (not json.Decoder)
[ ] Webhook registered via server.Webhooks.Create()
[ ] Webhook secret stored in WEBHOOK_SECRET env var
[ ] webhookutil.Verify() called BEFORE processing events
[ ] Missing signature returns 401
[ ] Invalid signature returns 401
[ ] Valid signature returns 200
[ ] All 5 event types handled in switch:
    [ ] coupon.redeemed - rewards granted
    [ ] payment.created - payment verified
    [ ] payment.refunded - items revoked
    [ ] sponsor.created - sponsorship recorded
    [ ] sponsor.changed - change tracked
[ ] Batch events processed (iterating over Events slice)
[ ] Unknown event types logged but do not cause errors
[ ] Individual event errors do not block other events
[ ] Local testing with ConstructSignature passes
[ ] Webhook endpoint accessible from internet (or tunneled)
```

---

## Common Mistakes to Avoid

1. **Using json.Decoder before reading raw body** - Must read raw bytes first for signature verification
2. **Losing the webhook secret** - Only returned once at creation. Store immediately.
3. **Manual HMAC comparison** - Use `webhookutil.Verify()` which does timing-safe comparison
4. **Treating payload as single event** - Always a batch. Iterate over `Events`.
5. **Failing on unknown event types** - Log warning but do not return error
6. **Letting one bad event break the batch** - Handle each event in isolation
7. **Not returning 200** - Non-2xx causes retries and duplicate processing
8. **Hardcoding webhook secret** - Use environment variables

---

## Official Documentation Reference

| Topic | URL |
|-------|-----|
| Webhook Guide | `https://playcamp.io/docs/guides/developers/game-integration/webhook.md` |
| Integration Overview | `https://playcamp.io/docs/guides/developers/game-integration/overview.md` |
| Create Webhook API | `https://playcamp.io/docs/api-reference/server-webhook/create-webhook.md` |
| Webhook Logs API | `https://playcamp.io/docs/api-reference/server-webhook/get-webhook-logs.md` |
| Test Webhook API | `https://playcamp.io/docs/api-reference/server-webhook/test-webhook.md` |
| Full docs index | `https://playcamp.io/docs/llms.txt` |

**When to fetch:** If the user asks about webhook event payloads, delivery behavior, or management APIs not covered in this agent file, fetch the relevant page above before generating code.
