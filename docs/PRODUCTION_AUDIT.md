# DiscountBuddy – Production Audit, Fixes & Test Plan

Audit date: 2026-10-10. Scope: ~20% of `lib/` read in depth (auth, API client, FCM, routing,
Home, Nearby, booking, redeem, QR scanner, spin wheel, platform config, tests). **Not reviewed:**
most of `restaurant_details_page.dart`, merchant menu/deals/analytics/add-restaurant pages, all
admin pages, `models/restaurant.dart`, iOS native code. Nothing was profiled on a device.

| Repo | Branch (created from current) | Commit |
|---|---|---|
| App `DiscountBuddy` | `fix/audit-auth-qr-spin-fcm` (from `spin-banner-functionality`) | see `git log` |
| Backend `Discount-Buddy` | `fix/logout-and-fcm-token-upsert` (from `main`) | `c2d98be` |

---

## 1. Backend facts that shaped the fixes (verified in `Discount-Buddy`)

| Fact | Where | Consequence |
|---|---|---|
| Access token 30 min, refresh 7 days, `ROTATE_REFRESH_TOKENS=False` | `discount_buddy/settings.py` `SIMPLE_JWT` | Refresh returns only `access`; the app's "store only access" is correct. Rotation concern from the audit is **not** an issue. |
| `POST /user/api/users/logout` was `IsAuthenticated` | `users/views.py` `LogoutView` | With an expired access token it returned **401**. This confirmed the client deadlock (issue A1). |
| `DeviceToken.token` is `unique=True`; `ModelSerializer` adds a `UniqueValidator` | `notifications/models.py`, `serializers.py` | Re-registering a token that exists on any row/user returned **400 "already exists"** before `create()` ran. The app compensated by deleting and rotating the FCM token (`_registerTokenWithBackend`). |
| `create()` upserts by `device_id` (else by `token`) | `DeviceTokenSerializer.create` | Intent was an upsert; the validator defeated it. |
| Push send marks tokens `is_active=False` when FCM reports them invalid | `notifications/tasks.py:103,178` | Fine; no change. |

---

## 2. Findings and status

Legend: **FIXED** = changed on the branches above, **OPEN** = not changed (reason given).

### A. Fixed

| ID | Severity | Finding | Fix | Files |
|---|---|---|---|---|
| A1 | Critical | Failed token refresh called `logout()` → authenticated `POST logout` → 401 → queued behind the refresh it belonged to → **permanent hang**, `_isRefreshing` stuck, later 401s hang too | Refresh failure no longer calls the network. New local-only `_expireSession()`. Logout request sent `withAuth:false` (refresh token is the credential). Waiters have a 45 s timeout. **Backend:** logout is now `AllowAny`/no authentication. | `auth_service.dart`, `api_service.dart`, `users/views.py` |
| A2 | High | Any refresh error (timeout, offline, 5xx, bad body) wiped all secure storage = surprise logout, and `AuthProvider` kept `isAuthenticated=true` | Session is cleared **only** if refresh returns 400/401. Otherwise tokens are kept. New `ApiService.onSessionExpired` stream; `AuthProvider` clears state so `MainNavigation` redirects to login. | `auth_service.dart`, `api_service.dart`, `auth_provider.dart` |
| A3 | High | QR scanner: `_isProcessing` set too late → same QR opened several sheets; `setState` in `finally` after dispose; sheet controllers leaked; camera stayed frozen after swipe-dismiss; price/people accepted `NaN`, ≤0, huge | Lock set synchronously in `_handleQRCode`; `mounted` guards; controllers disposed in `whenComplete`; scanner resumes on dismiss; price `0<p≤100000`, people `1–1000` | `qr_scanner_page.dart` |
| A4 | Medium | Spin: after the request, widget could be disposed → animation on disposed controller / dialog with dead context | `mounted` checks after the await and in the animation callback (prize remains under "My prizes") | `spin_wheel_screen.dart` |
| A5 | Medium | HTML/stack-trace bodies and `TimeoutException…` strings shown to users; HTML on HTTP 200 treated as success | Generic messages; 5xx → "Server error…"; HTML 2xx → `ApiException` | `api_service.dart` |
| A6 | Medium | Foreground push tap did nothing (payload was `Map.toString()`); cold-start tap dropped when navigator not ready | Payload is `jsonEncode`d and parsed; navigation waits (bounded, ~10 s) for the navigator | `firebase_messaging_service.dart` |
| A7 | Low-Med | FCM token and notification content printed in release via `debugPrint` | Wrapped in `kDebugMode` | `firebase_messaging_service.dart` |
| A8 | Medium | FCM re-registration of an existing token failed with 400 (user switch on same phone, failed logout deactivate) | **Backend:** validator removed; `create()` deletes stale rows holding the same token (different `device_id`) then upserts | `notifications/serializers.py` |
| A9 | Medium | `flutter test` was red (empty `widget_test.dart`); no network/auth tests | Removed empty file; added `test/api_service_test.dart` (7 tests); backend added 4 tests | `test/`, `notifications/tests.py` |

### B. Open (not changed)

| ID | Severity | Finding | Why not changed / next step |
|---|---|---|---|
| B1 | High (risk) | `claimDeal`, `createBooking`, `spinWheel` are non-idempotent POSTs; a 30 s timeout after server success lets the user retry | Needs backend idempotency key / dedupe. Ask backend to accept `Idempotency-Key`. |
| B2 | Medium | No route guards for merchant/admin routes (`app_pages.dart`) | Backend enforces auth; add `GetMiddleware` later. |
| B3 | Medium | Home: banners then home-data fetched sequentially; `_isLoadingRestaurants` drops a reload requested mid-flight | Behavioural change, wants device verification. |
| B4 | Medium | Nearby: no stale-response guard; pin refresh is O(n) awaited platform calls per selection | Profile first. |
| B5 | Medium | 21× `CachedNetworkImage` + 7× `Image.network` with no `memCacheWidth` | Check which image variant lists use; profile memory. |
| B6 | Medium (a11y) | `main.dart` forces `TextScaler.noScaling` | Design decision. |
| B7 | Low-Med | `android:allowBackup` not disabled with `flutter_secure_storage`; unguarded `getAccessToken()` | Needs restore test. |
| B8 | Low | 4 pages create `TextEditingController`s with no dispose (`mystery_audit_modal`, `add_deal_page`, `merchant_loyalty_page`, `booking_selection_modal`) | Small leaks; fix when touched. |
| B9 | Low | Placeholder `YOUR_API_KEY_HERE` Google Maps key in manifest; `NSLocationAlways*` strings without background-location mode; tracked `response.json`, `compile_errors.json` | Hygiene. |
| B10 | – | God files (`restaurant_details_page` 3,665 lines etc.), mixed GetX/Provider/setState | Refactor only when next touched. |

---

## 3. How to test (manual checklist)

Setup: run the backend branch locally (`python manage.py runserver`) and point the app `.env`
`API_BASE_URL` at it. For token tests temporarily set `ACCESS_TOKEN_LIFETIME` to 1 minute in
`settings.py` (revert afterwards).

### Backend (`fix/logout-and-fcm-token-upsert`)
- [ ] `python manage.py test notifications.tests.DeviceTokenRegistrationAndLogoutTests` → 4 tests pass (3 of them fail on `main`).
- [ ] `curl -X POST …/user/api/users/logout -d '{"refresh":"<valid>"}'` with **no** Authorization header → 200; repeat → 400 "already blacklisted".
- [ ] Register token T for user A, then register T for user B → 201, one row, owned by B.
- [ ] Rotate token for same `device_id` → same row, new token.

### Token / session (A1, A2)
- [ ] Log in, wait for access expiry (1 min setting), tap around → requests succeed transparently (refresh).
- [ ] **Deadlock case:** expire access token, then blacklist the refresh token server-side (or edit it in the DB), trigger any call → the app must show the login screen within a few seconds, not spin forever. Repeat on the **old** backend (`main`) → must still not hang (logout is sent without auth; worst case it errors silently).
- [ ] **Transient failure:** expire access token, enable airplane mode, pull-to-refresh → error message, **not** logged out; disable airplane mode, retry → works.
- [ ] Server 500 on refresh (stop backend) → not logged out.
- [ ] Normal logout and delete-account still work; FCM device deactivated; relogin works.

### QR redemption (A3) – merchant account
- [ ] Hold camera on one deal QR for several seconds → exactly **one** price/people sheet.
- [ ] Swipe the sheet down → camera resumes and can scan again.
- [ ] Enter price `0`, `-5`, `NaN`, `100001`; people `0`, `1001` → validation errors.
- [ ] Valid redeem → success dialog; scanner usable after closing dialog.
- [ ] Leave the screen while the redeem request is in flight (slow network) → no crash.
- [ ] Loyalty reward QR and manual-code flows unchanged.

### Spin to Win (A4) – customer
- [ ] Spin normally → wheel lands on prize, dialog shows.
- [ ] Spin then immediately close the modal on a throttled network → no exception in logs; prize appears in My Prizes.

### Errors (A5)
- [ ] Point app at an unreachable host / block with proxy → "Network error…" / "timed out" messages, no raw exception text.
- [ ] Make the proxy return an HTML 502 → "Server error. Please try again…", no HTML shown.

### Push (A6–A8) – Android and iOS, release build
- [ ] App **foreground**, receive push, tap the local banner → correct screen (all types: new booking, review, promo/fav deal with restaurant, deal redeemed, booking confirmed).
- [ ] App **background**, tap push → correct screen.
- [ ] App **killed**, tap push → app opens and lands on the correct screen (watch for splash replacing the route; if it does, increase the initial 300 ms delay or replay after home mounts).
- [ ] Log in as user A, log out, log in as user B on the same phone → B gets pushes, A does not, no duplicate-token errors.
- [ ] Release build: `adb logcat | grep -i "FCM Token"` → nothing printed.

### Regression
- [ ] `flutter analyze` → only the existing 28 info-level items.
- [ ] `flutter test` → 40 pass.
- [ ] Smoke: login (email/Google/Apple), home, nearby map, booking create, redeem offer, profile edit.

---

## 4. Automated tests added

| Test | Proves |
|---|---|
| `401 -> refresh -> retried once` | Refresh success path |
| `concurrent 401s trigger a single refresh` | Waiter queue |
| `refresh failure surfaces original 401` | No swallowed errors |
| `regression: 401 during refresh cannot hang` | A1 (fails/hangs on old code) |
| `HTML error page never shown` / `HTML 2xx is an error` / `timeouts map to friendly message` | A5 |
| Backend: reassign token between users, rotation, device_id move, logout without access token | A1/A8 |

## 5. Not done / needs a device
- Cold-start push navigation (A6) is timing-dependent and unverified on hardware.
- No performance numbers exist; profile Home/Nearby/images per B3–B5 in profile mode on a low-end Android device.
- `db.sqlite3` in the backend repo has uncommitted local changes that pre-date this work; it was deliberately not committed.
