//
//  OnboardingCoordinator.swift
//  Manifest
//

import Foundation

@Observable
final class OnboardingCoordinator {
    enum Step: Int, CaseIterable {
        case welcome, gatekeeper, style, colorTheme, permissions
        case goalCapture, craftGoal, ritualPreview, appSelection, schedule, paywall
    }

    var step: Step = .welcome

    // Held between Goal Capture and Goal Crafting — the goal itself isn't
    // created until crafting confirms (content-safety check + user
    // agreement happen first, before anything is saved).
    var draftGoalText = ""
    var draftGoalCategory: GoalCategory = .career
    var draftGoalCustomCategoryLabel: String?
    var draftGoalStyle: ManifestationStyle = .present

    /// The goal once actually created, at the end of crafting.
    var draftGoal: Goal?

    func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func back() {
        guard step.rawValue > 0, let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }
}
