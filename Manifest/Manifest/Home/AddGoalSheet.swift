//
//  AddGoalSheet.swift
//  Manifest
//
//  The Home "+" affordance — same capture pattern as onboarding's Goal
//  Capture screen, minus the funnel chrome, presented as a sheet. Text
//  entry, then the same GoalCraftingView used in onboarding (content-safety
//  check + "does this feel right?") before the goal is actually saved.
//

import SwiftUI
import SwiftData

struct AddGoalSheet: View {
    var settings: AppSettings

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Goal> { $0.fulfilledAt == nil }) private var activeGoals: [Goal]
    @FocusState private var isTextFocused: Bool
    @State private var text = ""
    @State private var category: GoalCategory = .career
    @State private var customCategoryLabel = ""
    @State private var style: ManifestationStyle
    @State private var isCrafting = false

    init(settings: AppSettings) {
        self.settings = settings
        _style = State(initialValue: settings.defaultStyle)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isCrafting {
                    GoalCraftingView(
                        initialText: text.trimmingCharacters(in: .whitespacesAndNewlines),
                        style: style,
                        language: settings.language
                    ) { finalText in
                        let goal = Goal(
                            text: finalText,
                            category: category,
                            customCategoryLabel: category == .custom ? customCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                            style: style
                        )
                        modelContext.insert(goal)
                        NotificationScheduler.reschedule(settings: settings, activeGoals: activeGoals + [goal])
                        Analytics.track("goal_created", ["style": style.rawValue, "category": category.rawValue, "source": "home"])
                        dismiss()
                    }
                } else {
                    captureStep
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var captureStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New manifestation")
                .font(.newsreader(29))
                .foregroundStyle(.textPrimary)

            TextEditor(text: $text)
                .focused($isTextFocused)
                .font(.newsreader(20))
                .foregroundStyle(.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(height: 120)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            CategoryPicker(category: $category, customLabel: $customCategoryLabel, language: settings.language)

            StyleChipPicker(style: $style, language: settings.language)

            Spacer()

            PrimaryButton(title: "Continue", isEnabled: isValid) {
                isTextFocused = false
                isCrafting = true
            }
        }
        .padding(24)
        .background(Color.appBackground.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { isTextFocused = false }
    }

    private var isValid: Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if category == .custom {
            return !customCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }
}

#Preview {
    AddGoalSheet(settings: AppSettings())
}
