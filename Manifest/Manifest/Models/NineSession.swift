//
//  NineSession.swift
//  Manifest
//
//  Tracks the 369 method's three write-it-out sessions (morning/afternoon/
//  night) for one goal, one calendar day — separate from RitualLog, since
//  369 goals aren't read aloud in the shared morning ritual and complete on
//  their own per-goal, per-session schedule instead of once a day.
//

import Foundation
import SwiftData

@Model
final class NineSession {
    var goalID: UUID
    var date: Date
    var morningCount: Int
    var afternoonCount: Int
    var nightCount: Int

    init(
        goalID: UUID,
        date: Date,
        morningCount: Int = 0,
        afternoonCount: Int = 0,
        nightCount: Int = 0
    ) {
        self.goalID = goalID
        self.date = date
        self.morningCount = morningCount
        self.afternoonCount = afternoonCount
        self.nightCount = nightCount
    }
}

enum NineWindow: CaseIterable {
    case morning, afternoon, night

    var target: Int {
        switch self {
        case .morning: 3
        case .afternoon: 6
        case .night: 9
        }
    }

    // See ManifestationStyle.displayName(language:) — String(localized:)
    // outside a SwiftUI view doesn't see .environment(\.locale), so the
    // locale has to be passed in explicitly to follow Settings > Language.
    func label(language: String) -> String {
        let locale = Locale(identifier: language)
        switch self {
        case .morning: return String(localized: "Morning", locale: locale)
        case .afternoon: return String(localized: "Afternoon", locale: locale)
        case .night: return String(localized: "Night", locale: locale)
        }
    }

    /// Which window the clock is in right now — before noon, noon–6pm, after 6pm.
    static var current: NineWindow {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12: return .morning
        case 12..<18: return .afternoon
        default: return .night
        }
    }
}

extension NineSession {
    static func today(goalID: UUID, in context: ModelContext) -> NineSession {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<NineSession>(
            predicate: #Predicate { $0.goalID == goalID && $0.date == startOfDay }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let session = NineSession(goalID: goalID, date: startOfDay)
        context.insert(session)
        return session
    }

    func count(for window: NineWindow) -> Int {
        switch window {
        case .morning: morningCount
        case .afternoon: afternoonCount
        case .night: nightCount
        }
    }

    func increment(_ window: NineWindow) {
        switch window {
        case .morning: morningCount = min(morningCount + 1, window.target)
        case .afternoon: afternoonCount = min(afternoonCount + 1, window.target)
        case .night: nightCount = min(nightCount + 1, window.target)
        }
    }

    func isComplete(_ window: NineWindow) -> Bool {
        count(for: window) >= window.target
    }

    var isFullyCompleteToday: Bool {
        NineWindow.allCases.allSatisfy { isComplete($0) }
    }
}
