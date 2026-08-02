//
//  AmbientSoundOption.swift
//  Manifest
//
//  Real ambient music, not procedural noise — four tracks by Kevin MacLeod
//  (incompetech.com), licensed under Creative Commons Attribution 3.0,
//  which explicitly permits commercial use at no cost as long as the music
//  is credited (see MusicCredits.swift and its Settings row). Downloaded
//  directly from incompetech.com — not a random "free sound" aggregator —
//  and re-encoded to AAC to keep the app bundle reasonably sized.
//
//  Bundled as Sounds/<rawValue>.m4a — AmbientAudioPlayer loops whichever
//  one is selected. `fileName` is the single place that mapping lives.
//

import Foundation

enum AmbientSoundOption: String, Codable, CaseIterable, Identifiable {
    case tranquility = "ambient_tranquility"
    case meditation = "ambient_meditation"
    case innerLight = "ambient_inner_light"
    case bathedInLight = "ambient_bathed_in_light"
    case random

    var id: String { rawValue }
    var fileName: String { rawValue }

    func displayName(language: String) -> String {
        let locale = Locale(identifier: language)
        switch self {
        case .tranquility: return String(localized: "Tranquility", locale: locale)
        case .meditation: return String(localized: "Meditation Impromptu", locale: locale)
        case .innerLight: return String(localized: "Inner Light", locale: locale)
        case .bathedInLight: return String(localized: "Bathed in the Light", locale: locale)
        case .random: return String(localized: "Random", locale: locale)
        }
    }

    /// `.random` resolves to one of the other cases at playback time —
    /// never to itself, and never to a silent no-op.
    var resolved: AmbientSoundOption {
        self == .random ? Self.allCases.filter { $0 != .random }.randomElement()! : self
    }
}
