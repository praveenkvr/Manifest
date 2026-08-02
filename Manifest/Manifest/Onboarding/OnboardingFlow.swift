//
//  OnboardingFlow.swift
//  Manifest
//
//  Drives the full onboarding funnel (screens 1-10). The final Paywall step
//  sets settings.hasCompletedOnboarding = true, handing off to MainTabView.
//

import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @State private var coordinator = OnboardingCoordinator()

    var body: some View {
        Group {
            switch coordinator.step {
            case .welcome:
                WelcomeView(coordinator: coordinator)
            case .gatekeeper:
                GatekeeperView(coordinator: coordinator)
            case .style:
                StylePickerView(coordinator: coordinator, settings: settings)
            case .colorTheme:
                ColorThemePickerView(coordinator: coordinator, settings: settings)
            case .permissions:
                PermissionsView(coordinator: coordinator, settings: settings)
            case .goalCapture:
                GoalCaptureView(coordinator: coordinator, settings: settings)
            case .craftGoal:
                GoalCraftingView(
                    initialText: coordinator.draftGoalText,
                    style: coordinator.draftGoalStyle,
                    language: settings.language
                ) { finalText in
                    let goal = Goal(
                        text: finalText,
                        category: coordinator.draftGoalCategory,
                        customCategoryLabel: coordinator.draftGoalCustomCategoryLabel,
                        style: coordinator.draftGoalStyle
                    )
                    modelContext.insert(goal)
                    coordinator.draftGoal = goal
                    Analytics.track("goal_created", ["style": goal.style.rawValue, "category": goal.category.rawValue, "source": "onboarding"])
                    coordinator.advance()
                }
            case .ritualPreview:
                RitualPreviewView(coordinator: coordinator)
            case .appSelection:
                AppSelectionView(coordinator: coordinator, settings: settings)
            case .schedule:
                ScheduleView(coordinator: coordinator, settings: settings)
            case .paywall:
                PaywallView(settings: settings, source: "onboarding") {
                    Analytics.track("onboarding_completed")
                    settings.hasCompletedOnboarding = true
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        .animation(.easeInOut(duration: 0.25), value: coordinator.step)
        // One tracking point for the entire funnel instead of instrumenting
        // every screen — fires on the first step too (.task) and on every
        // step change after (.onChange), so drop-off is visible per step
        // without needing to touch each onboarding view individually.
        .task { Analytics.screen("onboarding_\(coordinator.step)") }
        .onChange(of: coordinator.step) { _, newStep in
            Analytics.screen("onboarding_\(newStep)")
        }
    }
}
