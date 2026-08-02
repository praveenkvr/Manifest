//
//  GoalCaptureView.swift
//  Manifest
//
//  Screen 5/19 — images/screens/05-goal-capture.png
//

import SwiftUI

struct GoalCaptureView: View {
    var coordinator: OnboardingCoordinator
    var settings: AppSettings

    @FocusState private var isFocused: Bool
    @State private var text = ""
    @State private var category: GoalCategory = .career
    @State private var customCategoryLabel = ""
    @State private var style: ManifestationStyle

    init(coordinator: OnboardingCoordinator, settings: AppSettings) {
        self.coordinator = coordinator
        self.settings = settings
        _style = State(initialValue: settings.defaultStyle)
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 68)

                Text("STEP 1 OF 2")
                    .eyebrowStyle()

                Spacer().frame(height: 8)

                Text("What are you\nmanifesting?")
                    .font(.newsreader(37))
                    .foregroundStyle(.ink900)
                    .lineSpacing(2)

                Spacer().frame(height: 12)

                Text("Plain words are perfect. One goal to start.")
                    .font(.manrope(15))
                    .foregroundStyle(.slate500)

                Spacer().frame(height: 22)

                TextEditor(text: $text)
                    .focused($isFocused)
                    .font(.newsreader(22))
                    .foregroundStyle(.ink900)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(height: 160)
                    .background(Color.paperAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isFocused ? Color.accent300 : Color.clear, lineWidth: 2)
                    )

                Spacer().frame(height: 18)

                CategoryPicker(category: $category, customLabel: $customCategoryLabel, language: settings.language)

                Spacer().frame(height: 18)

                StyleChipPicker(style: $style, language: settings.language)

                Spacer()

                PrimaryButton(
                    title: "Continue",
                    isEnabled: isValid
                ) {
                    coordinator.draftGoalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    coordinator.draftGoalCategory = category
                    coordinator.draftGoalCustomCategoryLabel = category == .custom
                        ? customCategoryLabel.trimmingCharacters(in: .whitespacesAndNewlines) : nil
                    coordinator.draftGoalStyle = style
                    coordinator.advance()
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
        .onTapGesture { isFocused = false }
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
    GoalCaptureView(coordinator: OnboardingCoordinator(), settings: AppSettings())
}
