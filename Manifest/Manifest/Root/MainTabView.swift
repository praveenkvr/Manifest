//
//  MainTabView.swift
//  Manifest
//
//  4-tab shell (Today / Goals / Journey / Settings).
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var settings: AppSettings
    @State private var selectedTab = "today"

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(settings: settings)
                .tabItem { Label("Today", systemImage: "house.fill") }
                .tag("today")

            GoalsListView(settings: settings)
                .tabItem { Label("Goals", systemImage: "bookmark.fill") }
                .tag("goals")

            JourneyView()
                .tabItem { Label("Journey", systemImage: "chart.bar.fill") }
                .tag("journey")

            SettingsView(settings: settings)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag("settings")
        }
        .tint(.accent500)
        .task { Analytics.screen(selectedTab) }
        .onChange(of: selectedTab) { _, newTab in Analytics.screen(newTab) }
    }
}

#Preview {
    MainTabView(settings: AppSettings())
        .modelContainer(for: [Goal.self, RitualLog.self, DailyScript.self], inMemory: true)
}
