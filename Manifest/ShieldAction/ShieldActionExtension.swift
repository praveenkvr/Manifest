//
//  ShieldActionExtension.swift
//  ShieldAction
//
//  ShieldConfigurationExtension only sets a primary button ("Open Manifest"),
//  no secondary one, so secondaryButtonPressed never actually fires in
//  practice — handled the same as primary regardless, just in case.
//  There's no "launch the companion app" response in this API, so .close is
//  the honest choice: it dismisses the shield screen and returns to the
//  home screen: from there the user opens Manifest themselves.
//

import ManagedSettings

class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.close)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.close)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.close)
    }
}
