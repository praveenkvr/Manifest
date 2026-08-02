//
//  AppSettings.swift
//  Manifest
//
//  Single-row settings model (the app queries for the first instance and
//  creates it on first launch if missing — see RootView).
//

import Foundation
import SwiftData

enum AppTheme: String, Codable {
    case light
    case dark
}

@Model
final class AppSettings {
    var theme: AppTheme
    /// Stored as a raw String, not the enum directly — SwiftData's lightweight
    /// migration reliably backfills a default for primitive-typed properties
    /// added later (String, Bool, Int), but is unreliable for custom
    /// RawRepresentable enum types even with a literal default, which is what
    /// crashed on existing installs ("Could not cast ... to AmbientSoundOption").
    /// AppTheme above is fine because it's part of the original schema and
    /// never needed a migration — this only bites newly-added enum properties.
    private var accentThemeRaw: String = AccentTheme.jade.rawValue
    var accentTheme: AccentTheme {
        get { AccentTheme(rawValue: accentThemeRaw) ?? .jade }
        set { accentThemeRaw = newValue.rawValue }
    }
    var defaultStyle: ManifestationStyle
    var language: String

    /// Ritual window, stored as minutes since midnight (local time).
    var windowStartMinutes: Int
    var windowEndMinutes: Int
    /// Calendar weekday raw values (1 = Sunday ... 7 = Saturday) the ritual is active on.
    var activeWeekdays: [Int]

    var graceSkipsPerWeek: Int
    var graceSkipsUsedThisWeek: Int
    var ambientSoundEnabled: Bool
    private var ambientSoundOptionRaw: String = AmbientSoundOption.tranquility.rawValue
    var ambientSoundOption: AmbientSoundOption {
        get { AmbientSoundOption(rawValue: ambientSoundOptionRaw) ?? .tranquility }
        set { ambientSoundOptionRaw = newValue.rawValue }
    }
    /// When true, apps stay locked any time of day (from the window's start)
    /// until the ritual is completed — not just during the window itself.
    var lockAllDayUntilDone: Bool

    /// Encoded `FamilyActivitySelection` from FamilyActivityPicker — opaque
    /// blob, decoded only where ManagedSettings/FamilyControls code needs it.
    var familyActivitySelectionData: Data?

    var hasCompletedOnboarding: Bool

    init(
        theme: AppTheme = .light,
        accentTheme: AccentTheme = .jade,
        defaultStyle: ManifestationStyle = .present,
        language: String = Locale.current.language.languageCode?.identifier ?? "en",
        windowStartMinutes: Int = 6 * 60 + 30,
        windowEndMinutes: Int = 9 * 60,
        activeWeekdays: [Int] = Array(1...7),
        graceSkipsPerWeek: Int = 2,
        graceSkipsUsedThisWeek: Int = 0,
        ambientSoundEnabled: Bool = true,
        ambientSoundOption: AmbientSoundOption = .tranquility,
        lockAllDayUntilDone: Bool = false,
        hasCompletedOnboarding: Bool = false
    ) {
        self.theme = theme
        self.accentThemeRaw = accentTheme.rawValue
        self.defaultStyle = defaultStyle
        self.language = language
        self.windowStartMinutes = windowStartMinutes
        self.windowEndMinutes = windowEndMinutes
        self.activeWeekdays = activeWeekdays
        self.graceSkipsPerWeek = graceSkipsPerWeek
        self.graceSkipsUsedThisWeek = graceSkipsUsedThisWeek
        self.ambientSoundEnabled = ambientSoundEnabled
        self.ambientSoundOptionRaw = ambientSoundOption.rawValue
        self.lockAllDayUntilDone = lockAllDayUntilDone
        self.familyActivitySelectionData = nil
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
