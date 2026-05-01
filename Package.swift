// swift-tools-version: 5.9
import PackageDescription

// ════════════════════════════════════════════════════════════════
// Kixo iOS SDK — closed-source binary distribution
//
// This package vends a precompiled `KixoSDK.xcframework` bundle.
// Customers add it via Xcode → File → Add Package Dependencies →
// paste this repository URL, OR by referencing it in their own
// Package.swift:
//
//     .package(url: "https://<git-host>/kuicktech/kixo-ios-sdk-release.git",
//              from: "1.0.0")
//
// Then `import KixoSDK` and call `Kixo.configure(...)`. Full setup
// + API reference: see README.md.
//
// Why the module is named `KixoSDK` while the public class stays
// `Kixo`: shipping a closed-source SDK requires Swift's library
// evolution (`BUILD_LIBRARY_FOR_DISTRIBUTION=YES`) so customers'
// apps can be built with newer Xcodes than the SDK was. Library
// evolution emits an `extension Kixo.<Type>` swiftinterface; if
// the module name and the public class share the bare word
// `Kixo`, the swiftinterface verifier can't disambiguate them.
// We solve this by naming the framework module `KixoSDK` while
// keeping the public class `Kixo`. Customer code reads naturally:
//
//     import KixoSDK
//     Kixo.configure(projectId: "kx_proj_…", apiKey: "kx_key_…")
//
// Same pattern is used by Stripe (module `Stripe`, namespacing
// class `StripeAPI`), Sentry (module `Sentry`, entry `SentrySDK`),
// AppsFlyer (module `AppsFlyerLib`, entry class `AppsFlyer`).
// ════════════════════════════════════════════════════════════════

let package = Package(
    name: "KixoSDK",
    platforms: [
        // Kixo currently targets iOS 26+. Customers on earlier
        // iOS versions are out of scope. Bump this minimum
        // alongside any SDK release that uses APIs introduced in
        // a newer SDK.
        .iOS("26.0"),
    ],
    products: [
        .library(
            name: "KixoSDK",
            targets: ["KixoSDK"],
        ),
    ],
    targets: [
        // Local binary target — the .xcframework lives inside this
        // repo at the path below. Switch to a hosted target
        // (`url:` + `checksum:`) once the artifact is uploaded to
        // a GitHub release; the build script emits both forms.
        .binaryTarget(
            name: "KixoSDK",
            path: "Frameworks/KixoSDK.xcframework",
        ),
    ],
)
