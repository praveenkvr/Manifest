//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitor
//
//  Runs in the background on iOS's own schedule (registered by
//  RitualActivityScheduler in the main app) — this is what makes the shield
//  engage even if Manifest itself is never opened that day. Reads shared
//  state from SharedRitualStore.swift and applies/lifts via
//  ShieldController.swift, both shared with the main app target (checked
//  under Target Membership in Xcode's File Inspector).
//

import Foundation
import DeviceActivity

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard activity == RitualActivityScheduler.activityName else { return }
        // Defense-in-depth: the main app stops monitoring the moment a
        // subscription lapses, but a previously scheduled interval could
        // still fire in the gap before that runs.
        guard SharedRitualStore.isSubscribed else { return }

        let weekday = Calendar.current.component(.weekday, from: .now)
        guard SharedRitualStore.activeWeekdays.contains(weekday) else { return }
        guard !SharedRitualStore.isHandledToday else { return }

        ShieldController.apply(selectionData: SharedRitualStore.selectionData)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == RitualActivityScheduler.activityName else { return }

        // lockAllDayUntilDone schedules the interval to run to end-of-day,
        // so by the time this fires it's genuinely the end of the day —
        // always safe to lift and let tomorrow start fresh.
        ShieldController.lift()
    }
}
