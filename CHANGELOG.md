# Changelog

All notable changes to the Kixo iOS SDK are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.12] — 2026-07-05

Adds `autoTrackFlows` — a client-side switch for the always-on journey/flow layer. No behavior change unless you set it.

**XCFramework sha256:** `645eec7aab7205cad0e9fc2afb743acd2780053a7857c6163a5967c82f5cc2cf`.

### Added

- **`ConfigurationOptions.autoTrackFlows`** (default `true`) gates the always-on `FlowRecorder` plus the scroll / tap / screen-transition observers that feed /journey Flows / Map / Funnel. Set `false` to eliminate the always-on scroll/tap observation cost on very scroll-heavy screens — the trade-off is that `ScreenVisit.tapCount` / `scrollCount` and `screen_transition` then ship as zero, so /journey engagement + funnels lose those columns for the app. Client-side only; there is no remote-config equivalent.

---
## [1.0.11] — 2026-07-05

Replay performance, round 2 — the heavy capture pipelines are now off by default, foreground uploads skip disk, and frames are smaller. No public API changes.

**XCFramework sha256:** `92bfaab2a5c1133506543539a6feb7f4aa08c7d7f095dd233286454f294ee644`.

### Changed

- **Structural / per-leaf-tile / OCR passes are now compiled-default OFF.** These are the expensive per-capture stages (a structural view-tree walk measured ~33 ms on a busy screen); they stay off unless the backend enables them per project. Plans that want them (e.g. Enterprise) re-enable via remote config.
- **Memory-first frame upload.** In the foreground, frames PUT straight from memory — no disk write — through an ephemeral session; the disk-spill + background-`URLSession` path is kept only for backgrounding and transient upload failures, so no-data-loss resilience is unchanged. One shared request-builder keeps the signed headers consistent across both paths.
- **Tighter frame compression** — HEIC quality 0.20 → 0.15 plus a 0.85× downscale (~40–50 % fewer bytes per frame, iPad capped at 0.5×). Both are remote-tunable (`replay.heicQuality` / `replay.captureScale`).

Existing integrations pick these up automatically.

---
## [1.0.10] — 2026-07-05

Network-capture redesign + dirty-driven replay cadence — removes the remaining scroll jank on media-heavy feeds. No public API changes.

**XCFramework sha256:** `0f7aa152a250826fceeedc9e93f1783472142da0214dff56a6502eba353cdc25`.

### Changed

- **Network auto-tracking rebuilt around low-cost aggregates.** `autoTrackNetwork` (still default-OFF) now records host + sanitized-route + status/latency buckets and emits a single periodic `network_summary` instead of wrapping every request. The previous global `URLSession` swizzle added per-request work to every image/video load — the dominant cost on scroll-heavy media feeds — and is gone from the default path. Detailed per-request capture is now an opt-in, sampled, remote-gated diagnostic.
- **Replay capture is now dirty-driven (event-based, not timer-based).** Frames are taken only when the UI actually changes — a new screen (~500 ms after entry), a settled interaction, or a periodic heartbeat — behind a cadence floor. Static screens cost nothing; scroll-heavy screens no longer stutter.
- **First-frame guarantee** — a screen frame always exists before the first interaction (cold-start frame + a frame on every screen entry), so replays never open on a blank or late frame.

### Added

- **Opt-in delegate-based network capture** (`Kixo.networkDelegate(wrapping:)`) for apps that want per-request detail without the global swizzle.
- **Server-tunable cadence knobs** — post-tap settle, dirty-heartbeat interval, and scroll-end capture are adjustable per project from the backend.

### Fixed

- **Accurate replay frame timestamps** — frames are stamped with their real capture time, so the dashboard player anchors a tap to the pre-tap screen and shows the resulting screen after the interaction.

---
## [1.0.9] — 2026-07-04

Session-replay capture performance overhaul — removes the main-thread jank on interaction-heavy and video screens. No public API changes.

**XCFramework sha256:** `84b980f520e134d8504322b10dc737b23cc28131c551d771283e6868a4e68b1d`.

### Changed

- **Replay capture is now dirty-region aware and throttled.** Instead of a full-screen render on every interaction, the SDK skips capture when the screen hasn't changed (view-tree signature incl. scroll offset + text), coalesces bursts behind a cadence floor, and captures at scroll-settle rather than mid-scroll. On screens with video + long text during slow scrolls this eliminates the visible stutter.
- **Video / WebView / Metal / camera regions are placeholdered, not screenshotted.** Those layers rasterize to a black frame through every iOS capture API anyway, so the SDK no longer pays the render cost for them.
- **Render primitive rewritten to raw CoreGraphics** (kept `drawHierarchy`), materially cutting the per-frame main-thread block.
- **Over-quota / metadata-only sessions no longer pay any capture cost** — the quota gate now short-circuits before the render.

### Added

- **Server-tunable replay performance knobs** — the backend can disable/adjust the structural pipeline, per-leaf tiles, OCR, and capture cadence per project (kill-switch), applied at session start.
- **Honest upload telemetry** — the SDK reports confirmed uploads and per-reason drop counts (`frames_dropped` / `drop_reasons`) at session end, distinguishing real failures from deliberate perf skips.
- **Pre-upload size guard** — frames are checked against the backend-signed size cap with a quality re-encode ladder before upload; oversize artifacts are dropped cleanly instead of 4xx-ing to a `failed/` directory.
- **`os_signpost` instrumentation** (`io.kixo.replay`) around every capture stage for on-device profiling.

### Fixed

- **Privacy: OCR now fails closed on redaction failure** — if a frame's redaction can't be applied, the SDK skips text recognition for that frame instead of ever reading unredacted pixels.
- **Server-side replay truncation is honored** — when a session hits its per-plan frame/duration cap the SDK stops capturing frames (metadata-only) instead of churning on uploads that can't land.

---
## [1.0.8] — 2026-07-04

Fixes session-replay frame uploads, which were silently failing for every frame.

**XCFramework sha256:** `ac095366da5285abd82773b6524cba367a6b3232ab6b18a22b46879748db143b`.

### Fixed

- **Session-replay frame uploads (100% failure → fixed)** — the signed GCS PUT sent `x-goog-content-length-range: 0,250000`, but the backend signs the upload URL with the canonical universal 20 KB frame cap (`0,20000`). Because that is a *signed* extension header, the byte mismatch produced `403 SignatureDoesNotMatch`, so every captured replay frame was moved to the local `failed/` directory and never reached storage. Aligned the SDK's content-length-range to the backend's 20 KB cap; frames now upload. Analytics, tap capture, and the replay session lifecycle were unaffected — only the pixel-frame upload was broken. (Verified end-to-end on a simulator with real touch injection.)

---
## [1.0.7] — 2026-06-28

App-approval gate support and StoreKit install validation, plus an Xcode 26 build fix.

**XCFramework sha256:** `feb22e3db9fa8a4f95244c62f6c0ac04b59f55fc02e3358b84ff240a3e502986`.

### Added

- **App identity on config refresh + push registration** — the SDK now sends `platform` / `bundle_id` / `environment` / `sdk_version` on remote-config refresh and `app_id` / `release_id` / `bundle_id` / `environment` / `sdk_version` on push-token registration, so Kixo's server-side app-approval gate can scope and approve the app. Existing single-app integrations are unaffected (the first app per project auto-approves).
- **StoreKit 2 install-receipt validation** (`InstallValidator`) — forwards the signed `AppTransaction` JWS to Kixo for deterministic install validation.

### Fixed

- **Xcode 26 / iOS 26 SDK build** — read the app-transaction JWS from `VerificationResult.jwsRepresentation` (the wrapper, available iOS 16+, covers both verified and unverified results) instead of the unwrapped `AppTransaction`, which no longer exposes `jwsRepresentation` in the iOS 26 SDK.
- **Config self-pause on a nil bundle identifier** — a missing `Bundle.main.bundleIdentifier` no longer causes the config call to pause.

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
