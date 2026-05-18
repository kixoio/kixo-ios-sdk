# Kixo iOS SDK

The Kixo SDK ships product analytics, session replay, push tracking, and crash
reporting for iOS apps in a single drop-in package. After one `Kixo.configure(...)`
call the SDK auto-tracks every screen view, tap, network request, push
notification, and (optionally) a privacy-aware visual replay of each session.

| | |
|---|---|
| **Distribution** | Swift Package Manager binary target (`KixoSDK.xcframework`) |
| **Architectures** | iOS device `arm64`, iOS simulator `arm64` + `x86_64` |
| **iOS minimum** | iOS 26.0 |
| **Swift / Xcode** | Swift 5.9, Xcode 15+ |
| **License** | Commercial — see `LICENSE.md` |
| **Support** | <support@kixo.io> |

---

## Install (Swift Package Manager)

### Xcode UI

1. **File → Add Package Dependencies…**
2. Paste the repository URL we provided you and click *Add Package*.
3. Select your app target and click *Add Package*.

### `Package.swift`

```swift
dependencies: [
    .package(
        url: "https://<git-host>/kuicktech/kixo-ios-sdk-release.git",
        from: "1.0.6"
    ),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "KixoSDK", package: "kixo-ios-sdk-release"),
        ]
    )
]
```

> The module is named `KixoSDK`. The public type you call into is `Kixo`.

---

## Quick start

In your `App` (SwiftUI) or `AppDelegate.application(_:didFinishLaunchingWithOptions:)`:

```swift
import KixoSDK

@main
struct MyApp: App {
    init() {
        Kixo.configure(
            projectId: "kx_proj_xxxxxxxxxxxxxxxxxxxxxxxx",
            apiKey:    "kx_key_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        )
    }
    var body: some Scene { WindowGroup { ContentView() } }
}
```

That's it. With no further configuration the SDK auto-tracks:

- screen views (UIKit + SwiftUI),
- taps and key gesture interactions,
- outbound `URLSession` requests + response codes,
- session start / end with idle timeout,
- app lifecycle (cold launch, foreground, background),
- crashes (Mach exception + signal handlers),
- push delivery + open + dismiss + permission state.

---

## Identify users

```swift
// When you know who the user is (e.g. after sign-in)
// Reserved standard property keys carry a `$`-prefix (Mixpanel
// convention) so they namespace away from your own custom traits.
Kixo.identify("user_123", traits: [
    "$email": "jane@example.com",       // identity
    "$name":  "Jane Doe",                // identity
    "$plan":  "pro",                     // saas pack
    "$lifetime_orders": 12,              // ecommerce pack
    "signup_source": "twitter_ad",       // custom trait
])

// Standardized profile properties — these populate the audience
// explorer + drive segmentation. Always prefer the typed enum
// over a free-form string key.
Kixo.setUserProperty(.email, value: "user@example.com")
Kixo.setUserProperty(.firstName, value: "Anna")
Kixo.setUserProperty(.country, value: "US")
Kixo.setUserProperty(.plan, value: "pro")

// Or in bulk — reserved keys with `$`-prefix, custom traits bare
Kixo.setUserProperties([
    "$email":           "user@example.com",
    "$plan":            "pro",
    "$lifetime_orders": 12,
    "signup_source":    "twitter_ad"
])

// Boolean flags — tag a user for segmentation & campaigns
Kixo.setUserProperty("subscribe", value: true)   // segment: subscribe = true
Kixo.setUserProperty("vip", value: true)
Kixo.setUserProperty("beta_tester", value: false)

// On sign-out — clears identity + flushes the queue.
Kixo.reset()
```

### Reserved-namespace catalog (37 properties across 8 packs)

The catalog is split into three **universal** packs (always rendered
in the dashboard) and five **vertical** packs (rendered only when at
least one property in the pack is populated — the dashboard
auto-detects each project's vertical):

| Pack | Kind | Keys |
|---|---|---|
| `identity` | universal | `$email`, `$phone`, `$name`, `$first_name`, `$last_name`, `$avatar_url` |
| `geo` | universal | `$country`, `$city`, `$region`, `$timezone`, `$language`, `$locale` |
| `lifecycle` | universal | `$created`, `$last_seen` |
| `saas` | vertical | `$plan`, `$subscription_status`, `$trial_ends`, `$mrr`, `$subscription_started` |
| `ecommerce` | vertical | `$lifetime_orders`, `$lifetime_revenue`, `$aov`, `$last_purchase`, `$first_purchase`, `$cart_abandoned_count` |
| `media` | vertical | `$content_tier`, `$subscribed_categories`, `$watch_time_total`, `$last_played` |
| `marketplace` | vertical | `$seller_tier`, `$buyer_tier`, `$listings_count`, `$reviews_count`, `$verified` |
| `loyalty` | vertical | `$loyalty_points`, `$vip_level`, `$referral_count` |

Don't see your pattern? Use bare keys for custom traits — they
surface in the dashboard's *Custom Traits* panel without polluting
profile columns.

Boolean values are the cleanest way to **tag a user** —
`setUserProperty("subscribe", value: true)` lets the chat say
*"send a welcome email to users where subscribe is true"* and Kixo
builds the segment automatically.

---

## Track custom events

```swift
Kixo.track("checkout_started", properties: [
    "cart_value": 49.90,
    "currency":   "USD",
    "items_count": 3
])
```

Property values can be `String`, `Bool`, integer, double, `Date`, or arrays
of those types. Nested dictionaries are flattened into dotted keys server-side.

### Typed event helpers

A handful of common events have typed sugar so you can't mistype the property
keys. Currently supported:

| Helper | Signature highlights | Backing event |
|---|---|---|
| `Kixo.trackPurchase(...)` | `amount`, `currency`, `productId`, `productName`, `quantity` | `purchase` |
| `Kixo.trackSubscriptionStart(...)` | `plan`, `amount`, `currency`, `interval` (`SubscriptionInterval`) | `subscribe_start` |
| `Kixo.trackTrialStart(...)` | `plan`, `days` | `trial_start` |
| `Kixo.trackCancel(...)` | `plan`, `reason` | `cancel` |
| `Kixo.trackUpgrade(...)` | `fromPlan`, `toPlan` | `upgrade` |
| `Kixo.trackSignup(...)` | `method`, `plan` | `signup` |
| `Kixo.trackActivation(...)` | `event` (label of the activation step) | `activation` |
| `Kixo.trackShare(...)` | `channel`, `contentId` | `share` |
| `Kixo.trackInvite(...)` | `channel`, `recipientCount` | `invite` |

If your app is heavily commerce-driven, prefer these — they bind to the
schema your dashboard reports already understand. All helpers accept an
extra `properties: [String: Any]` parameter for ad-hoc fields.

---

## Push notifications

Kixo never holds your push token; it only forwards it to the Kixo backend
for delivery + attribution. Register the token in your `AppDelegate`:

```swift
import KixoSDK

func application(_ app: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken token: Data) {
    let hex = token.map { String(format: "%02x", $0) }.joined()
    Kixo.setPushToken(hex, provider: .apns)
}
```

If you use Firebase Cloud Messaging, register the FCM token instead:

```swift
Kixo.setPushToken(fcmToken, provider: .firebase)
```

After registration Kixo automatically tracks `push_received`, `push_opened`,
`push_dismissed`, and `push_permission` events — you don't write any of that
plumbing yourself.

---

## Session replay

Replay is **opt-in**. Enable it in `ConfigurationOptions`:

```swift
Kixo.configure(
    projectId: "kx_proj_…",
    apiKey:    "kx_key_…",
    options: ConfigurationOptions(
        replayEnabled:           true,
        replaySampleRate:        1.0,   // 0.0…1.0 — fraction of sessions sampled
        replayCaptureOnCellular: false  // Wi-Fi only by default
    )
)
```

What gets captured:

- a sequence of HEIC frames (one per significant UI change),
- per-tap coordinates, gesture kind, and target `accessibilityIdentifier`,
- structural snapshots of the view hierarchy (no pixel data for sensitive views).

What is **never captured automatically**:

- `UITextField.isSecureTextEntry == true` — passwords, OTPs, etc.
- `UITextField.textContentType` ∈
  `{ .creditCardNumber, .password, .newPassword, .oneTimeCode }`.
- `WKWebView` content (whole bounds — we can't introspect web text).
- `AVPlayerLayer` content (whole bounds — DRM + paid-video privacy).
- Any text run that the on-device PII filter flags — emails,
  phone numbers, and Luhn-validated card-shaped digit sequences are
  scrubbed via `NLTagger` over OCR text before upload.

To explicitly mark an extra view as sensitive (UIKit):

```swift
cardNumberLabel.kxRedact = true
```

The flag is stored as an associated object so it survives view-controller
transitions. Set it on any container — the entire visible bounds are
rasterized into a black rect on every captured frame.

> SwiftUI `.kixoSensitive()` is in flight for v1.1. Until then, host
> SwiftUI views with sensitive content inside `UIViewControllerRepresentable`
> or `UIViewRepresentable` and set `kxRedact` on the underlying UIKit view.

Replay is bandwidth-aware: with `replayCaptureOnCellular = false`
(the default) frames buffer to disk on cellular and only upload on
Wi-Fi — no data lost, just radio cost gated. Uploads also pause on
Low Power Mode and throttle when the device runs thermal-warm.

---

## Configuration options

The full surface of `ConfigurationOptions`:

| Option | Default | Description |
|---|---|---|
| `autoTrackScreens` | `true` | Auto-track UIKit + SwiftUI screen views |
| `autoTrackTaps` | `true` | Auto-track tap / long-press / swipe interactions |
| `autoTrackNetwork` | `true` | Auto-track URLSession requests + response codes |
| `autoTrackCrashes` | `true` | Install Mach + signal crash handlers |
| `autoTrackSessions` | `true` | Track session start / end with idle timeout |
| `autoTrackPush` | `true` | Track push delivery + open events |
| `pushAttributionWindowSeconds` | `1800` | Window for attributing app opens to a push (30 min) |
| `sessionTimeout` | `30` | Idle **seconds** before a new session starts. Bump to `1800` for the 30-min industry default. |
| `flushInterval` | `30` | Seconds between event-batch flushes |
| `flushAt` | `20` | Flush immediately when the queue exceeds this |
| `maxBufferSize` | `200` | Hard cap on the event queue while offline |
| `apiHost` | auto | Resolved per environment: `sdk.dev.kixo.io` (development), `sdk.staging.kixo.io` (staging), `sdk.kixo.io` (production). Override only for self-hosted backends. |
| `debug` | auto | Print verbose `[Kixo]` log lines. Defaults to `true` in Xcode Debug builds, `false` in TestFlight / App Store. |
| `environment` | auto | Auto-detected: `development` (Sim / Debug), `staging` (TestFlight sandbox), `production` (App Store). Pass any string to override. |
| `replayEnabled` | `false` | Enable session replay |
| `replaySampleRate` | `0.05` | Fraction of sessions captured (0.0–1.0). 5% default keeps storage / bandwidth modest; bump for low-traffic apps. |
| `replayCaptureOnCellular` | `false` | If `false`, replay frames stay on disk on cellular and upload on Wi-Fi |

---

## Privacy & data residency

- Events buffer in **SQLite WAL** under your app's sandbox until they flush.
  No data is shared with other apps.
- Files are protected at iOS class
  `completeUntilFirstUserAuthentication` — they can't be read at lock screen.
- `Kixo.reset()` clears the in-memory identity (user id, traits,
  super-properties), forces a final queue flush, and starts a new
  anonymous session. Use this on user sign-out.
- For customers with a hard "stop tracking me" requirement, gate the
  initial `Kixo.configure(...)` call behind your own consent toggle —
  if the SDK is never configured, no data is collected. (A first-class
  `Kixo.optOut()` API ships in 1.1.)
- Ingest endpoints + storage region are configured per-tenant; see your
  account's *Data Processing Addendum* for region + retention specifics.
- The SDK never reads from the system pasteboard, photo library, contacts,
  or location services.

---

## Common API quick reference

```swift
// Lifecycle
Kixo.configure(projectId: …, apiKey: …, options: …)
Kixo.reset()                              // sign-out / new anonymous session

// Identity
Kixo.identify(_:traits:)
Kixo.setUserProperty(_:value:)            // String key form
Kixo.setUserProperty(.email, value: …)    // typed StandardProperty
Kixo.setUserProperties([:])
Kixo.group(_:traits:)

// Events
Kixo.track(_:properties:)
Kixo.screenView(_:properties:)
Kixo.trackPurchase(amount:currency:productId:productName:quantity:)
Kixo.trackSubscriptionStart(plan:amount:currency:interval:)
Kixo.trackInvite(channel:recipientCount:)

// Super-properties (sent on every event)
Kixo.setSuperProperty(_:value:)
Kixo.setSuperProperties([:])
Kixo.unsetSuperProperty(_:)
Kixo.clearSuperProperties()

// Push
Kixo.setPushToken(_:provider:)            // .apns | .firebase
Kixo.logPushReceived(userInfo:)
Kixo.logPushOpened(userInfo:)
Kixo.logPushDismissed(userInfo:)

// Operational
Kixo.flush()
Kixo.flush(timeout: 5.0)
Kixo.diagnostics()
```

---

## Troubleshooting

**No events showing up in the dashboard.** Check that:

1. `projectId` / `apiKey` are correct and from the same project (they're a pair).
2. The device has an internet connection — the SDK will buffer offline and
   flush on next foreground.
3. `Kixo.optOut()` wasn't called somewhere on launch.
4. Set `options: ConfigurationOptions(debug: true)` to see SDK log output —
   look for the line `[Kixo] Lifecycle initialising → running` followed by
   `[Kixo] Init: release_id = …`. If you don't see those, configuration
   never reached the backend.

**Build error: "module 'KixoSDK' was not compiled with library evolution
support".** You're consuming a build-from-source variant; switch to the
binary release (this repo) — `Package.swift` here points at
`KixoSDK.xcframework`.

**Build error: "Failed to verify module interface of KixoSDK".** Your Xcode
is older than the one we built the framework with. Update Xcode (15.x or
newer) or contact us for a back-port build.

**`xcframework not found` / corrupted artifact.** Run `swift package
clean` in your project, then `swift package resolve`. SPM caches binary
targets aggressively.

---

## Support

- General: <support@kixo.io>
- Security disclosures: <security@kixo.io>
- Account / contract: <hello@kixo.io>

We aim to respond to support tickets within one business day.
