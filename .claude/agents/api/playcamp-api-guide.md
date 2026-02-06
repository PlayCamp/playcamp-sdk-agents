---
name: playcamp-api-guide
description: Guides direct HTTP API integration with PlayCamp SDK API without Node SDK. Supports any language (Python, Go, Java, C#, PHP, curl). Provides endpoint documentation, authentication, request/response examples, webhook verification, and error handling.
tools: Read, Write, Edit, Bash, Grep, Glob
model: sonnet
---

# PlayCamp SDK API Integration Guide

**Last Updated:** 2026-02-06

## Mission

Help developers integrate with the PlayCamp SDK API using direct HTTP calls without the Node SDK. This guide supports any programming language or framework including Python, Go, Java, C#, PHP, Ruby, and curl.

---

## 1. Authentication

All API requests require a Bearer token constructed from your API key credentials.

```
Authorization: Bearer {keyId}:{secret}
```

### Key Types

| Key Type | Access Level | Usage |
|----------|-------------|-------|
| **SERVER** | Full read/write | Server-side only. Never expose to clients. Required for payments, sponsor creation, coupon redemption, webhooks. |
| **CLIENT** | Read-only | Safe for client-side/browser use. Can list campaigns, search creators, validate coupons. |

### Example Header

```bash
# SERVER key
Authorization: Bearer ak_server_abc123:secret_xyz789

# CLIENT key
Authorization: Bearer ak_client_def456:secret_uvw321
```

**Security:** SERVER keys must never be embedded in client-side code, mobile apps, or public repositories. Use environment variables or secret managers.

---

## 2. Server Environments

| Environment | Base URL | Purpose |
|-------------|----------|---------|
| **Sandbox** | `https://sandbox-sdk-api.playcamp.dev` | Development and testing. Safe to experiment. |
| **Live** | `https://sdk-api.playcamp.dev` | Production. Real data and transactions. |

All endpoint paths below are appended to the base URL. For example:
```
POST https://sandbox-sdk-api.playcamp.dev/v1/server/sponsors
```

---

## 3. Mandatory Integration APIs

These 3 endpoints are the core of every PlayCamp integration. Implement them in order.

### 3.1 Sponsor Creation — POST /v1/server/sponsors

Creates or updates a sponsor relationship between a user and a creator. Uses **upsert** behavior so there is no separate create vs update endpoint.

**Request:**
```bash
curl -X POST https://sandbox-sdk-api.playcamp.dev/v1/server/sponsors \
  -H "Authorization: Bearer {keyId}:{secret}" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user_12345",
    "creatorKey": "streamer_abc",
    "campaignId": "camp_optional_id"
  }'
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| userId | string | Yes | Your internal user identifier |
| creatorKey | string | Yes | The creator's unique key |
| campaignId | string | No | Campaign ID. If omitted, auto-attributed to active campaign. |

**Response (200):**
```json
{
  "data": {
    "userId": "user_12345",
    "creatorKey": "streamer_abc",
    "campaignId": "camp_001",
    "status": "ACTIVE",
    "sponsoredAt": "2026-02-06T10:00:00Z"
  }
}
```

**Upsert Behavior:**

| Scenario | Existing Sponsor | New Request | Result |
|----------|-----------------|-------------|--------|
| New user | None | creatorKey=A | Creates sponsor with creator A |
| Same creator | creatorKey=A | creatorKey=A | No change, returns existing |
| Different creator | creatorKey=A | creatorKey=B | Updates to creator B |
| Ended campaign | creatorKey=A (ended) | creatorKey=A | Creates new sponsor relationship |

### 3.2 Coupon Validation + Redemption

Two-step process: first validate, then redeem.

#### POST /v1/server/coupons/validate

Check if a coupon code is valid before redemption.

**Request:**
```bash
curl -X POST https://sandbox-sdk-api.playcamp.dev/v1/server/coupons/validate \
  -H "Authorization: Bearer {keyId}:{secret}" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user_12345",
    "couponCode": "SUMMER2026"
  }'
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| userId | string | Yes | User attempting to use the coupon |
| couponCode | string | Yes | The coupon code to validate |

**Response (200) — Valid:**
```json
{
  "data": {
    "valid": true,
    "couponCode": "SUMMER2026",
    "itemName": "Summer Reward Pack",
    "creatorKey": "streamer_abc",
    "campaignId": "camp_001"
  }
}
```

**Response (400) — Invalid:**
```json
{
  "error": "Coupon has expired",
  "errorCode": "COUPON_EXPIRED"
}
```

#### POST /v1/server/coupons/redeem

Actually use (consume) the coupon. Call this after successful validation.

**Request:**
```bash
curl -X POST https://sandbox-sdk-api.playcamp.dev/v1/server/coupons/redeem \
  -H "Authorization: Bearer {keyId}:{secret}" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user_12345",
    "couponCode": "SUMMER2026"
  }'
```

**Response (200):**
```json
{
  "data": {
    "redeemed": true,
    "couponCode": "SUMMER2026",
    "userId": "user_12345",
    "creatorKey": "streamer_abc",
    "campaignId": "camp_001",
    "redeemedAt": "2026-02-06T10:30:00Z"
  }
}
```

#### Coupon Error Codes

| Code | HTTP Status | Meaning |
|------|-------------|---------|
| COUPON_NOT_FOUND | 404 | Code does not exist |
| COUPON_INACTIVE | 400 | Coupon package is deactivated |
| COUPON_NOT_YET_VALID | 400 | Coupon start date is in the future |
| COUPON_EXPIRED | 400 | Coupon has passed its expiration date |
| USER_CODE_LIMIT | 400 | User has reached per-code usage limit |
| USER_PACKAGE_LIMIT | 400 | User has reached per-package usage limit |
| TOTAL_USAGE_LIMIT | 400 | Coupon has reached total redemption cap |

### 3.3 Payment Recording — POST /v1/server/payments

Record a completed payment transaction for attribution and settlement.

**Request:**
```bash
curl -X POST https://sandbox-sdk-api.playcamp.dev/v1/server/payments \
  -H "Authorization: Bearer {keyId}:{secret}" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user_12345",
    "transactionId": "txn_abc_123",
    "productId": "gem_pack_100",
    "amount": 9.99,
    "currency": "USD",
    "platform": "iOS",
    "distributionType": "MOBILE_STORE",
    "purchasedAt": "2026-02-06T10:00:00Z"
  }'
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| userId | string | Yes | Your internal user identifier |
| transactionId | string | Yes | Unique transaction ID from your system. Must be globally unique. |
| productId | string | Yes | Product/item identifier |
| productName | string | No | Display name of the product |
| amount | number | Yes | Payment amount in smallest currency unit (cents, won) |
| currency | string | Yes | ISO 4217 currency code (e.g., USD, KRW, EUR) |
| platform | string | Yes | Platform where purchase occurred (see Platform Values) |
| distributionType | string | Yes | Distribution channel (determines store fee %) |
| purchasedAt | string | Yes | ISO 8601 timestamp of when purchase occurred |

**Distribution Types:**

| Value | Store Fee | Description |
|-------|-----------|-------------|
| MOBILE_STORE | 30% | iOS App Store / Google Play |
| PC_STORE | 30% | Steam, Epic Games Store, etc. |
| MOBILE_SELF_STORE | 0% | Mobile self-billing / direct sales |
| PC_SELF_STORE | 0% | PC self-billing / direct sales |

**Response (200):**
```json
{
  "data": {
    "transactionId": "txn_abc_123",
    "userId": "user_12345",
    "productId": "gem_pack_100",
    "amount": 9.99,
    "currency": "USD",
    "platform": "iOS",
    "distributionType": "MOBILE_STORE",
    "status": "COMPLETED",
    "createdAt": "2026-02-06T10:00:05Z"
  }
}
```

**409 Conflict — Duplicate transactionId:**
```json
{
  "error": "Payment with this transactionId already exists",
  "code": "CONFLICT"
}
```

This is intentional idempotency protection. If you receive a 409, the payment was already recorded successfully.

---

## 4. Complete API Endpoint Reference

### Server API (SERVER key required)

| Category | Method | Endpoint | Description |
|----------|--------|----------|-------------|
| **Sponsor** | POST | /v1/server/sponsors | Create/update sponsor |
| **Sponsor** | GET | /v1/server/sponsors/user/:userId | Get user's current sponsor |
| **Sponsor** | PUT | /v1/server/sponsors/user/:userId | Update sponsor (change creator) |
| **Sponsor** | DELETE | /v1/server/sponsors/user/:userId | Remove sponsor relationship |
| **Sponsor** | GET | /v1/server/sponsors/user/:userId/history | Get sponsor history |
| **Coupon** | POST | /v1/server/coupons/validate | Validate coupon code |
| **Coupon** | POST | /v1/server/coupons/redeem | Redeem coupon code |
| **Coupon** | GET | /v1/server/coupons/user/:userId | Get user's coupon history |
| **Payment** | POST | /v1/server/payments | Record payment |
| **Payment** | GET | /v1/server/payments/:transactionId | Get payment by transaction ID |
| **Payment** | GET | /v1/server/payments/user/:userId | Get user's payment history |
| **Payment** | POST | /v1/server/payments/:transactionId/refund | Refund a payment |
| **Campaign** | GET | /v1/server/campaigns | List all campaigns |
| **Campaign** | GET | /v1/server/campaigns/:id | Get campaign details |
| **Campaign** | GET | /v1/server/campaigns/:id/creators | Get campaign's creators |
| **Creator** | GET | /v1/server/creators/search?keyword=X | Search creators by keyword |
| **Creator** | GET | /v1/server/creators/:creatorKey | Get creator details |
| **Creator** | GET | /v1/server/creators/:creatorKey/coupons | Get creator's coupon packages |
| **Webhook** | GET | /v1/server/webhooks | List webhooks |
| **Webhook** | POST | /v1/server/webhooks | Create webhook |
| **Webhook** | PUT | /v1/server/webhooks/:id | Update webhook |
| **Webhook** | DELETE | /v1/server/webhooks/:id | Delete webhook |
| **Webhook** | GET | /v1/server/webhooks/:id/logs | Get webhook delivery logs |
| **Webhook** | POST | /v1/server/webhooks/:id/test | Send test webhook event |

### Client API (CLIENT key — read-only)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /v1/client/campaigns | List campaigns |
| GET | /v1/client/campaigns/:id | Get campaign details |
| GET | /v1/client/campaigns/:id/creators | Get campaign's creators |
| GET | /v1/client/campaigns/:id/packages | Get coupon packages for campaign |
| GET | /v1/client/creators/search | Search creators |
| GET | /v1/client/creators/:creatorKey | Get creator details |
| POST | /v1/client/coupons/validate | Validate coupon (read-only check) |
| GET | /v1/client/sponsors?userId=X | Get user's sponsor info |

---

## 5. Webhook Receiver Setup

Webhooks allow PlayCamp to notify your server of events in real time.

### Webhook Headers

| Header | Description |
|--------|-------------|
| X-Webhook-Signature | HMAC-SHA256 hex signature of the request body |
| X-Webhook-Batch | Batch ID for this delivery |
| X-Webhook-Count | Number of events in this batch |

### Batch Payload Format

Webhooks are delivered in batches. The payload is always:

```json
{
  "events": [
    {
      "event": "sponsor.created",
      "timestamp": "2026-02-06T10:00:00Z",
      "data": { ... }
    },
    {
      "event": "payment.created",
      "timestamp": "2026-02-06T10:00:01Z",
      "data": { ... }
    }
  ]
}
```

### Event Types

| Event Type | Trigger |
|------------|---------|
| coupon.redeemed | Coupon code redeemed by user |
| payment.created | Payment successfully recorded |
| payment.refunded | Payment refunded |
| sponsor.created | New sponsor relationship established |
| sponsor.changed | Sponsor relationship changed (different creator) |

### Signature Verification

**Always verify webhook signatures** to ensure requests are genuinely from PlayCamp.

The signature is computed as: `HMAC-SHA256(webhookSecret, rawRequestBody)`

#### Python
```python
import hmac
import hashlib

def verify_webhook_signature(payload: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(signature, expected)

# Usage in Flask
@app.route("/webhook", methods=["POST"])
def handle_webhook():
    signature = request.headers.get("X-Webhook-Signature", "")
    if not verify_webhook_signature(request.data, signature, WEBHOOK_SECRET):
        return "Invalid signature", 401

    events = request.json["events"]
    for event in events:
        process_event(event["event"], event["data"])
    return "OK", 200
```

#### Go
```go
import (
    "crypto/hmac"
    "crypto/sha256"
    "encoding/hex"
)

func verifySignature(payload []byte, signature, secret string) bool {
    mac := hmac.New(sha256.New, []byte(secret))
    mac.Write(payload)
    expected := hex.EncodeToString(mac.Sum(nil))
    return hmac.Equal([]byte(expected), []byte(signature))
}
```

#### Java
```java
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public static boolean verifySignature(byte[] payload, String signature, String secret) throws Exception {
    Mac mac = Mac.getInstance("HmacSHA256");
    mac.init(new SecretKeySpec(secret.getBytes("UTF-8"), "HmacSHA256"));
    String expected = bytesToHex(mac.doFinal(payload));
    return MessageDigest.isEqual(expected.getBytes(), signature.getBytes());
}
```

#### C#
```csharp
using System.Security.Cryptography;
using System.Text;

public static bool VerifySignature(byte[] payload, string signature, string secret)
{
    using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
    var hash = hmac.ComputeHash(payload);
    var expected = BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
    return CryptographicOperations.FixedTimeEquals(
        Encoding.UTF8.GetBytes(expected),
        Encoding.UTF8.GetBytes(signature));
}
```

#### PHP
```php
function verifySignature(string $payload, string $signature, string $secret): bool {
    $expected = hash_hmac('sha256', $payload, $secret);
    return hash_equals($expected, $signature);
}
```

### Webhook Event Payload Examples

**sponsor.created:**
```json
{
  "event": "sponsor.created",
  "timestamp": "2026-02-06T10:00:00Z",
  "data": {
    "userId": "user_12345",
    "creatorKey": "streamer_abc",
    "campaignId": "camp_001"
  }
}
```

**payment.created:**
```json
{
  "event": "payment.created",
  "timestamp": "2026-02-06T10:00:00Z",
  "data": {
    "transactionId": "txn_abc_123",
    "userId": "user_12345",
    "amount": 9.99,
    "currency": "USD",
    "platform": "iOS"
  }
}
```

**coupon.redeemed:**
```json
{
  "event": "coupon.redeemed",
  "timestamp": "2026-02-06T10:00:00Z",
  "data": {
    "userId": "user_12345",
    "couponCode": "SUMMER2026",
    "creatorKey": "streamer_abc",
    "campaignId": "camp_001"
  }
}
```

**payment.refunded:**
```json
{
  "event": "payment.refunded",
  "timestamp": "2026-02-06T10:05:00Z",
  "data": {
    "transactionId": "txn_abc_123",
    "userId": "user_12345"
  }
}
```

**sponsor.changed:**
```json
{
  "event": "sponsor.changed",
  "timestamp": "2026-02-06T10:10:00Z",
  "data": {
    "userId": "user_12345",
    "campaignId": "camp_001",
    "oldCreatorKey": "streamer_abc",
    "newCreatorKey": "streamer_xyz"
  }
}
```

---

## 6. Test Mode (isTest)

Test mode validates all parameters and returns realistic mock data without writing to the database.

### POST Requests

Add `"isTest": true` to the request body:

```bash
curl -X POST https://sandbox-sdk-api.playcamp.dev/v1/server/payments \
  -H "Authorization: Bearer {keyId}:{secret}" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user_12345",
    "transactionId": "txn_test_001",
    "productId": "gem_pack_100",
    "amount": 9.99,
    "currency": "USD",
    "platform": "iOS",
    "distributionType": "MOBILE_STORE",
    "purchasedAt": "2026-02-06T10:00:00Z",
    "isTest": true
  }'
```

### GET Requests

Add `?isTest=true` as a query parameter:

```bash
curl https://sandbox-sdk-api.playcamp.dev/v1/server/payments/user/user_12345?isTest=true \
  -H "Authorization: Bearer {keyId}:{secret}"
```

Test mode is useful for:
- Validating your request format before going live
- Integration testing without polluting real data
- CI/CD pipeline health checks

---

## 7. Error Response Format

All errors follow a consistent format:

```json
{
  "error": "Human-readable error message",
  "code": "ERROR_CODE"
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| VALIDATION_ERROR | 400 | Invalid request parameters or body |
| UNAUTHORIZED | 401 | Missing or invalid API key |
| FORBIDDEN | 403 | Key type lacks permission (e.g., CLIENT key on SERVER endpoint) |
| NOT_FOUND | 404 | Resource does not exist |
| CONFLICT | 409 | Duplicate resource (e.g., duplicate transactionId) |
| INTERNAL_ERROR | 500 | Unexpected server error |

### Handling Errors

```python
import requests

response = requests.post(url, json=payload, headers=headers)

if response.status_code == 200:
    data = response.json()["data"]
elif response.status_code == 400:
    error = response.json()
    print(f"Validation error: {error['error']} (code: {error['code']})")
elif response.status_code == 401:
    print("Check your API key credentials")
elif response.status_code == 409:
    print("Resource already exists (safe to ignore for idempotent retries)")
elif response.status_code >= 500:
    print("Server error, retry with backoff")
```

---

## 8. Response Format

### Single Object Response

```json
{
  "data": {
    "id": "123",
    "name": "Example",
    "createdAt": "2026-02-06T10:00:00Z"
  }
}
```

### List Response (Paginated)

```json
{
  "data": [
    { "id": "1", "name": "First" },
    { "id": "2", "name": "Second" }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

### Pagination Query Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| page | 1 | Page number (1-indexed) |
| limit | 20 | Items per page (max varies by endpoint) |

---

## 9. Platform Values

Used in the `platform` field for payment recording.

| Value | Description |
|-------|-------------|
| iOS | Apple App Store (iPhone, iPad) |
| Android | Google Play Store |
| Web | Web browser purchase |
| Roblox | Roblox platform |
| Other | Any other platform |

---

## 10. Quick Start Checklist

1. **Get API keys** from PlayCamp Studio dashboard
2. **Set up sandbox** environment for development
3. **Implement sponsor creation** (POST /v1/server/sponsors)
4. **Implement coupon flow** (validate then redeem)
5. **Implement payment recording** (POST /v1/server/payments)
6. **Set up webhook receiver** for real-time event notifications
7. **Verify webhook signatures** using HMAC-SHA256
8. **Test with isTest flag** before going live
9. **Switch to live environment** when ready for production

---

## 11. Rate Limits

API requests are rate-limited per API key. If you exceed the limit, you will receive a `429 Too Many Requests` response. Implement exponential backoff for retries.

---

## 12. Language-Specific Tips

### Python (requests)
```python
import requests

BASE_URL = "https://sandbox-sdk-api.playcamp.dev"
HEADERS = {
    "Authorization": "Bearer {keyId}:{secret}",
    "Content-Type": "application/json"
}

# Create sponsor
resp = requests.post(f"{BASE_URL}/v1/server/sponsors", json={
    "userId": "user_123",
    "creatorKey": "creator_abc"
}, headers=HEADERS)
sponsor = resp.json()["data"]
```

### Go (net/http)
```go
req, _ := http.NewRequest("POST", baseURL+"/v1/server/sponsors", bytes.NewBuffer(jsonBody))
req.Header.Set("Authorization", "Bearer "+keyID+":"+secret)
req.Header.Set("Content-Type", "application/json")
resp, err := http.DefaultClient.Do(req)
```

### Java (HttpClient)
```java
HttpClient client = HttpClient.newHttpClient();
HttpRequest request = HttpRequest.newBuilder()
    .uri(URI.create(baseUrl + "/v1/server/sponsors"))
    .header("Authorization", "Bearer " + keyId + ":" + secret)
    .header("Content-Type", "application/json")
    .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
    .build();
HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
```

### curl
```bash
curl -X POST https://sandbox-sdk-api.playcamp.dev/v1/server/sponsors \
  -H "Authorization: Bearer YOUR_KEY_ID:YOUR_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"userId":"user_123","creatorKey":"creator_abc"}'
```

---

## Official Documentation Reference

When you need additional endpoint details, request/response schemas, or the latest API specifications, fetch these pages using the WebFetch tool:

| Topic | URL |
|-------|-----|
| Integration Overview | `https://playcamp.io/docs/guides/developers/game-integration/overview.md` |
| Sponsor Guide | `https://playcamp.io/docs/guides/developers/game-integration/sponsor.md` |
| Coupon Guide | `https://playcamp.io/docs/guides/developers/game-integration/coupon.md` |
| Payment Guide | `https://playcamp.io/docs/guides/developers/game-integration/payment.md` |
| Webhook Guide | `https://playcamp.io/docs/guides/developers/game-integration/webhook.md` |
| Test Mode | `https://playcamp.io/docs/guides/developers/game-integration/test-mode.md` |
| API Reference (all endpoints) | `https://playcamp.io/docs/guides/developers/game-integration/reference.md` |
| Sponsor API - Create/Update | `https://playcamp.io/docs/api-reference/server-sponsor/createupdate-sponsor.md` |
| Sponsor API - Remove | `https://playcamp.io/docs/api-reference/server-sponsor/remove-sponsor.md` |
| Coupon API - Validate | `https://playcamp.io/docs/api-reference/server-coupon/validate-coupon.md` |
| Coupon API - Redeem | `https://playcamp.io/docs/api-reference/server-coupon/redeem-coupon.md` |
| Payment API - Create | `https://playcamp.io/docs/api-reference/server-payment/create-payment.md` |
| Payment API - Refund | `https://playcamp.io/docs/api-reference/server-payment/refund-payment.md` |
| Webhook API - Create | `https://playcamp.io/docs/api-reference/server-webhook/create-webhook.md` |
| Full docs index | `https://playcamp.io/docs/llms.txt` |

**When to fetch:** If the user asks about an endpoint, field, or behavior not covered in this guide, fetch the relevant page above before providing examples. The API reference pages contain exact request/response schemas for each endpoint.
