//
//  ShieldController+AppSettings.swift
//  Manifest
//
//  AppSettings is a SwiftData @Model — only usable in the main app process,
//  not the DeviceActivityMonitor extension (separate process, no SwiftData).
//  Kept out of ShieldController.swift itself so that file stays extension-safe.
//

import Foundation
import SwiftData
import DeviceActivity
import WidgetKit

extension ShieldController {
    /// Call on foreground/appear — the one place that decides whether the
    /// shield should currently be up, based on today's RitualLog and the window.
    static func refresh(settings: AppSettings, activeGoals: [Goal], isRitualCompletedToday: Bool, in context: ModelContext) {
        // No subscription, no blocking — the shield (and the daily-script
        // AI calls that would otherwise feed it) is entirely a paid feature.
        guard EntitlementStore.shared.isSubscribed else {
            lift()
            RitualActivityScheduler.stop()
            SharedRitualStore.isSubscribed = false
            WidgetCenter.shared.reloadTimelines(ofKind: "ManifestWidget")
            return
        }

        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let minutesNow = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        let isActiveDay = settings.activeWeekdays.contains(weekday)
        // Default: only block during the ritual window itself. With
        // lockAllDayUntilDone on, blocking starts at the window's open time
        // and holds for the rest of the day (not just until it closes) —
        // matches "keeps your distractions locked until it's done" literally,
        // for users who want a harder commitment than a morning-only nudge.
        let isWithinWindow = settings.lockAllDayUntilDone
            ? minutesNow >= settings.windowStartMinutes
            : minutesNow >= settings.windowStartMinutes && minutesNow < settings.windowEndMinutes

        if isActiveDay && isWithinWindow && !isRitualCompletedToday {
            apply(selectionData: settings.familyActivitySelectionData)
        } else {
            lift()
        }

        syncSharedStore(settings: settings, activeGoals: activeGoals, isRitualCompletedToday: isRitualCompletedToday, in: context)
        RitualActivityScheduler.reschedule(settings: settings)
    }

    /// Mirrors the state the DeviceActivityMonitor extension and ManifestWidget
    /// need into the App Group — neither can reach SwiftData directly, so this
    /// is the only way they learn which apps to shield, today's streak/headline,
    /// and whether today's already handled.
    private static func syncSharedStore(settings: AppSettings, activeGoals: [Goal], isRitualCompletedToday: Bool, in context: ModelContext) {
        SharedRitualStore.selectionData = settings.familyActivitySelectionData
        SharedRitualStore.windowStartMinutes = settings.windowStartMinutes
        SharedRitualStore.windowEndMinutes = settings.windowEndMinutes
        SharedRitualStore.lockAllDayUntilDone = settings.lockAllDayUntilDone
        SharedRitualStore.activeWeekdays = settings.activeWeekdays
        if isRitualCompletedToday {
            SharedRitualStore.markHandledToday()
        }

        SharedRitualStore.streak = RitualLog.currentStreak(in: context)
        SharedRitualStore.headline = activeGoals.first?.text
        SharedRitualStore.isSubscribed = true
        WidgetCenter.shared.reloadTimelines(ofKind: "ManifestWidget")
    }
}

extension RitualActivityScheduler {
    static func stop() {
        DeviceActivityCenter().stopMonitoring([activityName])
    }

    static func reschedule(settings: AppSettings) {
        let center = DeviceActivityCenter()
        center.stopMonitoring([activityName])

        let startMinutes = settings.windowStartMinutes
        // With lockAllDayUntilDone, the interval runs to end-of-day instead
        // of the window's own end — the shield only comes down at
        // intervalDidEnd or when the ritual's done, matching "locked until
        // it's done" instead of "locked until the window closes."
        let endMinutes = settings.lockAllDayUntilDone ? 23 * 60 + 59 : settings.windowEndMinutes
        guard endMinutes > startMinutes else { return }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startMinutes / 60, minute: startMinutes % 60),
            intervalEnd: DateComponents(hour: endMinutes / 60, minute: endMinutes % 60),
            repeats: true
        )

        do {
            try center.startMonitoring(activityName, during: schedule)
        } catch {
            print("[RitualActivityScheduler] failed to start monitoring: \(error)")
        }
    }
}
