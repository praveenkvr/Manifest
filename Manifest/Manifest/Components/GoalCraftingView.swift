//
//  GoalCraftingView.swift
//  Manifest
//
//  Shared "does this feel right?" step used by both onboarding's Goal
//  Capture and Home's Add Goal sheet. One AI call checks the goal for
//  content safety and, if it passes, returns a reflection plus sample
//  affirmation lines so the user can confirm this is really the future
//  they're imagining — or edit the wording (with optional AI-suggested
//  rephrasings) and re-check before it's ever saved.
//

import SwiftUI

struct GoalCraftingView: View {
    var initialText: String
    var style: ManifestationStyle
    var language: String
    var onConfirm: (String) -> Void

    private enum CheckState {
        case loading
        case blocked(reason: String)
        case allowed(reflection: String, sampleLines: [String])
        case failed
    }

    @State private var text: String
    @State private var state: CheckState = .loading
    @State private var isEditing = false
    @State private var suggestions: [String] = []
    @State private var isFetchingSuggestions = false
    @FocusState private var isTextFocused: Bool

    init(initialText: String, style: ManifestationStyle, language: String, onConfirm: @escaping (String) -> Void) {
        self.initialText = initialText
        self.style = style
        self.language = language
        self.onConfirm = onConfirm
        _text = State(initialValue: initialText)
    }

    var body: some View {
        ZStack {
            LinearGradient.welcomeBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 40)

                HStack(spacing: 12) {
                    LumenMascot(mood: .calm, size: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Lumen").font(.manropeBold(15.5)).foregroundStyle(.ink900)
                        Text("checking in on your goal").font(.manrope(14)).foregroundStyle(.slate500)
                    }
                }

                Spacer().frame(height: 22)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        stateContent
                        editSection
                    }
                    .padding(.bottom, 12)
                }

                Spacer(minLength: 12)

                bottomBar
            }
            .padding(.horizontal, 24)
        }
        .task { await check() }
        .contentShape(Rectangle())
        .onTapGesture { isTextFocused = false }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch state {
        case .loading:
            ProgressView().tint(.accent500).frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 40)

        case .failed:
            Text("Couldn't reach Manifest just now. You can still continue with your goal as written.")
                .font(.manrope(15))
                .foregroundStyle(.slate500)

        case .blocked(let reason):
            VStack(alignment: .leading, spacing: 12) {
                Text("Let's try a different angle")
                    .font(.newsreader(25))
                    .foregroundStyle(.ink900)
                Text(reason)
                    .font(.manrope(15))
                    .foregroundStyle(.ink900.opacity(0.75))
                    .lineSpacing(3)
            }
            .padding(18)
            .manifestCard()

        case .allowed(let reflection, let sampleLines):
            VStack(alignment: .leading, spacing: 16) {
                Text(reflection)
                    .font(.newsreader(21))
                    .foregroundStyle(.ink900)
                    .lineSpacing(3)

                if !sampleLines.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HOW IT MIGHT SOUND").eyebrowStyle()
                        ForEach(sampleLines, id: \.self) { line in
                            Text("\u{201C}\(line)\u{201D}")
                                .font(.newsreaderItalic(17))
                                .foregroundStyle(.ink900)
                                .lineSpacing(3)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.paperAlt)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }

                if !isEditing {
                    Text("Does this capture the future you're imagining?")
                        .font(.manrope(14))
                        .foregroundStyle(.slate500)
                }
            }
        }
    }

    @ViewBuilder
    private var editSection: some View {
        if isEditing {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $text)
                    .focused($isTextFocused)
                    .font(.newsreader(18))
                    .foregroundStyle(.ink900)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(height: 90)
                    .background(Color.paperAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.accent300, lineWidth: 2))

                Button {
                    Task { await fetchSuggestions() }
                } label: {
                    HStack(spacing: 6) {
                        if isFetchingSuggestions { ProgressView().tint(.accent500) }
                        Image(systemName: "sparkles")
                        Text("Need suggestions?")
                    }
                    .font(.manrope(14, weight: .semibold))
                    .foregroundStyle(.accent600)
                }
                .disabled(isFetchingSuggestions)

                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        text = suggestion
                        suggestions = []
                    } label: {
                        Text(suggestion)
                            .font(.manrope(14.5))
                            .foregroundStyle(.ink900)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.accent50)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                PrimaryButton(
                    title: "Check this version",
                    isEnabled: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    isTextFocused = false
                    Task { await check() }
                }
            }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        switch state {
        case .allowed where !isEditing:
            VStack(spacing: 10) {
                PrimaryButton(title: "Yes, this is it") {
                    onConfirm(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                Button("Let me adjust the wording") {
                    isEditing = true
                    isTextFocused = true
                }
                .font(.manrope(14, weight: .semibold))
                .foregroundStyle(.slate500)
            }
            .padding(.bottom, 12)

        case .blocked where !isEditing:
            PrimaryButton(title: "Edit my goal") {
                isEditing = true
                isTextFocused = true
            }
            .padding(.bottom, 12)

        case .failed:
            PrimaryButton(title: "Continue anyway") {
                onConfirm(text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .padding(.bottom, 12)

        default:
            EmptyView()
        }
    }

    private func check() async {
        isEditing = false
        state = .loading
        do {
            let result = try await AIService.checkGoal(goal: text, style: style, language: language)
            switch result {
            case .allowed(let reflection, let sampleLines):
                state = .allowed(reflection: reflection, sampleLines: sampleLines)
                Analytics.track("goal_check_allowed", ["style": style.rawValue])
            case .blocked(let reason):
                state = .blocked(reason: reason)
                Analytics.track("goal_check_blocked", ["style": style.rawValue])
            }
        } catch {
            print("[GoalCrafting] check failed: \(error)")
            state = .failed
            Analytics.track("goal_check_failed", ["style": style.rawValue])
        }
    }

    private func fetchSuggestions() async {
        isFetchingSuggestions = true
        do {
            suggestions = try await AIService.suggestPhrasing(goal: text, language: language)
        } catch {
            print("[GoalCrafting] suggestions failed: \(error)")
        }
        isFetchingSuggestions = false
    }
}

#Preview {
    GoalCraftingView(initialText: "Launch my ceramics studio", style: .present, language: "en") { _ in }
}
