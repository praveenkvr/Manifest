//
//  Color+Palette.swift
//  Manifest
//
//  Design tokens from design_handoff_manifest/README.md. Plain hex constants
//  rather than Asset Catalog color sets: several screens (ritual, paywall,
//  settings) are deliberately dark by design regardless of system light/dark
//  mode, so there's no automatic light/dark resolution to lean on yet.
//

import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    // Primary actions, progress, waves — resolves through the user's chosen
    // AccentTheme (Settings > Color theme), defaulting to jade. Every other
    // token on this page stays fixed across themes.
    static var accent900: Color { ThemeStore.shared.current.c900 }
    static var accent700: Color { ThemeStore.shared.current.c700 }
    static var accent600: Color { ThemeStore.shared.current.c600 }
    static var accent500: Color { ThemeStore.shared.current.c500 }
    static var accent300: Color { ThemeStore.shared.current.c300 }
    static var accent50: Color { ThemeStore.shared.current.c50 }

    // Gold — star, streaks, celebration
    static let gold600 = Color(hex: 0xC9962F)
    static let gold500 = Color(hex: 0xE0A94A)
    static let gold300 = Color(hex: 0xF6DFA8)
    static let gold50 = Color(hex: 0xFCF2DC)

    // Lavender & sky — grounds, Water style
    static let lavender500 = Color(hex: 0x8E7BC4)
    static let lavender50 = Color(hex: 0xF1EDF9)
    static let sky500 = Color(hex: 0x59B8E0)

    // Ink & slate — text, dark surfaces
    static let ink900 = Color(hex: 0x17231D)
    static let ink700 = Color(hex: 0x0E1A16)
    static let slate500 = Color(hex: 0x74837B)
    static let slate400 = Color(hex: 0x8A968C)
    static let slate300 = Color(hex: 0xA3AFA7)

    // Grounds — fixed values, used where a screen is deliberately dark or
    // deliberately light regardless of the app's theme setting (onboarding,
    // ritual reading, paywall, sign-off).
    static let paper = Color(hex: 0xFBF9F4)
    static let paperAlt = Color.white

    // Adaptive semantic tokens — these are what flip when the user toggles
    // Settings > Dark theme (driven by `.preferredColorScheme` in RootView,
    // not the system appearance). Everyday screens (Home, Goals, Journey,
    // Settings, goal detail) should use these instead of the fixed grounds
    // above. Brand accents (accent/gold/lavender/sky) and the mascot stay fixed
    // across both themes, matching how the design already reuses them
    // identically on both light and permanently-dark screens.
    static var appBackground: Color {
        Color(light: Color(hex: 0xFBF9F4), dark: Color(hex: 0x0E1A16))
    }
    static var appSurface: Color {
        Color(light: .white, dark: Color(hex: 0x17231D))
    }
    static var textPrimary: Color {
        Color(light: Color(hex: 0x17231D), dark: Color(hex: 0xFBF9F4))
    }
    static var textSecondary: Color {
        Color(light: Color(hex: 0x74837B), dark: Color(hex: 0xA3AFA7))
    }

    private init(light: Color, dark: Color) {
        self.init(UIColor(light: UIColor(light), dark: UIColor(dark)))
    }
}

private extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init(dynamicProvider: { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

// SwiftUI only resolves leading-dot syntax (`.foregroundStyle(.accent500)`) for
// `some ShapeStyle` parameters if the static lives on ShapeStyle itself, not
// just on Color — mirrors how SwiftUI exposes `.red`, `.blue`, etc.
extension ShapeStyle where Self == Color {
    static var accent900: Color { .accent900 }
    static var accent700: Color { .accent700 }
    static var accent600: Color { .accent600 }
    static var accent500: Color { .accent500 }
    static var accent300: Color { .accent300 }
    static var accent50: Color { .accent50 }

    static var gold600: Color { .gold600 }
    static var gold500: Color { .gold500 }
    static var gold300: Color { .gold300 }
    static var gold50: Color { .gold50 }

    static var lavender500: Color { .lavender500 }
    static var lavender50: Color { .lavender50 }
    static var sky500: Color { .sky500 }

    static var ink900: Color { .ink900 }
    static var ink700: Color { .ink700 }
    static var slate500: Color { .slate500 }
    static var slate400: Color { .slate400 }
    static var slate300: Color { .slate300 }

    static var paper: Color { .paper }
    static var paperAlt: Color { .paperAlt }

    static var appBackground: Color { .appBackground }
    static var appSurface: Color { .appSurface }
    static var textPrimary: Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
}

extension LinearGradient {
    /// Welcome screen background: 178deg #F6F1FA 0% → #FBF9F4 55% → #E9F7F2 100%
    static let welcomeBackground = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xF6F1FA), location: 0),
            .init(color: Color(hex: 0xFBF9F4), location: 0.55),
            .init(color: Color(hex: 0xE9F7F2), location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Sign-off background: dark → theme-tinted mid → theme's light ground —
    /// shares its first two stops with themeDarkBackground for consistency
    /// with Ritual Reading, then fades to the theme's own light shade instead
    /// of a fixed mint.
    static var signOffBackground: LinearGradient {
        let theme = ThemeStore.shared.current
        return LinearGradient(
            stops: [
                .init(color: theme.darkGradientStops[0], location: 0),
                .init(color: theme.darkGradientStops[1], location: 0.55),
                .init(color: theme.c50, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Locked ritual card: 150deg accent600 → accent700
    static var lockedRitualCard: LinearGradient {
        LinearGradient(colors: [.accent600, .accent700], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Progress bars: 90deg accent300 → accent500
    static var progressBar: LinearGradient {
        LinearGradient(colors: [.accent300, .accent500], startPoint: .leading, endPoint: .trailing)
    }

    /// Deep, theme-tinted background for the two screens meant to feel
    /// immersive rather than utilitarian — Ritual Reading and the Paywall.
    static var themeDarkBackground: LinearGradient {
        LinearGradient(colors: ThemeStore.shared.current.darkGradientStops, startPoint: .top, endPoint: .bottom)
    }
}
