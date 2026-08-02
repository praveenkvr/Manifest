//
//  NotificationRouter.swift
//  Manifest
//
//  Tapping the ritual reminder notification should open today's ritual
//  directly, not just launch the app to whatever screen it happens to land
//  on. HomeView watches `pendingRitual` and presents the ritual flow itself
//  once it's on screen — this only decides "should the ritual open," not
//  how, since that's already HomeView's job.
//

import Foundation
import UserNotifications
import Observation

@Observable
final class NotificationRouter: NSObject {
    static let shared = NotificationRouter()
    var pendingRitual = false

    private override init() {
        super.init()
    }

    func startListening() {
        UNUserNotificationCenter.current().delegate = self
    }
}

extension NotificationRouter: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == NotificationScheduler.ritualID {
            pendingRitual = true
            Analytics.track("notification_tapped_ritual")
        }
        completionHandler()
    }

    // Without this, a local notification firing while the app is already
    // open produces no banner/sound at all — UNUserNotificationCenter stays
    // silent in the foreground unless the delegate explicitly opts in.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
