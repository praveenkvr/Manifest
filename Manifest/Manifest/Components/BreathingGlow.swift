//
//  BreathingGlow.swift
//  Manifest
//
//  6s ease-in-out infinite scale 1 -> 1.06, opacity .8 -> 1 — used on Welcome
//  and Sign-off per the design spec's "breathing glow" interaction.
//

import SwiftUI

private struct BreathingGlowModifier: ViewModifier {
    @State private var isExpanded = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isExpanded ? 1.06 : 1)
            .opacity(isExpanded ? 1 : 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    isExpanded = true
                }
            }
    }
}

extension View {
    func breathingGlow() -> some View {
        modifier(BreathingGlowModifier())
    }
}
