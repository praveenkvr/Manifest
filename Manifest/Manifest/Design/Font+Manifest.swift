//
//  Font+Manifest.swift
//  Manifest
//
//  Type scale from design_handoff_manifest/README.md:
//  - Newsreader (serif) for display/ritual text, regular + italic (quotes only).
//  - Manrope for UI: 700 buttons/eyebrows, 600 chips/row titles, 400 body/captions.
//  Font.custom silently falls back to the system font if a name isn't found, so
//  this is safe to use before the font files are bundled.
//

import SwiftUI

extension Font {
    /// Newsreader, the serif used for headlines, greetings and ritual lines.
    /// PostScript name is "Newsreader16pt-Regular" — an artifact of instancing
    /// the variable font at a pinned optical size, not an actual size restriction.
    static func newsreader(_ size: CGFloat) -> Font {
        .custom("Newsreader16pt-Regular", size: size)
    }

    /// Newsreader Italic — reserved for AI-generated quotes only.
    static func newsreaderItalic(_ size: CGFloat) -> Font {
        .custom("Newsreader16pt-Italic", size: size)
    }

    /// Manrope, the UI typeface, at a given weight.
    static func manrope(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(manropePostScriptName(for: weight), size: size)
            .weight(weight)
    }

    static func manropeBold(_ size: CGFloat) -> Font { .manrope(size, weight: .bold) }
    static func manropeSemibold(_ size: CGFloat) -> Font { .manrope(size, weight: .semibold) }

    /// Eyebrow labels: 11/700 Manrope, uppercase, 0.14-0.16em tracking — apply
    /// `.textCase(.uppercase).tracking(size * 0.15)` alongside this font at the call site.
    static func manropeEyebrow(_ size: CGFloat = 11) -> Font { .manrope(size, weight: .bold) }

    private static func manropePostScriptName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold: return "Manrope-Bold"
        case .semibold: return "Manrope-SemiBold"
        case .medium: return "Manrope-Medium"
        default: return "Manrope-Regular"
        }
    }
}
