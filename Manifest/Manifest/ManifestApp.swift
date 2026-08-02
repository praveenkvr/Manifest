//
//  ManifestApp.swift
//  Manifest
//
//  Created by praveen kuruvada on 7/30/26.
//

import SwiftUI
import SwiftData
import RevenueCat

@main
struct ManifestApp: App {
    init() {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String ?? ""
        if !apiKey.isEmpty {
            Purchases.configure(withAPIKey: apiKey)
            EntitlementStore.shared.startListening()
        } else {
            print("[ManifestApp] REVENUECAT_API_KEY not set in Config.xcconfig — paywall will show its unavailable state.")
        }
        NotificationRouter.shared.startListening()
        DiagnosticsReporter.shared.startListening()
        // AnalyticsGate's cached value is available synchronously (from
        // UserDefaults) even before the network refresh below resolves, so
        // Analytics.configure() reads a real opt-in/out state from the start
        // rather than always defaulting to "on" for the first few seconds.
        Analytics.configure()
        Task {
            await AnalyticsGate.shared.refresh()
            Analytics.applyGate()
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Goal.self,
            DailyScript.self,
            RitualLog.self,
            NineSession.self,
            AppSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
