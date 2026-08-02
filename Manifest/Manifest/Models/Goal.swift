//
//  Goal.swift
//  Manifest
//

import Foundation
import SwiftData

enum ManifestationStyle: String, Codable, CaseIterable {
    case present
    case water
    /// Tesla's 3-6-9 method: write the affirmation 3x in the morning, 6x in
    /// the afternoon, 9x at night. Tracked separately via `NineSession` —
    /// not read aloud in the shared morning ritual like the other styles.
    case threeSixNine = "369"

    // `String(localized:)` outside a SwiftUI view has no access to
    // `.environment(\.locale)`, so it silently resolves against the
    // device's system locale instead of the app's own language setting.
    // Passing `locale:` explicitly is the only way these actually follow
    // Settings > Language rather than whatever the device happens to be set to.
    func displayName(language: String) -> String {
        let locale = Locale(identifier: language)
        switch self {
        case .present: return String(localized: "Present tense", locale: locale)
        case .water: return String(localized: "Water charging", locale: locale)
        case .threeSixNine: return String(localized: "369 method", locale: locale)
        }
    }
}

enum GoalCategory: String, Codable, CaseIterable {
    case career, health, money, love, calm, custom

    func label(language: String) -> String {
        let locale = Locale(identifier: language)
        switch self {
        case .career: return String(localized: "Career", locale: locale)
        case .health: return String(localized: "Health", locale: locale)
        case .money: return String(localized: "Money", locale: locale)
        case .love: return String(localized: "Love", locale: locale)
        case .calm: return String(localized: "Calm", locale: locale)
        case .custom: return String(localized: "Custom", locale: locale)
        }
    }
}

@Model
final class Goal {
    /// Stable key used to link `DailyScript` rows without a full SwiftData
    /// relationship graph — the app doesn't need graph traversal yet.
    var id: UUID
    var text: String
    var category: GoalCategory
    /// Only meaningful when `category == .custom` — the user's own label.
    var customCategoryLabel: String?
    var style: ManifestationStyle
    var createdAt: Date
    var fulfilledAt: Date?
    var notes: String
    /// User-chosen, independent of subscription state — a paused goal skips
    /// AI generation, notifications, and today's completion requirement.
    /// `EntitlementStore.isSubscribed == false` has the same effect on every
    /// goal without writing this field, so the two "why is this paused"
    /// reasons never collide (see ShieldController+AppSettings.swift).
    var isPaused: Bool = false
    /// Stored as a raw String, not the enum — see AppSettings.swift's
    /// accentThemeRaw for why (SwiftData migration is unreliable for
    /// non-optional custom enum types, even with a default). nil means "use
    /// the global default from Settings" — most goals won't need an override.
    private var ambientSoundOptionRaw: String?
    var ambientSoundOption: AmbientSoundOption? {
        get { ambientSoundOptionRaw.flatMap { AmbientSoundOption(rawValue: $0) } }
        set { ambientSoundOptionRaw = newValue?.rawValue }
    }
    @Attribute(.externalStorage) var imageData: [Data]

    init(
        text: String,
        category: GoalCategory,
        customCategoryLabel: String? = nil,
        style: ManifestationStyle = .present,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.text = text
        self.category = category
        self.customCategoryLabel = customCategoryLabel
        self.style = style
        self.createdAt = createdAt
        self.fulfilledAt = nil
        self.isPaused = false
        self.notes = ""
        self.imageData = []
    }

    /// What to actually show in chips/rows — the custom label when set, else the preset label.
    func displayCategory(language: String) -> String {
        if category == .custom, let customCategoryLabel, !customCategoryLabel.isEmpty {
            return customCategoryLabel
        }
        return category.label(language: language)
    }

    /// 1-indexed day count since the goal was created — drives the "Day 47" chip.
    var dayNumber: Int {
        let days = Calendar.current.dateComponents([.day], from: createdAt, to: .now).day ?? 0
        return days + 1
    }

    var isFulfilled: Bool { fulfilledAt != nil }
}
