//
//  NotificationScheduler.swift
//  Manifest
//
//  Local notifications only — no push, no server involvement. Two kinds:
//  one daily nudge at the ritual window's start for present/water goals,
//  and three daily nudges (morning/afternoon/night) for 369 goals, matching
//  NineWindow's own hour boundaries. Rescheduling always clears and
//  re-adds everything rather than diffing — cheap for a handful of local
//  requests, and it means stale reminders can never linger after a goal or
//  settings change.
//

import Foundation
import UserNotifications

enum NotificationScheduler {
    /// Also read by NotificationRouter to recognize which tapped notification
    /// should deep-link into the ritual.
    static let ritualID = "ritual-morning"
    private static let nineIDs = ["nine-morning", "nine-afternoon", "nine-night"]

    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("[NotificationScheduler] authorization request failed: \(error)")
            return false
        }
    }

    static func reschedule(settings: AppSettings, activeGoals: [Goal]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [ritualID] + nineIDs)

        // Notification content is built here, not read from a SwiftUI Text —
        // String(localized:) has no environment locale to inherit, so the
        // language has to be passed in explicitly to match Settings > Language.
        let locale = Locale(identifier: settings.language)

        center.getNotificationSettings { authStatus in
            guard authStatus.authorizationStatus == .authorized else { return }

            if activeGoals.contains(where: { $0.style != .threeSixNine }) {
                schedule(
                    id: ritualID,
                    title: String(localized: "Your ritual is waiting", locale: locale),
                    body: String(localized: "Two minutes, then the day is yours.", locale: locale),
                    minutesSinceMidnight: settings.windowStartMinutes
                )
            }

            if activeGoals.contains(where: { $0.style == .threeSixNine }) {
                schedule(id: nineIDs[0], title: String(localized: "Write it \u{00D7}3", locale: locale), body: String(localized: "Your 369 morning session is ready.", locale: locale), minutesSinceMidnight: 8 * 60)
                schedule(id: nineIDs[1], title: String(localized: "Write it \u{00D7}6", locale: locale), body: String(localized: "Your 369 afternoon session is ready.", locale: locale), minutesSinceMidnight: 14 * 60)
                schedule(id: nineIDs[2], title: String(localized: "Write it \u{00D7}9", locale: locale), body: String(localized: "Your 369 night session is ready.", locale: locale), minutesSinceMidnight: 20 * 60)
            }
        }
    }

    private static func schedule(id: String, title: String, body: String, minutesSinceMidnight: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = minutesSinceMidnight / 60
        components.minute = minutesSinceMidnight % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationScheduler] failed to schedule \(id): \(error)")
            }
        }
    }
}
