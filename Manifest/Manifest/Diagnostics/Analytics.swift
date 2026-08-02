//
//  Analytics.swift
//  Manifest
//
//  Thin wrapper around PostHog — every call site in the app goes through
//  here instead of importing PostHog directly, so the no-PII rules and the
//  AnalyticsGate kill switch are enforced in exactly one place.
//
//  No accounts exist in this app, so every event is anonymous by
//  construction: personProfiles is `.never` (PostHog is told never to build
//  a person profile, even implicitly), identify()/alias() are never called,
//  and event properties are restricted to small enums and counts — never
//  goal text, AI-generated content, or anything else the user typed.
//  Autocapture (captureElementInteractions, captureScreenViews) is off in
//  favor of the explicit .screen()/.track() calls placed at each real
//  screen and meaningful action — deliberate and auditable beats "capture
//  everything and hope nothing sensitive leaks in." Session replay is off
//  for the same reason.
//
//  Batching, retry/backoff, and offline queueing are all handled by the SDK
//  itself — no need to hand-roll them.
//

import Foundation
import PostHog

enum Analytics {
    static func configure() {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "PostHogAPIKey") as? String ?? ""
        guard !apiKey.isEmpty else {
            print("[Analytics] POSTHOG_API_KEY not set in Config.xcconfig — analytics disabled.")
            return
        }

        let config = PostHogConfig(projectToken: apiKey)
        config.captureScreenViews = false // SwiftUI has no real view controllers to swizzle — manual .screen() instead
        config.captureElementInteractions = false // no autocapture — explicit events only
        config.sessionReplay = false
        config.personProfiles = .never // no accounts, ever — every event is anonymous
        config.optOut = !AnalyticsGate.shared.isEnabled

        PostHogSDK.shared.setup(config)
    }

    /// Called on every foreground alongside AnalyticsGate.refresh() — applies
    /// a kill-switch flip without needing to relaunch the app.
    static func applyGate() {
        guard PostHogSDK.shared.isOptOut() != !AnalyticsGate.shared.isEnabled else { return }
        if AnalyticsGate.shared.isEnabled {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
        }
    }

    static func screen(_ name: String, _ properties: [String: Any] = [:]) {
        PostHogSDK.shared.screen(name, properties: properties)
    }

    static func track(_ event: String, _ properties: [String: Any] = [:]) {
        PostHogSDK.shared.capture(event, properties: properties)
    }

    /// Called when the app leaves the foreground (RootView's scenePhase
    /// handler) so queued events aren't stuck in memory if the app gets
    /// force-quit shortly after backgrounding.
    static func flush() {
        PostHogSDK.shared.flush()
    }
}
