//
//  EntitlementStore.swift
//  Manifest
//
//  Single source of truth for "is this device currently entitled" — every
//  gate (add goal, ritual, shield, notifications) reads this instead of
//  each querying RevenueCat separately. Backed by RevenueCat's own local
//  cache (CustomerInfo), so it reflects real entitlement state offline too.
//

import Foundation
import RevenueCat
import Observation

@Observable
final class EntitlementStore: NSObject {
    static let shared = EntitlementStore()

    private(set) var isSubscribed = false

    private override init() {
        super.init()
    }

    func startListening() {
        guard Purchases.isConfigured else { return }
        Purchases.shared.delegate = self
        refresh()
    }

    func refresh() {
        guard Purchases.isConfigured else { return }
        Task {
            guard let info = try? await Purchases.shared.customerInfo() else { return }
            await apply(info)
        }
    }

    /// Applies a CustomerInfo the caller already has in hand — a purchase or
    /// restore's result already includes it, so this updates state
    /// immediately instead of waiting on the delegate callback (which
    /// updates state too, but isn't guaranteed to land before the paywall
    /// dismisses and the rest of the app re-renders).
    @MainActor
    func apply(_ info: CustomerInfo) {
        isSubscribed = !info.entitlements.active.isEmpty
    }
}

extension EntitlementStore: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { await apply(customerInfo) }
    }
}
