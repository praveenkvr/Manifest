//
//  SharedRitualStore.swift
//  Manifest
//
//  The main app's SwiftData store isn't reachable from app extensions —
//  they run in a separate process. This is the thin, App Group-backed
//  mirror that DeviceActivityMonitor (and, if needed later, the Shield
//  extensions) actually read from. The main app is the single writer;
//  extensions only ever read, except for isHandledToday/lastAppliedDay
//  which the monitor extension itself updates as it acts.
//
//  Needs "Target Membership" checked for DeviceActivityMonitor (and any
//  other extension that ends up needing it) in Xcode's File Inspector —
//  it lives in the main app's synced folder, so that's the one manual step.
//

import Foundation

enum SharedRitualStore {
    private static let suiteName = "group.com.akizillc.Manifest"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    private enum Key {
        static let selectionData = "sharedFamilyActivitySelectionData"
        static let windowStart = "sharedWindowStartMinutes"
        static let windowEnd = "sharedWindowEndMinutes"
        static let lockAllDay = "sharedLockAllDayUntilDone"
        static let activeWeekdays = "sharedActiveWeekdays"
        static let handledDayKey = "sharedHandledDayKey"
        static let streak = "sharedStreak"
        static let headline = "sharedHeadline"
        static let isSubscribed = "sharedIsSubscribed"
    }

    static var selectionData: Data? {
        get { defaults?.data(forKey: Key.selectionData) }
        set { defaults?.set(newValue, forKey: Key.selectionData) }
    }

    static var windowStartMinutes: Int {
        get { (defaults?.object(forKey: Key.windowStart) as? Int) ?? 6 * 60 + 30 }
        set { defaults?.set(newValue, forKey: Key.windowStart) }
    }

    static var windowEndMinutes: Int {
        get { (defaults?.object(forKey: Key.windowEnd) as? Int) ?? 9 * 60 }
        set { defaults?.set(newValue, forKey: Key.windowEnd) }
    }

    static var lockAllDayUntilDone: Bool {
        get { defaults?.bool(forKey: Key.lockAllDay) ?? false }
        set { defaults?.set(newValue, forKey: Key.lockAllDay) }
    }

    static var activeWeekdays: [Int] {
        get { (defaults?.array(forKey: Key.activeWeekdays) as? [Int]) ?? Array(1...7) }
        set { defaults?.set(newValue, forKey: Key.activeWeekdays) }
    }

    /// True once today has been either completed or grace-skipped — either
    /// way, the monitor extension shouldn't re-lock apps for the rest of
    /// today. Keyed by calendar day so a stale "true" never leaks into
    /// tomorrow without the main app having to remember to clear it.
    static var isHandledToday: Bool {
        defaults?.string(forKey: Key.handledDayKey) == dayKey(for: .now)
    }

    static func markHandledToday() {
        defaults?.set(dayKey(for: .now), forKey: Key.handledDayKey)
    }

    /// Widget-facing snapshot — read by ManifestWidget's timeline provider,
    /// written by the main app whenever streak/goal state changes.
    static var streak: Int {
        get { (defaults?.object(forKey: Key.streak) as? Int) ?? 0 }
        set { defaults?.set(newValue, forKey: Key.streak) }
    }

    static var headline: String? {
        get { defaults?.string(forKey: Key.headline) }
        set { defaults?.set(newValue, forKey: Key.headline) }
    }

    /// Defense-in-depth: the main app already stops DeviceActivity
    /// monitoring the moment a subscription lapses, but a previously
    /// scheduled interval could still fire in the gap before that runs —
    /// the extension checks this too before ever applying the shield.
    static var isSubscribed: Bool {
        get { defaults?.bool(forKey: Key.isSubscribed) ?? false }
        set { defaults?.set(newValue, forKey: Key.isSubscribed) }
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}
