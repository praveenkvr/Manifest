//
//  NineRitualView.swift
//  Manifest
//
//  The 369 method's write-it-out screen — shown for one goal, one window
//  (morning/afternoon/night) at a time, whichever the clock currently says.
//  Unlike RitualReadingView this isn't a timed cascade: writing by hand
//  takes real time, so it's a tap-to-count "I wrote it" per repetition,
//  same honor-system spirit as "read aloud" elsewhere in the app.
//

import SwiftUI
import SwiftData

struct NineRitualView: View {
    var goal: Goal
    var settings: AppSettings
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Goal> { $0.fulfilledAt == nil }) private var activeGoals: [Goal]
    @State private var session: NineSession?
    @State private var line: String?
    @State private var isLoading = true
    @State private var draft = ""
    @FocusState private var isDraftFocused: Bool

    private let window = NineWindow.current

    private var count: Int { session?.count(for: window) ?? 0 }
    private var isWindowComplete: Bool { count >= window.target }

    var body: some View {
        ZStack {
            LinearGradient.themeDarkBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 18)).foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Text("\(window.label(language: settings.language).uppercased()) \u{00B7} \(min(count, window.target))/\(window.target)")
                        .font(.manrope(12.5, weight: .semibold))
                        .foregroundStyle(.accent300)
                }
                .padding(.top, 8)

                Spacer().frame(height: 32)

                if isLoading {
                    ProgressView().tint(.white).frame(maxWidth: .infinity, alignment: .center)
                } else if isWindowComplete {
                    doneState
                } else {
                    writingState
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .task { await load() }
        .onAppear {
            if settings.ambientSoundEnabled {
                AmbientAudioPlayer.shared.start(goal.ambientSoundOption ?? settings.ambientSoundOption)
            }
        }
        .onDisappear { AmbientAudioPlayer.shared.stop() }
    }

    private var writingState: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("WRITE IT OUT").eyebrowStyle(.accent300)

            if let line {
                Text(line)
                    .font(.newsreader(28))
                    .foregroundStyle(.white)
                    .lineSpacing(4)
            }

            Text("Copy it by hand, then log each pass below.")
                .font(.manrope(14))
                .foregroundStyle(.white.opacity(0.6))

            TextField("", text: $draft, prompt: Text("Optional \u{2014} type it here too").foregroundStyle(.white.opacity(0.35)), axis: .vertical)
                .focused($isDraftFocused)
                .font(.newsreader(18))
                .foregroundStyle(.white)
                .padding(14)
                .frame(minHeight: 90, alignment: .topLeading)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 8) {
                ForEach(0..<window.target, id: \.self) { i in
                    Capsule()
                        .fill(i < count ? Color.accent300 : Color.white.opacity(0.15))
                        .frame(height: 6)
                }
            }

            Button {
                logRepetition()
            } label: {
                Text("I wrote it \u{2014} \(min(count + 1, window.target)) of \(window.target)")
                    .font(.manropeBold(17))
                    .foregroundStyle(.ink900)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var doneState: some View {
        VStack(alignment: .leading, spacing: 16) {
            LumenMascot(mood: .delighted, size: 40)
            Text("\(window.label(language: settings.language)) session done")
                .font(.newsreader(28))
                .foregroundStyle(.white)
            Text("You wrote it \(window.target) times. The next window picks up later today.")
                .font(.manrope(14))
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(3)

            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.manropeBold(17))
                    .foregroundStyle(.ink900)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func logRepetition() {
        guard let session else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            session.increment(window)
        }
        if isWindowComplete {
            Analytics.track("nine_session_completed", ["window": String(describing: window)])
        }
        draft = ""
        isDraftFocused = false
        let unpausedGoals = activeGoals.filter { !$0.isPaused }
        RitualLog.refreshTodayCompletion(activeGoals: unpausedGoals, in: modelContext)
        ShieldController.refresh(settings: settings, activeGoals: unpausedGoals, isRitualCompletedToday: RitualLog.today(in: modelContext).completed, in: modelContext)
    }

    private func load() async {
        let s = NineSession.today(goalID: goal.id, in: modelContext)
        session = s

        let startOfDay = Calendar.current.startOfDay(for: .now)
        let goalID = goal.id
        let language = settings.language
        let descriptor = FetchDescriptor<DailyScript>(
            predicate: #Predicate { $0.goalID == goalID && $0.date == startOfDay && $0.language == language }
        )
        if let cached = try? modelContext.fetch(descriptor).first, let first = cached.lines.first {
            line = first
            isLoading = false
            return
        }

        do {
            let fetched = try await AIService.dailyScript(
                goal: goal.text, style: goal.style, language: settings.language, dayNumber: goal.dayNumber
            )
            line = fetched.first
            modelContext.insert(DailyScript(goalID: goal.id, date: startOfDay, style: goal.style, language: settings.language, lines: fetched))
        } catch {
            print("[NineRitual] line fetch failed, using local fallback: \(error)")
            line = "I already have what it takes."
        }
        isLoading = false
    }
}

#Preview {
    NineRitualView(goal: Goal(text: "Launch my ceramics studio", category: .career, style: .threeSixNine), settings: AppSettings(), onDismiss: {})
}
