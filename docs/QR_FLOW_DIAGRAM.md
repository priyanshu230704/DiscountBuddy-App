# QR Code Redemption - Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CUSTOMER SIDE (User App)                             │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │ User browses │
    │    deals     │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ User claims  │
    │   a deal     │
    └──────┬───────┘
           │
           ▼
    ┌──────────────────────────────────────┐
    │ POST /api/deals/{id}/use/            │
    │                                       │
    │ Backend generates:                    │
    │ • 6-digit code (e.g., "123456")      │
    │ • QR code: "DEALUSE:105:123456"      │
    │ • QR image saved to media/qr_codes/  │
    └──────┬───────────────────────────────┘
           │
           ▼
    ┌──────────────────────────────────────┐
    │ User receives DealRedemption object: │
    │ {                                     │
    │   "id": 105,                          │
    │   "redemption_code": "123456",        │
    │   "qr_code_url": "https://...",       │
    │   "is_redeemed": false                │
    │ }                                     │
    └──────┬───────────────────────────────┘
           │
           ▼
    ┌──────────────┐
    │ User shows   │
    │  QR code to  │
    │   merchant   │
    └──────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                        MERCHANT SIDE (Restaurant App)                        │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────┐
    │ Merchant opens   │
    │    Dashboard     │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │ Taps "Redeem"    │
    │   card           │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │ QRScannerPage opens                  │
    │                                       │
    │ 1. Check camera permission            │
    │ 2. Request if not granted             │
    │ 3. Show camera preview                │
    └────────┬─────────────────────────────┘
             │
             ├─────────────────┬─────────────────┐
             │                 │                 │
             ▼                 ▼                 ▼
    ┌────────────────┐  ┌──────────────┐  ┌──────────────┐
    │  Scan QR Code  │  │ Manual Entry │  │ Permission   │
    │                │  │              │  │   Denied     │
    └────────┬───────┘  └──────┬───────┘  └──────┬───────┘
             │                 │                 │
             │                 │                 ▼
             │                 │          ┌──────────────┐
             │                 │          │ Show error & │
             │                 │          │ request again│
             │                 │          └──────────────┘
             │                 │
             ▼                 ▼
    ┌─────────────────────────────────────┐
    │ Validate QR format                  │
    │ • Must start with "DEALUSE:"        │
    │ • Must have 3 parts (split by ':')  │
    │ • ID must be numeric                │
    │ • Code must be 6 digits             │
    └────────┬────────────────────────────┘
             │
             ├──────────────┬──────────────┐
             │              │              │
             ▼              ▼              ▼
    ┌────────────┐  ┌──────────────┐  ┌──────────────┐
    │   Valid    │  │   Invalid    │  │ Manual code  │
    │            │  │   Format     │  │  (6 digits)  │
    └──────┬─────┘  └──────┬───────┘  └──────┬───────┘
           │                │                 │
           │                ▼                 │
           │         ┌──────────────┐         │
           │         │ Show error   │         │
           │         │  snackbar    │         │
           │         └──────────────┘         │
           │                                  │
           └──────────────┬───────────────────┘
                          │
                          ▼
           ┌──────────────────────────────────┐
           │ Show loading sheet               │
           │ "Verifying deal..."              │
           └──────────────┬───────────────────┘
                          │
                          ▼
           ┌──────────────────────────────────┐
           │ POST /merchant/api/deals/redeem  │
           │                                   │
           │ Body (QR):                        │
           │ { "qr_data": "DEALUSE:105:123456" }│
           │                                   │
           │ OR (Manual):                      │
           │ { "redemption_code": "123456" }   │
           └──────────────┬───────────────────┘
                          │
                          ▼
           ┌──────────────────────────────────┐
           │ Backend validates:                │
           │ • Merchant is authenticated       │
           │ • Merchant owns restaurant        │
           │ • Deal use exists                 │
           │ • Code matches                    │
           │ • Not already redeemed            │
           │ • Deal is still active            │
           └──────────────┬───────────────────┘
                          │
                          ├────────────┬────────────┐
                          │            │            │
                          ▼            ▼            ▼
                   ┌──────────┐  ┌──────────┐  ┌──────────┐
                   │ Success  │  │  Error   │  │  Error   │
                   │  (200)   │  │  (400)   │  │ (403/409)│
                   └────┬─────┘  └────┬─────┘  └────┬─────┘
                        │             │             │
                        ▼             ▼             ▼
           ┌──────────────────────────────────────────────┐
           │ Hide loading dialog                          │
           └──────────────┬───────────────────────────────┘
                          │
                          ├────────────┬────────────┐
                          │            │            │
                          ▼            ▼            ▼
           ┌──────────────────┐  ┌──────────────┐  ┌──────────────┐
           │ Success Sheet    │  │ Error Sheet  │  │ Error Sheet  │
           │                  │  │              │  │              │
           │ ✓ Green check    │  │ ✗ Red error  │  │ ⚠ Orange warn│
           │ Deal title       │  │ "Invalid     │  │ "Already     │
           │ Code: 123456     │  │  code"       │  │  redeemed"   │
           │ Restaurant       │  │              │  │              │
           │ Redeemed at      │  │              │  │              │
           │                  │  │              │  │              │
           │ [Done] button    │  │ [OK] button  │  │ [OK] button  │
           └────────┬─────────┘  └──────┬───────┘  └──────┬───────┘
                    │                   │                 │
                    └───────────────────┴─────────────────┘
                                        │
                                        ▼
                            ┌───────────────────────┐
                            │ Return to Dashboard   │
                            └───────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                            BACKEND UPDATES                                   │
└─────────────────────────────────────────────────────────────────────────────┘

    When deal is claimed:
    ┌──────────────────────────────────────┐
    │ DealUse model updated:                │
    │ • is_redeemed = True                  │
    │ • restaurant_confirmed = True         │
    │ • redeemed_at = current timestamp     │
    └──────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                         KEY COMPONENTS USED                                  │
└─────────────────────────────────────────────────────────────────────────────┘

    Services:
    • QRScannerService      → Permission & validation
    • MerchantService        → API calls
    
    Models:
    • DealRedemption         → Response parsing
    • RedeemedDeal           → Deal details
    
    UI Pages:
    • QRScannerPage          → Scanner UI
    • MerchantDashboardPage  → Entry point
    
    Dependencies:
    • mobile_scanner         → QR scanning
    • permission_handler     → Camera access


┌─────────────────────────────────────────────────────────────────────────────┐
│                         ERROR HANDLING FLOW                                  │
└─────────────────────────────────────────────────────────────────────────────┘

    Network Error
    ├─→ Catch DioException
    └─→ Show "Network error. Please check your connection."

    Invalid QR Format
    ├─→ Client-side validation fails
    └─→ Show "Invalid QR code format" snackbar

    Invalid Code (400)
    ├─→ API returns 400
    └─→ Show "Invalid redemption code or QR data"

    Unauthorized (403)
    ├─→ API returns 403
    └─→ Show "You are not authorized to redeem this deal"

    Already Redeemed (409)
    ├─→ API returns 409
    └─→ Show "This deal has already been redeemed" (orange warning)

    Deal Expired
    ├─→ Backend validation
    └─→ Show "This deal is no longer valid"


┌─────────────────────────────────────────────────────────────────────────────┐
│                         SECURITY LAYERS                                      │
└─────────────────────────────────────────────────────────────────────────────┘

    Layer 1: Client Validation
    • QR format check
    • Code length check
    • Numeric validation

    Layer 2: Authentication
    • Merchant must be logged in
    • Valid JWT token required

    Layer 3: Authorization
    • Merchant must own restaurant
    • Backend verifies ownership

    Layer 4: Business Logic
    • Deal must be active
    • Not expired
    • Not already redeemed
    • Code must match

    Layer 5: One-Time Use
    • Database constraint
    • is_redeemed flag
    • redeemed_at timestamp
```

## Quick Reference

### QR Code Format
```
DEALUSE:<deal_use_id>:<redemption_code>
Example: DEALUSE:105:123456
```

### API Endpoint
```
POST /merchant/api/deals/redeem
```

### Success Response Structure
```json
{
  "success": true,
  "reason": "Deal redeemed successfully.",
  "id": 105,
  "deal": { ... },
  "is_redeemed": true,
  "redeemed_at": "2026-02-17T10:15:30Z"
}
```

### Navigation Path
```
MerchantDashboardPage
  → Tap "Redeem" card
    → QRScannerPage
      → Scan QR or Enter Code
        → Success/Error Dialog
          → Back to Dashboard
```
