//
//  AccentTheme.swift
//  Manifest
//
//  User-selectable brand color, chosen during onboarding and changeable in
//  Settings. Every `.accent*` token in Color+Palette.swift resolves through
//  ThemeStore to whichever palette is picked here — gold/lavender/sky stay
//  fixed regardless (they're semantic: streaks, "today's line" cards, the
//  Water style), only the "primary action" ramp swaps.
//

import SwiftUI

enum AccentTheme: String, Codable, CaseIterable, Identifiable {
    case jade, gold, lavender, rose

    var id: String { rawValue }

    func displayName(language: String) -> String {
        let locale = Locale(identifier: language)
        switch self {
        case .jade: return String(localized: "Jade", locale: locale)
        case .gold: return String(localized: "Gold", locale: locale)
        case .lavender: return String(localized: "Lavender", locale: locale)
        case .rose: return String(localized: "Rose", locale: locale)
        }
    }

    var c900: Color {
        switch self {
        case .jade: return Color(hex: 0x0B4438)
        case .gold: return Color(hex: 0x5C3D0E)
        case .lavender: return Color(hex: 0x2E2350)
        case .rose: return Color(hex: 0x4A1F2E)
        }
    }

    var c700: Color {
        switch self {
        case .jade: return Color(hex: 0x0C6753)
        case .gold: return Color(hex: 0x8A5D1A)
        case .lavender: return Color(hex: 0x4A3B7A)
        case .rose: return Color(hex: 0x7A3349)
        }
    }

    var c600: Color {
        switch self {
        case .jade: return Color(hex: 0x0F8F73)
        case .gold: return Color(hex: 0xC9962F)
        case .lavender: return Color(hex: 0x6B58A8)
        case .rose: return Color(hex: 0xA84568)
        }
    }

    var c500: Color {
        switch self {
        case .jade: return Color(hex: 0x17A183)
        case .gold: return Color(hex: 0xE0A94A)
        case .lavender: return Color(hex: 0x8E7BC4)
        case .rose: return Color(hex: 0xC96389)
        }
    }

    var c300: Color {
        switch self {
        case .jade: return Color(hex: 0x5FD8B6)
        case .gold: return Color(hex: 0xF6DFA8)
        case .lavender: return Color(hex: 0xC2B6E8)
        case .rose: return Color(hex: 0xEBA9C0)
        }
    }

    var c50: Color {
        switch self {
        case .jade: return Color(hex: 0xE4F7F1)
        case .gold: return Color(hex: 0xFCF2DC)
        case .lavender: return Color(hex: 0xF1EDF9)
        case .rose: return Color(hex: 0xFCEEF3)
        }
    }

    /// The dark, tinted 3-stop gradient used behind Ritual Reading and the
    /// Paywall — same recipe as the original fixed jade one (deep ink →
    /// tinted mid → ink), just rotated to each theme's hue.
    var darkGradientStops: [Color] {
        switch self {
        case .jade: return [Color(hex: 0x0B1B17), Color(hex: 0x10302A), Color(hex: 0x0C231E)]
        case .gold: return [Color(hex: 0x1B160B), Color(hex: 0x302510), Color(hex: 0x231C0C)]
        case .lavender: return [Color(hex: 0x150B1B), Color(hex: 0x241030), Color(hex: 0x1B0C23)]
        case .rose: return [Color(hex: 0x1B0B12), Color(hex: 0x301019), Color(hex: 0x230C15)]
        }
    }
}
