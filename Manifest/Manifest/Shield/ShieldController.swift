//
//  ShieldController.swift
//  Manifest
//
//  Applies/lifts the ManagedSettings shield for the user's chosen apps.
//  Shared with the DeviceActivityMonitor extension target (checked in
//  Xcode's File Inspector → Target Membership) — apply()/lift() run
//  identically whether called from the main app (on foreground/ritual
//  completion, for immediate feedback) or from the extension (on the
//  background schedule boundary, so the shield engages even if the app is
//  never opened that day). Both write to the same ManagedSettingsStore.
//

import Foundation
import FamilyControls
import ManagedSettings

enum ShieldController {
    private static let store = ManagedSettingsStore()

    static func apply(selectionData: Data?) {
        guard let data = selectionData,
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    static func lift() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
