# Product analytics (mobile app)

Reference for how Sampul’s Flutter app sends **privacy-conscious** usage data to **PostHog**. Use this when adding screens, journeys, or new events.

## Goals

- Readable **screen names** in PostHog (not opaque routes like `root ('/')`).
- **Automatic** screen tracking where possible (`PosthogObserver` on `Navigator`).
- **Explicit events** for funnels (signup, checkout, will/property-trust steps) without PII.
- Predictable behaviour on **sign-out** (no stray anonymous “people” from logged-out navigation).

## Configuration

| Variable | Required | Notes |
|----------|----------|--------|
| `POSTHOG_API_KEY` | Yes, for analytics | Project API key from PostHog. If missing/empty, analytics is disabled; the app runs normally. |
| `POSTHOG_HOST` | No | Defaults to `https://us.i.posthog.com`. Use EU or self-host URL if your project lives there. |

Loaded via `flutter_dotenv` with the rest of the app `.env`.

## Core code

| Piece | Location | Role |
|-------|-----------|------|
| Init + observers | `lib/main.dart` | Calls `AnalyticsService.initialize()`, attaches `navigatorObservers`, wraps app when needed, coordinates auth → identify / capture enable. |
| API wrapper | `lib/services/analytics_service.dart` | `initialize`, `capture`, `logScreen`, `identify`, `reset`, `resetAndDisableCapture`, `enableCapture` / `disableCapture`, `captureException`, `setLocale`, `wrapApp`, `navigatorObservers`. |
| Screen name constants | `lib/config/analytics_screens.dart` | Single source of truth for human-readable route/screen labels. |

PostHog is configured with **`identifiedOnly`** person profiles so anonymous traffic does not create person records until `identify` runs.

## How screen names appear in PostHog

1. **Named routes** — Prefer `MaterialPageRoute( settings: RouteSettings(name: AnalyticsScreens.someConstant), builder: ...)`. `PosthogObserver` emits `$screen` (or equivalent) using `RouteSettings.name`.
2. **Manual** — `AnalyticsService.logScreen(AnalyticsScreens.foo)` when a route name is not practical (rare; avoid duplicating the same screen twice in one visit).

Always add new screens to **`analytics_screens.dart`** first, then reference the constant from navigation code.

## Auth and privacy behaviour

- After **sign-in**, the app enables capture and **identifies** with the Supabase **user UUID** (not email).
- **Sign-out**: auth flows trigger analytics reset; **`resetAndDisableCapture`** runs so logged-out navigation does not keep creating anonymous PostHog persons/events unintentionally. Capture is re-enabled when the user signs in again.

## Custom events (non-PII properties)

These are examples of intentional product events. Names use **lowercase with spaces** (existing convention in the codebase). Expand this list in code comments or here when you add new ones.

| Event | Where / when | Properties (examples) |
|-------|----------------|------------------------|
| `user signed up` | Auth | `method`, etc. (see `auth_controller`) |
| `user signed in` | Auth | `method` |
| `user signed out` | Auth | — |
| `will journey started` | `will_management_screen` | `mode`: `create` \| `edit` |
| `will generation viewed` | `will_generation_screen` | `mode`: `create` \| `edit` |
| `will saved` | `will_generation_screen` on successful save | `mode`: `update` \| `create`, `is_draft`: bool |
| `property trust journey started` | `hibah_management_screen` (e.g. FAB into flow) | — |
| `property trust submitted` | `hibah_create_screen` after successful submit | `asset_group_count`, `document_count` |
| `onboarding completed` | Onboarding | `destination`, etc. |
| Checkout / billing | `billing_screen`, `trust_payment_form_modal` | checkout / subscription-related |
| Verification (Didit) | `settings_screen` | verification started / link opened / failed |
| Push | `onesignal_service` | `push received` / `push opened` with `notification_id`, `has_data`, optional `type` — **no title/body** |

Do **not** attach names, emails, NRIC, addresses, or raw document content to events.

## Screen constants map (high level)

`analytics_screens.dart` defines labels for: app shell (`App`, `Home`, `Learn`, `Wasiat`, `Settings`), auth, onboarding, chat, billing, trust (create/edit/info/dashboard/management, fund support), Wasiat management vs **Create or edit will**, extra wishes, assets (list/add/edit/about/preview), family (list/add/about/edit), property trust (management, info, create, detail, asset/doc sub-forms), Pusaka (management, info), checklist, aftercare, inform death flows, notifications, referral/admin, AI chat, executor create, and **notifications deep links**.

Home and major journeys (`home_screen`, `will_*`, `hibah_*`, `notification_screen`) attach **`RouteSettings(name: ...)`** so horizontal lists, grids, and modals open with consistent PostHog screen names.

## Adding a new screen or flow

1. Add a `static const String` in `lib/config/analytics_screens.dart` (clear, user-facing wording).
2. Any `Navigator.push` / `MaterialPageRoute`: set `settings: RouteSettings(name: AnalyticsScreens.yourScreen)`.
3. If the step is funnel-critical, add **`AnalyticsService.capture(...)`** with **non-sensitive** properties only.
4. After `await` before using `BuildContext`, follow existing **`mounted`** checks.

## Errors

Uncaught Flutter errors can be forwarded via **`AnalyticsService.captureException`** (wired from `main.dart` error handlers). Avoid including stack traces that embed user data.

