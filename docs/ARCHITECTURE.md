# DiscountBuddy Architecture Guide

**Use this doc when adding or changing features.** One source of truth for folder layout, SOLID layering, and how code should talk to each other.

---

## 1. Big picture

Feature-first Clean Architecture:

```
UI (pages) → Provider → UseCase → Repository (interface) → RepositoryImpl → API/storage
```

| Layer | Owns | Must not own |
|-------|------|--------------|
| **pages/** | Widgets, navigation, showing errors | HTTP, parsing, business rules |
| **data/** Provider | UI state, call **one** use case, map `Result` | Dio, JSON, FCM, string-surgery on exceptions |
| **domain/** | Entities, repository contracts, use cases, ports | Flutter UI, `http`, DTOs |
| **data/** Impl / Service / Mapper | HTTP, JSON DTOs, local storage, map DTO ↔ entity | UI widgets, `ChangeNotifier` |

Shared infrastructure lives in `lib/core/`. Shared widgets in `lib/components/` and `lib/widgets/`.

**Stack today:** Provider (`ChangeNotifier`) for feature state · GetX for named routes · `package:discount_buddy/...` imports only.

---

## 2. Top-level layout

```
lib/
├── main.dart                 # MultiProvider registration, app boot
├── core/                     # Shared infra (not feature-specific)
│   ├── config/
│   ├── network/              # API client, interceptors
│   ├── theme/
│   ├── utils/
│   ├── device/
│   ├── di/
│   └── domain/
│       ├── result.dart       # Success / Err
│       ├── error_mapper.dart # Exception → Failure
│       └── failures/         # Failure, AppFailure, NetworkFailure, …
├── components/               # Design-system / reusable UI
├── widgets/
├── routes/
│   ├── app_routes.dart       # Route path constants
│   └── app_pages.dart        # GetPage bindings
└── features/
    └── <feature_name>/
        ├── pages/            # Screens & modals
        ├── domain/
        │   ├── entities/     # Pure domain models (when needed)
        │   ├── repositories/ # Abstract contracts (intent-based)
        │   ├── usecases/     # 1 action = 1 file
        │   └── ports/        # Optional adapters (e.g. DeviceTokenPort)
        ├── data/
        │   ├── <feature>_repository_impl.dart
        │   ├── <feature>_provider.dart   # or service + provider
        │   ├── mappers/                  # DTO ↔ entity
        │   └── …_service.dart            # HTTP / storage details
        └── models/           # API DTOs / JSON models (data-shaped)
```

**Existing features:** `auth`, `onboarding`, `home`, `nearby`, `restaurants`, `deals`, `bookings`, `merchant`, `loyalty`, `mystery_guest`, `profile`, `notifications`.

Put code in the feature that owns the capability. Prefer extending an existing feature over inventing a new top-level folder.

---

## 3. Hard rules (non-negotiable)

### 3.1 One use case = one action = one file

```
features/bookings/domain/usecases/create_booking_usecase.dart
features/bookings/domain/usecases/cancel_booking_usecase.dart
```

- Name: `VerbNounUseCase` → file `verb_noun_usecase.dart`
- Expose `Future<Result<T>> call(...)` (or named params)
- Inject the repository (and optional ports) via constructor
- Do **not** bundle multiple actions in one `*_usecases.dart` file

### 3.2 Repository is intent, not HTTP verbs

```dart
// Good — what the app needs
Future<Result<Booking>> createBooking({...});
Future<Result<void>> cancelBooking(int bookingId);

// Bad — leaky transport
Future<Response> post('/bookings');
```

### 3.3 Errors are `Failure` / `Result` — never Exception string surgery in UI

Use shared types:

- `lib/core/domain/result.dart` → `Success<T>` / `Err<T>` + `fold`
- `lib/core/domain/failures/` → `Failure`, `AppFailure`, `NetworkFailure`, `UnauthorizedFailure`, …
- Map thrown/Dio errors with `mapToFailure()` in **data** (repository impl), not in pages

```dart
result.fold(
  onSuccess: (value) { /* update state */ },
  onError: (failure) { /* show failure.message */ },
);
```

### 3.4 Provider = state + one use case + map Result

Each public provider method should:

1. Set loading / clear previous failure  
2. Call **one** use case  
3. `fold` the `Result` into state  
4. `notifyListeners()`

Do not call repositories or services directly from pages when a use case exists.

**Variants:**

- **Stateful feature** (`BookingProvider`, `AuthProvider`): holds lists/user/loading/`Failure?`
- **Facade feature** (`MerchantProvider`): holds use-case instances; page calls use case and folds (still no raw repo in UI)

Register new `ChangeNotifier` providers in `main.dart` `MultiProvider` if pages use `context.read` / `Consumer`.

### 3.5 Domain entities for UI state — DTOs stay in data

- **Domain / UI:** `UserEntity`, feature entities as needed  
- **Data only:** `ApiUser`, JSON models under `features/*/models/`  
- Mappers live in `data/mappers/` (`toEntity` only toward domain)  
- Pages must not depend on API DTO field names (`profilePicture` vs `profilePictureUrl`, nested `loyaltyStats`, etc.)

### 3.6 Side effects via ports

Things like FCM device tokens belong behind a **port** in domain (`DeviceTokenPort`) with an adapter in data — not inside the Provider.

---

## 4. New feature checklist

Copy this when starting work:

1. **Name the feature** under `lib/features/<name>/` (snake_case).
2. **Define intent** in `domain/repositories/<name>_repository.dart` returning `Result<T>`.
3. **Add use cases** — one file per action under `domain/usecases/`.
4. **Implement** `data/<name>_repository_impl.dart` (and service if needed); map errors with `mapToFailure`.
5. **Add mapper** if API JSON ≠ domain shape.
6. **Add provider** in `data/` — state + use cases + `fold`.
7. **Register** provider in `main.dart` if needed.
8. **Add pages** under `pages/`; wire with `context.read` / `Consumer` / `AuthProvider()` as existing screens do.
9. **Routes:** constant in `app_routes.dart`, page in `app_pages.dart`.
10. **Imports:** always `package:discount_buddy/...` (never relative across features).
11. **Analyze:** `flutter analyze` — fix errors before merging.
12. **Do not** leave unrouted orphan pages in the tree.

### Minimal skeleton

```
features/foo/
  domain/
    repositories/foo_repository.dart
    usecases/do_something_usecase.dart
  data/
    foo_repository_impl.dart
    foo_provider.dart
    mappers/   # if needed
  pages/
    foo_page.dart
  models/      # API DTOs only if needed
```

Reference implementations to copy:

| Pattern | Look at |
|---------|---------|
| Full SOLID (entities + ports) | `features/auth/` |
| Typical CRUD provider | `features/bookings/` |
| Many use cases, thin provider | `features/merchant/` |
| Shared Result / Failure | `lib/core/domain/` |

---

## 5. Where to put what (quick decisions)

| You are adding… | Put it in… |
|-----------------|------------|
| New screen for bookings | `features/bookings/pages/` |
| New API call for bookings | repo method + **new** use case + provider method |
| Shared button / card | `lib/components/` or `lib/widgets/` |
| Theme color / spacing | `lib/core/theme/` |
| Dio / headers / base URL | `lib/core/network/` |
| Cross-feature type used by many | Prefer owning feature’s `models/` or promote carefully to `core` only if truly shared |
| Route path | `lib/routes/app_routes.dart` + `app_pages.dart` |

**Do not** create a new top-level `lib/services/` for feature logic — keep adapters inside the feature’s `data/`.

---

## 6. UI layer conventions

- Pages: layout, user input, navigation (`Get.toNamed` / `Navigator`), snackbars from `failure.message`
- Prefer existing theme tokens (`AppColors`, `AppTypography`, `AppSpacing`, …)
- Auth user: `AuthProvider().user` is `UserEntity?` — use `profilePictureUrl`, `role`, `activeRestaurantsCount`, etc.
- Merchant pages often call use cases via `MerchantProvider` and fold locally — match that pattern, don’t invent a second style in the same feature

---

## 7. Anti-patterns (avoid)

- Calling Dio / `*Service` from a page  
- Parsing `e.toString()` in UI to decide what went wrong  
- One file with five use case classes  
- Exposing `ApiUser` (or other DTOs) as provider public state  
- Copy-pasting HTTP into a second feature instead of extending the owning repository  
- Dead screens not registered in `app_pages.dart`  
- Relative imports (`../../`) across packages/features  

---

## 8. Dependency direction (remember this)

```
pages  →  provider  →  usecase  →  repository (abstract)
                                      ↑
                         repository_impl  →  service / API
                                      ↑
                                   mapper ← DTO models
```

Domain never imports `data/` or Flutter Material (except unavoidable UI types you already avoid).  
Data may import domain.  
Pages may import provider + domain entities / models the UI already uses — prefer entities over DTOs for anything new.

---

## 9. Before you open a PR

- [ ] New actions have their own use-case files  
- [ ] Repository methods return `Result<T>`  
- [ ] Provider (or page via provider use cases) folds `Result` — no bare try/catch for business errors in UI  
- [ ] Provider registered if consumed via `context.read`  
- [ ] Routes added for every shipped page  
- [ ] No orphan / unused screens left behind  
- [ ] `flutter analyze` clean of errors  

---

*This is the only architecture doc to follow for app structure. Feature-specific API notes live under `docs/` separately and do not replace this guide.*
