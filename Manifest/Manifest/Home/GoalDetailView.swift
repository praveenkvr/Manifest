//
//  GoalDetailView.swift
//  Manifest
//
//  Screen 12/19 — images/screens/12-goal-detail.png
//

import SwiftUI
import SwiftData
import PhotosUI

struct GoalDetailView: View {
    @Bindable var goal: Goal
    var settings: AppSettings

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var scripts: [DailyScript]
    @FocusState private var isNotesFocused: Bool
    @State private var photoItems: [PhotosPickerItem?] = [nil, nil, nil]
    @State private var showScratchOff = false
    @State private var showEditSheet = false
    @State private var showNineRitual = false
    @State private var showPaywall = false
    @State private var showSoundPicker = false
    @State private var previewingSound: AmbientSoundOption?
    @State private var nineSession: NineSession?

    private var isSubscribed: Bool { EntitlementStore.shared.isSubscribed }

    private var todayLine: String? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return scripts.first { $0.goalID == goal.id && $0.date == startOfDay && $0.language == settings.language }?.lines.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(goal.text)
                    .font(.newsreader(33))
                    .foregroundStyle(.textPrimary)
                    .lineSpacing(2)

                HStack(spacing: 8) {
                    chip(goal.displayCategory(language: settings.language), background: .accent50, foreground: .accent600)
                    chip("Day \(goal.dayNumber)", background: .appSurface, foreground: .textSecondary)
                    chip(goal.style.displayName(language: settings.language), background: .appSurface, foreground: .textSecondary)
                    pauseChip
                }

                soundRow

                if goal.style == .threeSixNine {
                    nineSection
                }

                Text("VISION BOARD").eyebrowStyle(.textSecondary)

                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        visionSlot(index: index)
                    }
                }

                Text("NOTES").eyebrowStyle(.textSecondary)
                TextEditor(text: $goal.notes)
                    .focused($isNotesFocused)
                    .font(.manrope(14.5))
                    .foregroundStyle(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .frame(height: 100)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isNotesFocused ? Color.accent300 : Color.clear, lineWidth: 2)
                    )

                if let todayLine {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TODAY'S LINE").eyebrowStyle(.lavender500)
                            HStack(alignment: .top, spacing: 8) {
                                LumenMascot(mood: .calm, size: 26)
                                Text("\u{201C}\(todayLine)\u{201D}")
                                    .font(.newsreaderItalic(18))
                                    .foregroundStyle(.textPrimary)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.lavender50)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                Spacer().frame(height: 8)

                HStack(spacing: 12) {
                    Button {
                        isNotesFocused = true
                    } label: {
                        Text("Add note")
                            .font(.manropeBold(15))
                            .foregroundStyle(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        goal.fulfilledAt = .now
                        Analytics.track("goal_fulfilled", ["style": goal.style.rawValue])
                        showScratchOff = true
                    } label: {
                        Text("Mark fulfilled")
                            .font(.manropeBold(15))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.accent500)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .contentShape(Rectangle())
            .onTapGesture { isNotesFocused = false }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditSheet = true }
                    .font(.manrope(15, weight: .semibold))
                    .foregroundStyle(.accent500)
            }
        }
        .fullScreenCover(isPresented: $showScratchOff) {
            ScratchOffView(goal: goal)
        }
        .fullScreenCover(isPresented: $showNineRitual, onDismiss: refreshNineSession) {
            NineRitualView(goal: goal, settings: settings) { showNineRitual = false }
        }
        .sheet(isPresented: $showEditSheet) {
            EditGoalSheet(goal: goal, language: settings.language) {
                Analytics.track("goal_deleted", ["source": "goalDetail"])
                modelContext.delete(goal)
                dismiss()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(settings: settings, source: "goalDetail") { showPaywall = false }
        }
        .sheet(isPresented: $showSoundPicker) {
            soundSheet
        }
        .onAppear { refreshNineSession() }
    }

    private var soundRow: some View {
        Button {
            showSoundPicker = true
        } label: {
            HStack {
                Text("Ambient sound").font(.manropeBold(15)).foregroundStyle(.textPrimary)
                Spacer()
                Text(soundValueText).font(.manrope(14)).foregroundStyle(.textSecondary)
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(.slate300)
            }
        }
        .buttonStyle(.plain)
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var soundValueText: String {
        guard let option = goal.ambientSoundOption else {
            let locale = Locale(identifier: settings.language)
            return String(localized: "Default", locale: locale)
        }
        return option.displayName(language: settings.language)
    }

    private var soundSheet: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Ambient sound").font(.newsreader(25)).foregroundStyle(.textPrimary)
                Text("Overrides the global Settings choice for this manifestation only.")
                    .font(.manrope(13.5))
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                soundOptionRow(title: soundDefaultLabel, isSelected: goal.ambientSoundOption == nil, preview: nil) {
                    goal.ambientSoundOption = nil
                    Analytics.track("goal_ambient_sound_changed", ["option": "default"])
                    showSoundPicker = false
                }
                ForEach(AmbientSoundOption.allCases) { option in
                    soundOptionRow(
                        title: option.displayName(language: settings.language),
                        isSelected: goal.ambientSoundOption == option,
                        preview: option == .random ? nil : option
                    ) {
                        goal.ambientSoundOption = option
                        Analytics.track("goal_ambient_sound_changed", ["option": option.rawValue])
                        showSoundPicker = false
                    }
                }

                Text("Music by Kevin MacLeod (incompetech.com), licensed under Creative Commons: By Attribution 3.0")
                    .font(.manrope(11))
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .onDisappear { AmbientAudioPlayer.shared.stop(); previewingSound = nil }
    }

    private var soundDefaultLabel: String {
        let locale = Locale(identifier: settings.language)
        let defaultName = settings.ambientSoundOption.displayName(language: settings.language)
        return String(localized: "Use Settings default", locale: locale) + " (\(defaultName))"
    }

    private func soundOptionRow(title: String, isSelected: Bool, preview: AmbientSoundOption?, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Button(action: action) {
                HStack {
                    Text(title).font(.manropeBold(15.5)).foregroundStyle(.textPrimary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark").foregroundStyle(.accent500)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let preview {
                AmbientSoundPreviewButton(option: preview, previewing: $previewingSound)
            }
        }
        .padding(16)
        .manifestCard(adaptive: true)
    }

    private var pauseChip: some View {
        Button {
            goal.isPaused.toggle()
            Analytics.track(goal.isPaused ? "goal_paused" : "goal_resumed")
        } label: {
            HStack(spacing: 4) {
                Image(systemName: goal.isPaused ? "play.fill" : "pause.fill").font(.system(size: 10))
                Text(goal.isPaused ? "Paused" : "Pause")
            }
            .font(.manrope(13, weight: .semibold))
            .foregroundStyle(goal.isPaused ? .white : .textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(goal.isPaused ? Color.slate400 : Color.appSurface)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func refreshNineSession() {
        guard goal.style == .threeSixNine else { return }
        nineSession = NineSession.today(goalID: goal.id, in: modelContext)
    }

    private var nineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S 369 PRACTICE").eyebrowStyle(.textSecondary)
            HStack(spacing: 10) {
                ForEach(NineWindow.allCases, id: \.self) { window in
                    let done = nineSession?.count(for: window) ?? 0
                    VStack(spacing: 6) {
                        Text(window.label(language: settings.language)).font(.manrope(12, weight: .semibold)).foregroundStyle(.textSecondary)
                        Text("\(min(done, window.target))/\(window.target)")
                            .font(.manropeBold(15.5))
                            .foregroundStyle(done >= window.target ? .accent600 : .textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(window == NineWindow.current ? Color.accent50 : Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            Button {
                if !isSubscribed { showPaywall = true }
                else if !goal.isPaused { showNineRitual = true }
            } label: {
                Text(nineButtonTitle)
                    .font(.manropeBold(15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(nineButtonEnabled ? Color.accent500 : Color.slate300)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!nineButtonEnabled && isSubscribed)
        }
    }

    private var nineButtonEnabled: Bool {
        isSubscribed && !goal.isPaused && nineSession?.isFullyCompleteToday != true
    }

    private var nineButtonTitle: String {
        if !isSubscribed { return "Subscribe to write today's lines" }
        if goal.isPaused { return "Paused \u{2014} resume to write" }
        if nineSession?.isFullyCompleteToday == true { return "All 3 sessions done today" }
        return "Write now \u{2014} \(NineWindow.current.label(language: settings.language))"
    }

    private func chip(_ text: String, background: Color, foreground: Color) -> some View {
        Text(LocalizedStringKey(text))
            .font(.manrope(13, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(background)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func visionSlot(index: Int) -> some View {
        if goal.imageData.indices.contains(index), let uiImage = UIImage(data: goal.imageData[index]) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            PhotosPicker(selection: Binding(
                get: { photoItems[index] },
                set: { newValue in
                    photoItems[index] = newValue
                    Task { await loadImage(newValue, into: index) }
                }
            ), matching: .images) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.slate300.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .frame(width: 100, height: 100)
                    .overlay(Image(systemName: "photo").foregroundStyle(.slate400))
            }
        }
    }

    private func loadImage(_ item: PhotosPickerItem?, into index: Int) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        while goal.imageData.count <= index { goal.imageData.append(Data()) }
        goal.imageData[index] = data
    }
}

#Preview {
    NavigationStack {
        GoalDetailView(goal: Goal(text: "Launch my ceramics studio", category: .career), settings: AppSettings())
    }
}
