//
//  RootView.swift
//  Manifest
//
//  App entry point: bootstraps the singleton AppSettings row, then switches
//  between the onboarding flow and the main app based on its
//  hasCompletedOnboarding flag.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settingsList: [AppSettings]

    var body: some View {
        Group {
            if let settings = settingsList.first {
                if settings.hasCompletedOnboarding {
                    MainTabView(settings: settings)
                } else {
                    OnboardingFlow(settings: settings)
                }
            } else {
                Color.paper.ignoresSafeArea()
                    .task { modelContext.insert(AppSettings()) }
            }
        }
        // Manual toggle, not the system appearance — Settings > Dark theme
        // (AppTheme) drives this directly, defaulting to light.
        .preferredColorScheme(settingsList.first?.theme == .dark ? .dark : .light)
        // Overrides the app's text locale from Settings > Language instead
        // of following the device's system language — without this, every
        // Text() in the app always resolves against the device locale, so
        // switching the in-app picker had no visible effect no matter how
        // many translations existed in the string catalog.
        .environment(\.locale, Locale(identifier: settingsList.first?.language ?? Locale.current.identifier))
        // ThemeStore is what Color+Palette.swift's `.accent*` tokens actually
        // read — this keeps it synced with Settings > Color theme, including
        // at launch, since Color extensions have no direct access to the
        // AppSettings instance itself.
        .task(id: settingsList.first?.accentTheme) {
            if let theme = settingsList.first?.accentTheme {
                ThemeStore.shared.current = theme
            }
        }
        // Placed here rather than in HomeView's own scenePhase handler so it
        // covers onboarding too — a user backgrounding mid-onboarding still
        // gets those events flushed instead of stuck in memory.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { Analytics.flush() }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: AppSettings.self, inMemory: true)
}
