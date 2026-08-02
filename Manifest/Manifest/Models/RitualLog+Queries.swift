//
//  RitualLog+Queries.swift
//  Manifest
//
//  Small helpers over ModelContext — streak/progress math shared by Home,
//  Journey and the ritual flow.
//

import Foundation
import SwiftData

extension RitualLog {
    static func today(in context: ModelContext) -> RitualLog {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<RitualLog>(predicate: #Predicate { $0.date == startOfDay })
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let log = RitualLog(date: startOfDay)
        context.insert(log)
        return log
    }

    static func currentStreak(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<RitualLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let logs = try? context.fetch(descriptor) else { return 0 }

        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: .now)
        for log in logs {
            guard log.completed, Calendar.current.isDate(log.date, inSameDayAs: expectedDate) else { break }
            streak += 1
            expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
        }
        return streak
    }

    static func totalCompletedCount(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<RitualLog>(predicate: #Predicate { $0.completed })
        return (try? context.fetch(descriptor).count) ?? 0
    }

    /// Recomputes whether "today" counts as done across every active goal —
    /// present/water goals via the shared read-aloud session (RitualReadingView
    /// sets `completed` directly), 369 goals via their own 3 write sessions
    /// (NineSession) — and persists the combined result into today's row so
    /// the streak/consistency grid, which only ever reads `RitualLog.completed`,
    /// reflects 369-only days too instead of silently ignoring them.
    @discardableResult
    static func refreshTodayCompletion(activeGoals: [Goal], in context: ModelContext) -> Bool {
        let log = today(in: context)
        guard !log.completed, !log.skipped else { return log.completed }

        let readGoals = activeGoals.filter { $0.style != .threeSixNine }
        let nineGoals = activeGoals.filter { $0.style == .threeSixNine }
        guard !(readGoals.isEmpty && nineGoals.isEmpty) else { return log.completed }

        // Reaching here means log.completed is still false, so the only way
        // "reading" can count as done is if there was nothing to read — a
        // 369-only day. If there ARE read goals, this function can't
        // complete that half; RitualReadingView.completeRitual() does, directly.
        let readDone = readGoals.isEmpty
        let nineDone = nineGoals.allSatisfy { NineSession.today(goalID: $0.id, in: context).isFullyCompleteToday }

        if readDone && nineDone {
            log.completed = true
        }
        return log.completed
    }
}
