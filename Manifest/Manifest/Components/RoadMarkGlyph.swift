//
//  RoadMarkGlyph.swift
//  Manifest
//
//  In-app brand mark — the actual designed asset (Assets.xcassets/LogoMark,
//  from images/icon/logo-transparent-*.png in the design handoff), not a
//  hand-drawn approximation. Used on Welcome, Sign-off, Paywall, and
//  Settings wherever the mark needs to sit on its own without a card
//  background behind it.
//

import SwiftUI

struct RoadMarkGlyph: View {
    var size: CGFloat = 160

    var body: some View {
        Image("LogoMark")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

#Preview {
    RoadMarkGlyph()
        .padding(40)
        .background(Color.paper)
}
