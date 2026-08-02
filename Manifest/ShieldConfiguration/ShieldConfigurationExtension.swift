//
//  ShieldConfigurationExtension.swift
//  ShieldConfiguration
//
//  Customizes the blocked-app screen to match Manifest's brand instead of
//  Apple's generic gray default. Colors are hardcoded here (not shared via
//  Color+Palette.swift) since that file defines SwiftUI Color, not the
//  UIColor this API needs — not worth a cross-target dependency for four hex values.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        Self.manifestShield
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        Self.manifestShield
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        Self.manifestShield
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        Self.manifestShield
    }

    private static var manifestShield: ShieldConfiguration {
        ShieldConfiguration(
            backgroundColor: UIColor(red: 0x0B / 255, green: 0x1B / 255, blue: 0x17 / 255, alpha: 1),
            icon: UIImage(systemName: "sparkles"),
            title: .init(text: "Locked for your ritual", color: .white),
            subtitle: .init(
                text: "Finish today's intention in Manifest to unlock this.",
                color: UIColor.white.withAlphaComponent(0.7)
            ),
            primaryButtonLabel: .init(text: "Open Manifest", color: .white),
            primaryButtonBackgroundColor: UIColor(red: 0x17 / 255, green: 0xA1 / 255, blue: 0x83 / 255, alpha: 1)
        )
    }
}
