# Changelog

All notable changes to the Kixo iOS SDK are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.6] — 2026-05-18

Expand the `StandardProperty` reserved-namespace catalog from
16 properties to **37 properties across 8 packs** — 3 universal
+ 5 B2B-vertical. The dashboard auto-detects each project's
vertical and renders the corresponding pack's audience-explorer UI.

**XCFramework sha256:**
`d1d13df6f8dac9a28f83ece09664f2c33d3397096abf8da4cf6ebefbf972d206`.

### Added

- **3 universal packs** (always rendered in the dashboard):
  - `identity` (6): `$email`, `$phone`, `$name`, `$first_name`, `$last_name`, `$avatar_url`
  - `geo` (6): `$country`, `$city`, `$region`, `$timezone`, `$language`, `$locale`
  - `lifecycle` (2): `$created`, `$last_seen`

- **5 vertical packs** (rendered when at least one property in the pack is populated):
  - `saas` (5): `$plan`, `$subscription_status`, `$trial_ends`, `$mrr`, `$subscription_started`
  - `ecommerce` (6): `$lifetime_orders`, `$lifetime_revenue`, `$aov`, `$last_purchase`, `$first_purchase`, `$cart_abandoned_count`
  - `media` (4): `$content_tier`, `$subscribed_categories`, `$watch_time_total`, `$last_played`
  - `marketplace` (5): `$seller_tier`, `$buyer_tier`, `$listings_count`, `$reviews_count`, `$verified`
  - `loyalty` (3): `$loyalty_points`, `$vip_level`, `$referral_count`

- **Nested `StandardProperty.Pack` enum** + `public var pack: Pack`
  computed property so segmentation / dashboard code can group
  properties by pack at the call site without hard-coding the
  mapping.

### Removed (no back-compat shim — pre-prod)

- `StandardProperty.gender` (`$gender`) — low signal for B2B audiences.
- `StandardProperty.birthYear` (`$birth_year`) — same rationale.
- `StandardProperty.revenue` (`$revenue`) — replaced by the more
  explicit `$lifetime_revenue` in the `ecommerce` pack.

Customers who set `$gender` / `$birth_year` / `$revenue` via the
typed enum form (`Kixo.setUserProperty(.gender, …)`) will see a
compile-time error and need to migrate. String-key form
(`Kixo.setUserProperty("$revenue", …)`) silently stops being
promoted to a profile column and is stored as a custom trait.

### Notes

- `sdkVersion` runtime stamp bumped `1.0.5` → `1.0.6` in
  `Transport.swift`.
- This catalog mirrors Android (`kixo/src/main/kotlin/io/kixo/sdk/
  StandardProperty.kt`) and Web
  (`kixo-web-sdk/src/core/standard-properties.ts`) byte-for-byte;
  the three SDKs bump together so the backend pivot and dashboard
  column registry stay coherent.

### Drop-in upgrade

`.package(url: ..., from: "1.0.0")` auto-resolves to `1.0.6` on
the next `swift package update`. Customer code using the typed
enum form for retained cases (`Kixo.setUserProperty(.email, value: …)`)
continues to work unchanged.

---

## [1.0.5] — 2026-05-18

Restore the 569Xlprefix convention on `StandardProperty` rawValues
(reverts v1.0.4). Reserved namespace separation is the whole point
of the Mixpanel convention; without it a customer using bare
`email` for their own app's notification-frequency property
collides with the Kixo `$email` reserved column.

**Built from** `kixo-ios-sdk@760bde2` with Xcode 26.4 / Swift 6.3.1.
**XCFramework sha256:** `27102b023e35e86c44dcca761848bf88aecfc9c5e167d88f8709cea80fdcb997`.

### Changed (canonical wire shape — back to v1.0.3 form)

- `StandardProperty.email.rawValue` = `"$email"` (was `"email"` in v1.0.4)
- Same for all 15 other cases — $-prefix restored throughout
- Backend pivot reads ONE canonical form (`$email`); no fallback

### Drop-in upgrade

`.package(url: ..., from: "1.0.0")` auto-resolves to `1.0.5` on
next `swift package update`. Customer code using the typed enum
form (`Kixo.setUserProperty(.email, value: "…")`) continues to
work unchanged — only the underlying wire string changed back to
$-prefix.

## [1.0.4] — 2026-05-18

Drop the legacy \$-prefix from all 16 reserved StandardProperty keys.

**Built from** `kixo-ios-sdk@e93a9ec` with Xcode 26.4 / Swift 6.3.1.
**XCFramework sha256:**
`a296df23a450e1c7145cfb84a4655f7bb195a55aad07134daa60cbfce2759974`.

### Changed (canonical wire shape)

- **`StandardProperty.email.rawValue` now `"email"` (was `"\$email"`).** Same
  for the other 15 cases — `phone`, `name`, `first_name`,
  `last_name`, `avatar_url`, `created`, `city`, `country`,
  `region`, `language`, `timezone`, `gender`, `birth_year`,
  `plan`, `revenue`. The Mixpanel-style \$-prefix convention was
  dropped pre-production: the 3 SDKs disagreed on it, Web/Android
  READMEs always shipped bare keys, the backend pivot was indexing
  both forms, and customers who followed the docs saw correct data
  on the detail page but `email: null` on the audience list. One
  canonical name per property.

### Drop-in upgrade

`.package(url: ..., from: "1.0.0")` auto-resolves to `1.0.4` on
the next `swift package update`. No code changes required on the
customer side; the `StandardProperty` typed enum still works the
same way at the call site, only its underlying wire key changed.

## [1.0.3] — 2026-05-17

`Kixo.group()` shape cleanup — mirrors Android v0.1.6.

**Built from** `kixo-ios-sdk@85b11b7` with Xcode 26.4 / Swift 6.3.1.
**XCFramework sha256:**
`c1b619b25f36da6110e5ee3e1541fbf565bb1885ff65cf209def04a7d69f971a`.

### Fixed

- **`Kixo.group(groupId, traits)` no longer injects `group_id` into
  the properties payload.** `group_id` rides on the event envelope
  via the same identity machinery as `user_id`; injecting it as a
  property mirrored the v1.0.2-era setUserProperty + identify
  shape bugs we fixed on the Android side. The leak was cosmetic
  on the current backend (group events don't write to
  `audience_properties`) but the pattern was incorrect.

### Drop-in upgrade

`.package(url: ..., from: "1.0.0")` auto-resolves to `1.0.3`; no
code changes required on the customer side.

---

## [1.0.2] — 2026-05-14

iOS Wave 2 — autoTrackNetwork privacy hardening + MetricKit hang/crash
diagnostics + retire async-signal-unsafe crash path.

**Built from** `kixo-ios-sdk@cab2873` with Xcode 26.4 / Swift 6.3.1.
**XCFramework sha256:**
`2aef21fb4cac62fc0bcc9b330c438cbc910639d94b616284b1597d47dafc2df3`.

### Changed (breaking default)

- **`autoTrackNetwork` default flipped `true` → `false` (privacy).**
  The pre-Wave-2 default reported `URLSession.dataTask` URLs on
  every request, including raw path segments. Customer apps with
  REST routes like `/api/users/<email>` or `/v1/orders/<uuid>`
  were leaking end-user PII into every event — even when the
  customer's app had no separate `identify()` call. Customers
  who still want network tracking opt in explicitly:

  ```swift
  Kixo.configure(
      projectId: "kx_proj_...",
      apiKey: "kx_key_...",
      options: ConfigurationOptions(autoTrackNetwork: true)
  )
  ```

  Same posture as Sentry's HTTP-breadcrumb default and the
  Android SDK's v0.1.2 deprecation of the equivalent flag.

### Added

- **`URLPathSanitizer`** — when `autoTrackNetwork: true` is
  explicitly opted into, every captured URL now passes through
  a path sanitiser before it leaves the device. Replaces:

  | Path segment shape                  | Placeholder |
  | ----------------------------------- | ----------- |
  | Numeric, ≥6 digits                  | `:id`       |
  | RFC-4122 UUID (8-4-4-4-12 hex)      | `:uuid`     |
  | Contains `@…`                       | `:email`    |
  | Hex-only, ≥16 chars                 | `:hex`      |
  | Alphanumeric, ≥20 chars (mixed)     | `:token`    |

  Host is preserved (it's the API endpoint identity, not
  customer PII). Scheme + port + `?query` are dropped entirely.
  Conservative by design — over-sanitisation is preferred over
  leak. Short version + date segments (`/v1`, `/2024`) stay raw.

- **MetricKit hang + crash diagnostics
  (`Diagnostics/MetricKitSubscriber.swift`).** Subscribes to
  `MXMetricManager.shared` and routes `MXDiagnosticPayload.hangDiagnostics`
  + `.crashDiagnostics` into the standard event-queue path:

  - Hangs (main thread frozen ≥250ms) → `event_type=crash`,
    `event_name=hang`, properties include `frozen_ms`,
    `stack_trace` (full Apple call-stack-tree JSON),
    `app_version`, `os_version`, `device_type`, `historical=true`.
  - Crashes (SIGABRT / SIGSEGV / SIGILL / etc.) → `event_type=crash`,
    `event_name=metric_kit_crash`, properties include `signal_name`,
    `signal_code`, `exception_type`, `termination_reason`,
    `stack_trace`, `historical=true`, `metric_kit=true`.

  Apple delivers these payloads either daily (~24h post-event) or
  on the next launch after the host app's most recent crash.
  Stack traces include addresses the SDK could never capture from
  inside a Swift runloop observer.

### Fixed

- **Crash delivery reliability.** Removed the POSIX signal
  handlers in `CrashTracker` that called `enqueue + flush`
  synchronously from inside the signal handler. The handler
  required `malloc`, the Swift runtime, `JSONEncoder`, and
  `URLSession` — all of which are async-signal-unsafe
  (`man 2 sigaction`). On a real crash the in-handler path
  almost always either deadlocked the dying thread or silently
  corrupted state, so the crash event never actually reached the
  backend in production.

  Replacement is MetricKit (above) — the OS-blessed iOS path
  used by Sentry, Bugsnag, Firebase Crashlytics, and Datadog
  Mobile as their canonical source. Trade-off accepted: crash
  events show up ~24h delayed (or on the next launch) instead of
  in real time. The "real-time" claim of the old path was
  illusory anyway — most signal-handler crash reports never
  landed.

  The `CrashTracker` type itself stays callable for source-compat;
  the `init(handler:)` no longer wires up signal handlers. No
  customer-code changes required.

### Notes

- Privacy Manifest (`PrivacyInfo.xcprivacy`) from v1.0.1 is
  preserved in the v1.0.2 XCFramework — Apple's third-party-SDK
  requirement is still in force.
- `sdkVersion` payload stamp bumped `1.0.1` → `1.0.2` in
  `Transport.swift`.

---

## [1.0.1] — 2026-05-14

iOS Wave 1 — security fix + App Store privacy compliance.

**Built from** `kixo-ios-sdk@7983255` with Xcode 26.4 / Swift 6.3.1.

### Fixed

- **Environment auto-detect leak (security)** — Removed `#if DEBUG`,
  `targetEnvironment(simulator)`, and TestFlight-sandbox-receipt
  detection from `EnvironmentDetector.detect()`. The SDK is source-
  distributed inside the binary (`BUILD_LIBRARY_FOR_DISTRIBUTION=YES`
  swiftinterface preserves the macros at the **customer's** build-
  context), which meant a customer's Xcode Debug build of THEIR app
  routed Kixo events to `sdk.dev.kixo.io` (Kixo's internal dev
  backend) and TestFlight builds routed to staging. Customer-
  distributable debug + sandbox builds were leaking event data to
  a backend the customer doesn't have an account on.

  Now: `EnvironmentDetector.detect()` always returns `"production"`.
  The only path to `"development"` or `"staging"` is the operator
  passing `ConfigurationOptions(environment: "development")`
  explicitly. Identical class of bug to Android v0.1.2's
  FLAG_DEBUGGABLE removal.

  Drop-in upgrade — no customer code changes required. Existing
  `ConfigurationOptions(environment: "...")` explicit overrides
  keep working.

### Added

- **Privacy Manifest (`PrivacyInfo.xcprivacy`)** — Apple has
  required this for third-party SDKs since May 1, 2024. Without
  it, every Kixo customer's app fails Apple's privacy-manifest
  validation at App Store submission. We were a new-customer
  App Store blocker.

  Declares: `NSPrivacyTracking=false`, no tracking domains, 5
  collected data type categories (DeviceID, ProductInteraction,
  CrashData, PerformanceData, OtherDiagnosticData — all marked
  "linked to user within the customer's app context, NOT used
  for tracking across apps"), 4 required-reason API categories
  with the correct reason codes (UserDefaults `CA92.1`, DiskSpace
  `E174.1`, SystemBootTime `35F9.1`, FileTimestamp `C617.1`).

  Bundled via SwiftPM `resources: [.copy("PrivacyInfo.xcprivacy")]`
  in the source target's `Package.swift`. The XCFramework includes
  the file in its main bundle automatically.

### Changed

- `sdkVersion` runtime stamp `0.1.0` → `1.0.1`. The source repo
  had drifted from the published `v1.0.0` tag — every emitted
  event payload's `sdk_version` field now matches the SwiftPM
  resolved tag. Cosmetic but eliminates the "what version am I
  actually running" support escalation.

---

## [1.0.0] — 2026-05-01

Initial public release.

**Built from** `kixo-ios-sdk@deee36482544d15d630f4c1e9fa2690a76d6bc26`
with Xcode 26.4 / Swift 6.3.1. Reproduce with:

```sh
cd kixo-ios-sdk && git checkout deee36482544
./Distribution/build-xcframework.sh
shasum -a 256 build/KixoSDK.xcframework.zip
# expect: bbbc5443f2442c1116224415f8b9656bbfccc01d9737ab59d57aa34a634568c6
```

### Auto-tracking

- Screen views (UIKit + SwiftUI) with semantic-role fingerprinting and
  human-readable name resolution.
- Tap, long-press, swipe, multi-tap, pinch interactions captured via
  native gesture recognizers (no `UIWindow.sendEvent` swizzle —
  scroll-safe at 60–240 Hz).
- `URLSession` request + response code tracking with built-in SDK /
  vendor classification (1100+ catalog entries).
- Cold launch, foreground, background, and idle-timeout-based session
  start / end events.
- Crash capture via Mach exception + signal handlers.

### Identity

- `Kixo.identify(_:traits:)` for assigning a stable user id.
- `Kixo.setUserProperty(_:value:)` with the typed `StandardProperty`
  enum for `$email`, `$phone`, `$name`, `$plan`, etc.
- Custom traits as free-form key–value pairs.
- Multi-device merge on the backend keyed by `userId`.

### Push notifications

- `Kixo.setPushToken(_:provider:)` with `.apns` and `.firebase`
  providers.
- Auto-tracked `push_received`, `push_opened`, `push_dismissed`, and
  `push_permission` events.
- Push-attribution window of 30 minutes (configurable).
- Three content modes: `full` (default), `preview`, and `hash_only`
  for privacy-strict deployments.

### Session replay

- Opt-in via `ConfigurationOptions(replayEnabled: true)`.
- HEIC frame capture with screen-name fingerprinting.
- `SnapshotMerger` over four passes (UIView, Accessibility, Layer,
  Mirror) for structural fidelity.
- Native PII filter combining regex + Luhn + `NLTagger`.
- `.kixoSensitive()` view modifier for explicit redaction.
- Bandwidth-aware: Wi-Fi-only by default, Low Power Mode pauses,
  thermal-warm throttle.
- Per-tap interaction taxonomy (`tap`, `long_press`, `swipe_*`,
  `multi_tap`, `pinch_*`, `scroll_end`).

### Data durability

- All ingest events queue into a SQLite WAL store under the app
  sandbox (Mixpanel MPDB pattern, flag column for crash recovery).
- Per-event ack contract — accepted events are deleted, rejected
  events are reset for retry.
- Replay events land in a separate `replay-events.sqlite` queue
  with per-row credentials, FIFO eviction past 2000 rows, and a
  10-attempt retry cap.

### Operational

- `Kixo.flush()` and `Kixo.flush(timeout:)` for forced drain.
- `Kixo.optOut()` immediately stops new event collection.
- `Kixo.reset()` clears identity + super-properties + flushes queue.
- `Kixo.diagnostics()` returns runtime state for support tickets.

### Distribution

- Closed-source binary delivery via Swift Package Manager.
- Module name `KixoSDK` (`import KixoSDK`); public class remains
  `Kixo` for natural call-site syntax (`Kixo.configure(...)`).
- iOS device `arm64` + iOS simulator `arm64` + `x86_64` slices
  bundled in the same XCFramework.
- dSYMs included for crash-reporting symbolication.
