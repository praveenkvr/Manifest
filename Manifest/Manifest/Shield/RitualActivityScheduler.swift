//
//  RitualActivityScheduler.swift
//  Manifest
//
//  Registers the daily DeviceActivitySchedule that makes DeviceActivityMonitor
//  fire in the background at the ritual window's boundaries — this is what
//  lets the shield engage even if Manifest is never opened that day. Main-app
//  only; the extension just responds to the schedule this sets up, it doesn't
//  create schedules itself.
//

import Foundation
import DeviceActivity

enum RitualActivityScheduler {
    static let activityName = DeviceActivityName("ritualWindow")
}
