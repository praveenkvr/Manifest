//
//  RitualReadingView.swift
//  Manifest
//
//  Screen 13/19 — images/screens/13-ritual-reading.png (reworked)
//
//  One page per active manifestation. Lines for the current manifestation
//  fade in on their own, one after another, while the user reads along —
//  no per-line tapping. "Next" moves to the next manifestation; on the last
//  one it finishes the ritual. Scripts are fetched once (via AIService — on
//  the Worker today) and cached in DailyScript, per manifestation per day.
//

import SwiftUI
import SwiftData

struct RitualReadingView: View {
    var settings: AppSettings
    var goals: [Goal]
    var onComplete: () -> Void
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var goalIndex = 0
    @State private var lines: [String] = []
    @State private var revealedCount = 0
    @State private var isLoading = true
    @State private var showGraceSkip = false
    @State private var revealTask: Task<Void, Never>?

    private var currentGoal: Goal? {
        goals.indices.contains(goalIndex) ? goals[goalIndex] : nil
    }
    private var goalCount: Int { max(goals.count, 1) }
    private var isLastGoal: Bool { goalIndex >= goals.count - 1 }
    private var overallProgress: Double {
        let lineFraction = lines.isEmpty ? 0 : Double(revealedCount) / Double(lines.count)
        return (Double(goalIndex) + lineFraction) / Double(goalCount)
    }
    /// The button only makes sense once there's nothing left to read — before
    /// that, tapping it would skip past lines the timer hasn't shown yet.
    private var canFinish: Bool { !lines.isEmpty && revealedCount >= lines.count }

    var body: some View {
        ZStack {
            LinearGradient.themeDarkBackground.ignoresSafeArea()

            // Soft accent glow behind the mascot moment — the screen's one
            // deliberate spot of color against the otherwise deep, dark
            // background, instead of everything sitting at the same flat depth.
            Circle()
                .fill(RadialGradient(colors: [.accent500.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 160))
                .frame(width: 320, height: 320)
                .offset(y: -160)
                .allowsHitTesting(false)

            VStack {
                Spacer()
                WaveBackground().frame(height: 210)
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button { showGraceSkip = true } label: {
                        Image(systemName: "xmark").font(.system(size: 18)).foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        if goals.count > 1 {
                            Text("Manifestation \(goalIndex + 1) of \(goals.count)")
                                .font(.manrope(12.5))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        ProgressRing(progress: overallProgress, size: 28)
                    }
                }
                .padding(.top, 8)

                Spacer(minLength: 12)

                HStack {
                    Spacer()
                    LumenMascot(mood: .resting, size: 46).breathingGlow()
                    Spacer()
                }

                Spacer(minLength: 20)

                // The ScrollView/text stack stays mounted at all times —
                // only its opacity toggles for loading — so the very first
                // revealed line fades into an already-settled layout instead
                // of appearing the instant the container itself is inserted,
                // which read as the text "moving for a second till it settles".
                ZStack {
                    if isLoading {
                        ProgressView().tint(.white).frame(maxWidth: .infinity, alignment: .center)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("READ ALOUD").eyebrowStyle(.accent300)

                        Spacer().frame(height: 12)

                        // No `maxHeight: .infinity` here on purpose — six
                        // short lines fit on screen without scrolling in
                        // practice, so the block sizes to its own content and
                        // the flexible spacers above/below it share the
                        // remaining space, instead of the text pinning itself
                        // to the top and leaving one big empty gap below.
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 22) {
                                ForEach(Array(lines.prefix(revealedCount).enumerated()), id: \.offset) { index, line in
                                    Text(line)
                                        .font(.newsreader(25))
                                        .foregroundStyle(.white.opacity(index == revealedCount - 1 ? 1 : 0.5))
                                        .lineSpacing(3)
                                        .shadow(color: index == revealedCount - 1 ? .accent300.opacity(0.5) : .clear, radius: 14)
                                        .transition(.opacity)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.bottom, 8)
                        }
                    }
                    .opacity(isLoading ? 0 : 1)
                }

                Spacer(minLength: 20)

                Button {
                    advance()
                } label: {
                    Text(isLastGoal ? "Finish" : "Next manifestation")
                        .font(.manropeBold(17))
                        .foregroundStyle(.ink900)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isLoading || !canFinish)
                .opacity(canFinish ? 1 : 0.5)

                Spacer().frame(height: 12)

                HStack(spacing: 8) {
                    Image(systemName: "waveform").font(.system(size: 13)).foregroundStyle(.white.opacity(0.5))
                    Text("Speak it out loud \u{2014} it works better that way")
                        .font(.manrope(13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
        .task {
            Analytics.track("ritual_started", ["goal_count": goals.count])
            await loadCurrentGoal()
        }
        .onChange(of: goalIndex) { _, _ in
            Task { await loadCurrentGoal() }
        }
        .sheet(isPresented: $showGraceSkip) {
            GraceSkipSheet(
                settings: settings,
                onUseGraceSkip: { useGraceSkip() },
                onReadNow: { showGraceSkip = false }
            )
        }
        .onAppear {
            // A session can cover several goals — the first goal's override
            // (if any) sets the sound for the whole session rather than
            // switching mid-ritual as pages advance.
            if settings.ambientSoundEnabled {
                AmbientAudioPlayer.shared.start(goals.first?.ambientSoundOption ?? settings.ambientSoundOption)
            }
        }
        .onDisappear { AmbientAudioPlayer.shared.stop() }
    }

    private func advance() {
        if isLastGoal {
            completeRitual()
        } else {
            goalIndex += 1
        }
    }

    private func loadCurrentGoal() async {
        revealTask?.cancel()
        isLoading = true
        revealedCount = 0
        lines = []

        guard let goal = currentGoal else {
            lines = Self.fallbackLines
            isLoading = false
            startRevealTimer()
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: .now)
        let goalID = goal.id
        let language = settings.language
        // Language is part of the cache key — otherwise switching languages
        // mid-day kept serving whatever language today's script was first
        // generated in, since only goal+date were checked.
        let descriptor = FetchDescriptor<DailyScript>(
            predicate: #Predicate { $0.goalID == goalID && $0.date == startOfDay && $0.language == language }
        )
        if let cached = try? modelContext.fetch(descriptor).first {
            lines = cached.lines
            isLoading = false
            startRevealTimer()
            return
        }

        do {
            let fetched = try await AIService.dailyScript(
                goal: goal.text, style: goal.style, language: settings.language, dayNumber: goal.dayNumber
            )
            lines = fetched
            modelContext.insert(DailyScript(goalID: goal.id, date: startOfDay, style: goal.style, language: settings.language, lines: fetched))
        } catch {
            print("[Ritual] daily-script fetch failed, using local fallback: \(error)")
            lines = Self.fallbackLines
        }
        isLoading = false
        startRevealTimer()
    }

    /// Lines cascade in on their own — first one shortly after load, then
    /// every ~4s, giving enough time to actually speak each line before the
    /// next one appears.
    private func startRevealTimer() {
        revealTask?.cancel()
        let total = lines.count
        revealTask = Task {
            for index in 0..<total {
                let delay = index == 0 ? 600_000_000 : 4_000_000_000
                try? await Task.sleep(nanoseconds: UInt64(delay))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.9)) { revealedCount = index + 1 }
                }
            }
        }
    }

    private static let fallbackLines = [
        "I am exactly where I need to be.",
        "My effort today already matters.",
        "I trust the process I'm building.",
    ]

    private func completeRitual() {
        revealTask?.cancel()
        let log = RitualLog.today(in: modelContext)
        log.completed = true
        log.linesRead = lines.count
        log.totalLines = lines.count
        ShieldController.lift()
        SharedRitualStore.markHandledToday()
        Analytics.track("ritual_completed", ["goal_count": goals.count])
        onComplete()
    }

    private func useGraceSkip() {
        showGraceSkip = false
        revealTask?.cancel()
        settings.graceSkipsUsedThisWeek += 1
        let log = RitualLog.today(in: modelContext)
        log.skipped = true
        log.graceSkipUsed = true
        ShieldController.lift()
        SharedRitualStore.markHandledToday()
        Analytics.track("ritual_grace_skip_used")
        onDismiss()
    }
}

#Preview {
    RitualReadingView(settings: AppSettings(), goals: [], onComplete: {}, onDismiss: {})
}
