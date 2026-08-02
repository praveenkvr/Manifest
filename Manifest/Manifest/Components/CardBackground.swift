//
//  CardBackground.swift
//  Manifest
//
//  White rounded card, used across gatekeeper rows, style cards, permission
//  rows and (in later passes) goal/home cards. Shadow per the design spec:
//  `0 2px 8px rgba(23,35,29,.05)`.
//

import SwiftUI

extension View {
    /// `adaptive: true` flips the card to `Color.appSurface` for screens that
    /// use the adaptive text tokens (Settings, Grace skip) and follow the
    /// user's light/dark theme setting. Leave it `false` (default) on screens
    /// that are deliberately light or dark regardless of theme — those pair
    /// this fixed white card with fixed `.ink900`/`.slate500` text, and
    /// switching it would break that pairing instead of fixing it.
    func manifestCard(cornerRadius: CGFloat = 20, adaptive: Bool = false) -> some View {
        self
            .background(adaptive ? Color.appSurface : Color.paperAlt)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.ink900.opacity(0.05), radius: 4, y: 2)
    }

    /// 11/700 Manrope, uppercase, tracked-out — the "HOW IT WORKS" / "YOUR STYLE" labels.
    func eyebrowStyle(_ color: Color = .accent500) -> some View {
        self
            .font(.manropeEyebrow())
            .tracking(1.6)
            .foregroundStyle(color)
    }
}
