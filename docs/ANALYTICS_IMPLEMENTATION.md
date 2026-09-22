# Firebase Analytics Implementation

Discount Buddy uses **Firebase Analytics (GA4)** for product analytics.

This document covers what was implemented, which events are tracked, and which parameters each event sends.

---

## Architecture

| Piece | Location |
|---|---|
| Package | `firebase_analytics` in `pubspec.yaml` |
| Event / screen / param constants | `lib/core/analytics/analytics_events.dart` |
| Wrapper service | `lib/core/analytics/analytics_service.dart` |
| DI registration | `lib/routes/bindings/initial_binding.dart` |

All custom logging goes through `AnalyticsService.instance`.

Rules baked into the service:

- Calls are fire-and-forget and never throw (analytics cannot break booking / redeem / spin).
- Null parameters are dropped.
- Bools are sent as `"true"` / `"false"`.
- Strings are truncated to Firebase’s 100-character limit.
- **No PII** (no email, phone, or full name). Only internal ids and product fields.

---

## Automatic events (do not log manually)

Firebase records these once the Analytics SDK is in the app:

| Event | Platforms | Meaning |
|---|---|---|
| `first_open` | Android + iOS | First open after install (practical install metric) |
| `session_start` | Android + iOS | New session |
| `user_engagement` | Android + iOS | Time spent in app |
| `app_update` | Android + iOS | App was updated |
| `screen_view` | Android + iOS | Screen views (we also send custom ones below) |
| `app_remove` | **Android only** | App uninstalled |

### Uninstall notes

- **Android:** use `app_remove` in Firebase Events.
- **iOS:** Firebase has no uninstall event. Use Retention (D1 / D7 / D30) and App Store Connect.
- `first_open` vs `app_remove` in a date range is not a matched install-cohort uninstall rate.

---

## User identity

Set on successful login / cleared on logout in `lib/providers/auth_provider.dart`.

| API | When | Data |
|---|---|---|
| `setUserId` | After login | Internal numeric user id as string |
| `setUserId(null)` | Logout | Clears user id |
| `setUserProperty(user_type)` | After login | `customer`, `merchant`, `admin`, `mystery_guest`, etc. |
| `setUserProperty(user_type, null)` | Logout | Clears property |

---

## Screen views

Logged with `logScreenView(screenName, screenClass)`.

| Screen name | Where logged | Notes |
|---|---|---|
| `Home` | `main_navigation.dart` | Customer tab index 0 |
| `Nearby` | `main_navigation.dart` | Customer tab index 1 (map / nearby) |
| `Bookings` | `main_navigation.dart` | Customer tab index 2 |
| `Profile` | `main_navigation.dart` | Customer / merchant tab |
| `MerchantDashboard` | `main_navigation.dart` | Merchant tab 0 |
| `MerchantRestaurants` | `main_navigation.dart` | Merchant tab 1 |
| `MerchantMenu` | `main_navigation.dart` | Merchant tab 2 |
| `Search` | `search_page.dart` | Text search route (`/search`) |
| `Notifications` | `notifications_page.dart` | Notifications list |
| `RestaurantDetails` | `restaurant_details_page.dart` | After detail loads |
| `LoyaltyWallet` | `loyalty_cards_screen.dart` | Loyalty cards list |
| `SpinToWin` | `spin_wheel_screen.dart` | Spin wheel screen |

Firebase event name for these is always `screen_view`, with parameters:

| Parameter | Example |
|---|---|
| `firebase_screen` / `screen_name` | `Home` |
| `firebase_screen_class` / `screen_class` | `Home` or widget class name |

---

## Custom events reference

### Authentication

Uses Firebase built-in helpers (`logSignUp` / `logLogin`).

| Event | When | Parameters |
|---|---|---|
| `sign_up` | `register` or `registerComplete` succeeds | `method` = `email` |
| `login` | Email / Google / Apple login succeeds | `method` = `email` \| `google` \| `apple` |

**Source:** `lib/providers/auth_provider.dart`

---

### Discovery

| Event | When | Parameters | Example values |
|---|---|---|---|
| `search` | Debounced search with non-empty query | `search_term`, `result_count` | `search_term`: `"pizza"`, `result_count`: `12` |
| `restaurant_viewed` | Restaurant detail loaded | `restaurant_id`, `restaurant_name` | `"152"`, `"Cafe Nova"` |
| `restaurant_favorited` | Heart toggled **on** (not off) | `restaurant_id` | `"152"` |

**Sources:**

- `lib/pages/search_page.dart`
- `lib/pages/restaurant_details_page.dart`

---

### Deals / redeem funnel

| Event | When | Parameters | Example values |
|---|---|---|---|
| `deal_viewed` | Redeem Offer modal opens | `restaurant_id`, `deal_id` (optional) | `"152"`, `563` |
| `redeem_started` | Redeem Offer button tapped, or confirm pressed in modal | `restaurant_id`, `deal_id`, `type`, `source` | `type`: `deal` \| `loyalty_visit`<br>`source`: `details_button` \| `confirm` |
| `deal_redeemed` | Claim / loyalty visit API succeeds | `restaurant_id`, `deal_id`, `type` | `type`: `deal` \| `loyalty_visit` |

**Sources:**

- `lib/pages/restaurant_details_page.dart` — `redeem_started` with `source: details_button`
- `lib/pages/deals/redeem_offer_modal.dart` — `deal_viewed`, `redeem_started` (`confirm`), `deal_redeemed`

Funnel:

```
deal_viewed → redeem_started → deal_redeemed
```

---

### Booking funnel

| Event | When | Parameters | Example values |
|---|---|---|---|
| `booking_started` | Book Table tapped, or Redeem requires booking | `restaurant_id`, `source` | `source`: `book_table_button` \| `redeem_requires_booking` |
| `booking_created` | Create booking API succeeds | `restaurant_id`, `guests`, `source` | `guests`: `2`<br>`source`: `create_booking_page` \| `redeem_booking_modal` |
| `booking_cancelled` | Customer cancels booking successfully | `booking_id`, `restaurant_id` | `booking_id`: `901`, `restaurant_id`: `"152"` |

**Sources:**

- `lib/pages/restaurant_details_page.dart` — `booking_started`
- `lib/pages/bookings/create_booking_page.dart` — `booking_created`
- `lib/pages/bookings/booking_selection_modal.dart` — `booking_created`
- `lib/pages/bookings/bookings_page.dart` — `booking_cancelled`

Funnel:

```
booking_started → booking_created → (optional) booking_cancelled
```

---

### Loyalty

| Event | When | Parameters | Example values |
|---|---|---|---|
| `loyalty_card_viewed` | Loyalty wallet loads, or reward sheet opened on restaurant details | `restaurant_id` (optional), `card_count` (optional), `source` | `source`: `loyalty_wallet` \| `restaurant_details`<br>`card_count`: `3` |
| `stamp_collected` | Merchant QR scan succeeds and loyalty is enabled | `restaurant_id`, `is_loyalty_only`, `reward_just_earned` | `"true"` / `"false"` strings |
| `reward_redeemed` | Merchant claims loyalty reward successfully | `restaurant_id` | `"152"` |

**Sources:**

- `lib/pages/loyalty/loyalty_cards_screen.dart` — `loyalty_card_viewed`
- `lib/pages/restaurant_details_page.dart` — `loyalty_card_viewed`
- `lib/pages/merchant/qr_scanner_page.dart` — `stamp_collected`, `reward_redeemed`

Note: stamps and reward claims are confirmed on the **merchant** device, so those two events fire from the merchant scanner, not the customer app.

Customer “Collect Stamp” / loyalty visit in the redeem modal is tracked as:

- `redeem_started` with `type: loyalty_visit`
- `deal_redeemed` with `type: loyalty_visit`

---

### Notifications

| Event | When | Parameters | Example values |
|---|---|---|---|
| `notification_open` | Push tapped from background/terminated, or in-app list item tapped | `source`, `notification_type` | `source`: `push` \| `in_app`<br>`notification_type`: backend type string |

**Sources:**

- `lib/services/firebase_messaging_service.dart` — `source: push`
- `lib/pages/notifications_page.dart` — `source: in_app`

---

### Spin to Win

| Event | When | Parameters | Example values |
|---|---|---|---|
| `spin_started` | User taps spin | `campaign_id` | `12` |
| `spin_completed` | Spin API returns a result | `campaign_id`, `is_win`, `prize_title` | `is_win`: `"true"` \| `"false"`<br>`prize_title`: `"Free Coffee"` |

**Source:** `lib/pages/spin_to_win/spin_wheel_screen.dart`

---

## Parameter dictionary

| Parameter | Type in Firebase | Description |
|---|---|---|
| `restaurant_id` | string | Internal restaurant id |
| `restaurant_name` | string | Restaurant display name |
| `deal_id` | number | Internal deal / discount id |
| `booking_id` | number | Internal booking id |
| `guests` | number | Party size |
| `type` | string | Redeem type: `deal` or `loyalty_visit` |
| `source` | string | Where the action started (button, modal, push, etc.) |
| `notification_type` | string | Backend notification type |
| `campaign_id` | number | Spin campaign id |
| `is_win` | string | `"true"` / `"false"` |
| `prize_title` | string | Prize name from spin result |
| `card_count` | number | Number of loyalty cards shown |
| `result_count` | number | Search result count |
| `is_loyalty_only` | string | `"true"` / `"false"` — stamp without deal redeem |
| `reward_just_earned` | string | `"true"` / `"false"` — reward unlocked on this stamp |
| `method` | string | Auth method (`email` / `google` / `apple`) |
| `search_term` | string | Search query (Firebase `logSearch`) |

---

## Files touched for instrumentation

```
lib/core/analytics/analytics_events.dart
lib/core/analytics/analytics_service.dart
lib/routes/bindings/initial_binding.dart
lib/providers/auth_provider.dart
lib/pages/main_navigation.dart
lib/pages/search_page.dart
lib/pages/notifications_page.dart
lib/services/firebase_messaging_service.dart
lib/pages/restaurant_details_page.dart
lib/pages/deals/redeem_offer_modal.dart
lib/pages/bookings/create_booking_page.dart
lib/pages/bookings/booking_selection_modal.dart
lib/pages/bookings/bookings_page.dart
lib/pages/loyalty/loyalty_cards_screen.dart
lib/pages/merchant/qr_scanner_page.dart
lib/pages/spin_to_win/spin_wheel_screen.dart
```

---

## How to verify (DebugView)

### Android

```bash
adb shell setprop debug.firebase.analytics.app com.discountbuddy.app
```

Then open:

**Firebase Console → Analytics → DebugView**

Use the app and you should see events such as `session_start`, `restaurant_viewed`, `redeem_started`, etc. almost immediately.

Turn off when done:

```bash
adb shell setprop debug.firebase.analytics.app .none.
```

### Production console

**Firebase Console → Analytics → Events**

Custom events can take up to ~24 hours to appear in standard reports. DebugView is for instant validation.

---

## Not implemented yet

These were listed in the planning notes / `analytics.md` but are **not** wired in this pass:

- Referral sharing (`referral_shared`)
- Explicit `redeem_failed` event
- Booking completion / merchant booking status events beyond customer cancel
- Extra screens beyond the list above (DealDetails, BookingDetails, etc. as separate named screens)

Add those later through `AnalyticsService` the same way as existing helpers.
