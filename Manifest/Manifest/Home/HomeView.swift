//
//  HomeView.swift
//  Manifest
//
//  Screen 11/19 — images/screens/11-home-locked.png
//

import SwiftUI
import SwiftData
import FamilyControls

struct HomeView: View {
    var settings: AppSettings

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Goal> { $0.fulfilledAt == nil }, sort: \Goal.createdAt)
    private var activeGoals: [Goal]
    @Query(sort: \DailyScript.date, order: .reverse) private var scripts: [DailyScript]
    @Query(sort: \RitualLog.date, order: .reverse) private var logs: [RitualLog]

    @State private var streak = 0
    @State private var isCompletedToday = false
    @State private var isRitualPresented = false
    @State private var showAddGoal = false
    @State private var showPaywall = false

    private var isSubscribed: Bool { EntitlementStore.shared.isSubscribed }
    private var unpausedGoals: [Goal] { activeGoals.filter { !$0.isPaused } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    heroCard

                    if let todayLine, isCompletedToday {
                        todayLineCard(todayLine)
                    }

                    if activeGoals.isEmpty {
                        emptyGoalsState
                    } else {
                        HStack {
                            Text("ACTIVE MANIFESTATIONS").eyebrowStyle(.textSecondary)
                            Spacer()
                            addGoalControl
                        }

                        VStack(spacing: 12) {
                            ForEach(activeGoals) { goal in
                                NavigationLink {
                                    GoalDetailView(goal: goal, settings: settings)
                                } label: {
                                    GoalRow(goal: goal, isLocked: goal.isPaused || !isSubscribed)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        weekStrip
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 68)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar(.hidden)
        }
        .task { refreshState() }
        .onChange(of: isRitualPresented) { _, presented in
            if !presented { refreshState() }
        }
        // `.task` only fires once per view lifetime, not on every return to
        // the app — without this, a shield applied (or not) at launch just
        // sits stale if the user backgrounds Manifest and comes back later,
        // e.g. after the ritual window has since opened.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                EntitlementStore.shared.refresh()
                Task {
                    await AnalyticsGate.shared.refresh()
                    Analytics.applyGate()
                }
                refreshState()
            }
        }
        .fullScreenCover(isPresented: $isRitualPresented) {
            // 369 goals aren't read aloud here — they have their own write
            // flow from Goal Detail — so they're excluded from this list.
            // Paused goals are excluded too — nothing to read for them today.
            RitualFlowView(settings: settings, goals: unpausedGoals.filter { $0.style != .threeSixNine })
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet(settings: settings)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(settings: settings, source: "home") { showPaywall = false }
        }
        // .task(id:) rather than .onChange — needs to fire on a cold launch
        // where the flag is already true by the time HomeView first
        // appears, not just on a later change while already visible.
        .task(id: NotificationRouter.shared.pendingRitual) {
            guard NotificationRouter.shared.pendingRitual, !isCompletedToday else { return }
            NotificationRouter.shared.pendingRitual = false
            if isSubscribed { isRitualPresented = true } else { showPaywall = true }
        }
    }

    /// Swaps between "add a manifestation" and "subscribe to unlock" so the
    /// button's purpose is clear before tapping, not just intercepted silently.
    @ViewBuilder
    private var addGoalControl: some View {
        if isSubscribed {
            Button { showAddGoal = true } label: {
                Image(systemName: "plus").foregroundStyle(.accent500)
            }
        } else {
            Button { showPaywall = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles").font(.system(size: 11))
                    Text("Subscribe").font(.manrope(12.5, weight: .semibold))
                }
                .foregroundStyle(.ink900)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gold300)
                .clipShape(Capsule())
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeString).font(.manrope(14)).foregroundStyle(.textSecondary)
                Text(greeting).font(.newsreader(27)).foregroundStyle(.textPrimary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "sparkle").font(.system(size: 12)).foregroundStyle(.gold600)
                Text("\(streak)").font(.manropeBold(15)).foregroundStyle(.gold600)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.gold50)
            .clipShape(Capsule())
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill").font(.system(size: 11))
                    Text("\(lockedCount) APPS LOCKED")
                }
                .font(.manropeEyebrow(11))
                .foregroundStyle(.gold300)
                Spacer()
                LumenMascot(mood: isCompletedToday ? .delighted : .calm, size: 34)
                    .breathingGlow()
            }

            Text(isCompletedToday
                 ? "Ritual complete. Your day is yours."
                 : "Your ritual is waiting. Two minutes, then the day is yours.")
                .font(.newsreader(25))
                .foregroundStyle(.white)
                .lineSpacing(2)

            if !isCompletedToday {
                Button {
                    if isSubscribed { isRitualPresented = true } else { showPaywall = true }
                } label: {
                    Text(isSubscribed ? "Begin today's ritual" : "Subscribe to start your ritual")
                        .font(.manropeBold(16))
                        .foregroundStyle(.ink900)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                if isSubscribed {
                    Text(settings.lockAllDayUntilDone
                         ? "Locked until you finish \u{00B7} \(settings.graceSkipsPerWeek - settings.graceSkipsUsedThisWeek) grace skips left"
                         : "Window closes at \(formatMinutesAsTime(settings.windowEndMinutes, language: settings.language)) \u{00B7} \(settings.graceSkipsPerWeek - settings.graceSkipsUsedThisWeek) grace skips left")
                        .font(.manrope(12.5))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding(20)
        .background(LinearGradient.lockedRitualCard)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color(hex: 0x0C6753).opacity(0.28), radius: 20, y: 10)
    }

    /// A quiet re-read of what they spoke this morning — the app's actual
    /// "magic moment," surfaced here instead of buried in Goal Detail.
    private func todayLineCard(_ line: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            LumenMascot(mood: .delighted, size: 26)
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY'S LINE").eyebrowStyle(.lavender500)
                Text("\u{201C}\(line)\u{201D}")
                    .font(.newsreaderItalic(17))
                    .foregroundStyle(.ink900)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lavender50)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var emptyGoalsState: some View {
        VStack(spacing: 14) {
            LumenMascot(mood: .calm, size: 44)
            Text("What are you manifesting?")
                .font(.newsreader(22))
                .foregroundStyle(.textPrimary)
            Text("Add a goal and Lumen will write your first line.")
                .font(.manrope(14))
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                if isSubscribed { showAddGoal = true } else { showPaywall = true }
            } label: {
                Text(isSubscribed ? "Add a manifestation" : "Subscribe to start manifesting")
                    .font(.manropeBold(15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color.accent500)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    /// A glanceable "this week" strip — small, decorative, but turns an empty
    /// stretch of scroll into a quiet nudge toward the streak (full detail
    /// lives on the Journey tab).
    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let completedDates = Set(logs.filter(\.completed).map { calendar.startOfDay(for: $0.date) })
        let days = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }

        return VStack(alignment: .leading, spacing: 10) {
            Text("THIS WEEK").eyebrowStyle(.textSecondary)
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    let isDone = completedDates.contains(day)
                    let isToday = calendar.isDate(day, inSameDayAs: today)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isDone ? Color.accent500 : Color.slate300.opacity(0.2))
                        .frame(height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isToday ? Color.gold500 : Color.clear, lineWidth: 2)
                        )
                }
            }
        }
        .padding(.top, 4)
    }

    private var todayLine: String? {
        guard let goalID = activeGoals.first?.id else { return nil }
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return scripts.first { $0.goalID == goalID && $0.date == startOfDay && $0.language == settings.language }?.lines.first
    }

    private var lockedCount: Int {
        guard let data = settings.familyActivitySelectionData,
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return 0
        }
        return selection.applicationTokens.count + selection.categoryTokens.count
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.language)
        formatter.setLocalizedDateFormatFromTemplate("EEEE, jmm")
        return formatter.string(from: .now)
    }

    // String(localized:locale:) proved unreliable for hand-authored catalog
    // entries — some resolve, some silently fall back to English with no
    // error (see SettingsView's notSubscribedText for the same issue). A
    // hardcoded table sidesteps it entirely.
    private var greeting: String {
        let morning = ["en": "Good morning", "es": "Buenos días", "fr": "Bonjour", "de": "Guten Morgen", "pt": "Bom dia", "it": "Buongiorno", "ja": "おはようございます", "ko": "좋은 아침이에요", "zh": "早上好", "hi": "सुप्रभात", "ar": "صباح الخير", "ru": "Доброе утро"]
        let afternoon = ["en": "Good afternoon", "es": "Buenas tardes", "fr": "Bon après-midi", "de": "Guten Nachmittag", "pt": "Boa tarde", "it": "Buon pomeriggio", "ja": "こんにちは", "ko": "좋은 오후예요", "zh": "下午好", "hi": "नमस्कार", "ar": "مساء الخير", "ru": "Добрый день"]
        let evening = ["en": "Good evening", "es": "Buenas noches", "fr": "Bonsoir", "de": "Guten Abend", "pt": "Boa noite", "it": "Buonasera", "ja": "こんばんは", "ko": "좋은 저녁이에요", "zh": "晚上好", "hi": "शुभ संध्या", "ar": "مساء الخير", "ru": "Добрый вечер"]
        let table: [String: String]
        switch Calendar.current.component(.hour, from: .now) {
        case 0..<12: table = morning
        case 12..<17: table = afternoon
        default: table = evening
        }
        return table[settings.language] ?? table["en"]!
    }

    private func refreshState() {
        streak = RitualLog.currentStreak(in: modelContext)
        isCompletedToday = RitualLog.refreshTodayCompletion(activeGoals: unpausedGoals, in: modelContext)
        ShieldController.refresh(settings: settings, activeGoals: unpausedGoals, isRitualCompletedToday: isCompletedToday, in: modelContext)
        // No subscription, no reminders — nothing to remind them of, since
        // nothing is actionable without one.
        NotificationScheduler.reschedule(settings: settings, activeGoals: isSubscribed ? unpausedGoals : [])
    }
}

struct GoalRow: View {
    var goal: Goal
    /// True when paused (by choice, or because there's no active
    /// subscription) — dims the row and swaps the day chip for a status one,
    /// but never hides it: paused goals stay visible, just not actionable.
    var isLocked: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(goal.text)
                    .font(.manropeBold(16))
                    .foregroundStyle(.textPrimary)
                    .lineLimit(2)
                Spacer()
                if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "pause.fill").font(.system(size: 10))
                        Text("Paused")
                    }
                    .font(.manrope(13, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.slate300.opacity(0.2))
                    .clipShape(Capsule())
                } else {
                    Text("Day \(goal.dayNumber)")
                        .font(.manrope(13, weight: .semibold))
                        .foregroundStyle(.accent600)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.accent50)
                        .clipShape(Capsule())
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.slate300.opacity(0.25)).frame(height: 6)
                    Capsule().fill(LinearGradient.progressBar)
                        .frame(width: geo.size.width * min(1, Double(goal.dayNumber) / 30), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.ink900.opacity(0.05), radius: 4, y: 2)
        .opacity(isLocked ? 0.6 : 1)
    }
}

#Preview {
    HomeView(settings: AppSettings())
        .modelContainer(for: [Goal.self, RitualLog.self, DailyScript.self], inMemory: true)
}
