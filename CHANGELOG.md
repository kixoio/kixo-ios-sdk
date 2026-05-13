# Changelog

All notable changes to the Kixo iOS SDK are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
