//
//  AnalyticsGate.swift
//  Manifest
//
//  Decides whether PostHog should even be running — checks the Worker's
//  /v1/config kill switch on launch and on every foreground, caching the
//  last-known answer locally so a launch with no network still has a value
//  and doesn't default to "on" just because the check failed. Disabling
//  analytics server-side (ANALYTICS_ENABLED=false in wrangler.jsonc,
//  redeployed) takes effect within one app open — no app update needed.
//
//  Deliberately does not import PostHog itself — call sites (ManifestApp,
//  scenePhase handlers) are what start/stop the SDK, this only answers
//  "should it be running right now."
//

import Foundation
import Observation

@Observable
final class AnalyticsGate {
    static let shared = AnalyticsGate()

    private static let cacheKey = "analyticsEnabledCache"
    private let defaults = UserDefaults.standard

    private(set) var isEnabled: Bool

    private init() {
        // Defaults to true only on a genuinely first launch (no cached
        // value yet) — after that, the last server answer wins even offline,
        // rather than silently re-enabling every time the network check fails.
        isEnabled = defaults.object(forKey: Self.cacheKey) as? Bool ?? true
    }

    func refresh() async {
        guard let enabled = await WorkerClient.fetchAnalyticsEnabled() else { return }
        isEnabled = enabled
        defaults.set(enabled, forKey: Self.cacheKey)
    }
}
