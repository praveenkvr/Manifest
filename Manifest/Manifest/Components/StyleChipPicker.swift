//
//  StyleChipPicker.swift
//  Manifest
//
//  Per-goal style chip row, shared by Goal Capture (onboarding) and Add Goal
//  (Home) — each manifestation picks its own style at creation instead of
//  silently inheriting whatever the app-wide default currently is, so a user
//  can run a present-tense goal, a water-charging goal, and a 369 goal side
//  by side.
//

import SwiftUI

struct StyleChipPicker: View {
    @Binding var style: ManifestationStyle
    var language: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STYLE").eyebrowStyle(.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ManifestationStyle.allCases, id: \.self) { option in
                        let isSelected = style == option
                        Text(option.displayName(language: language))
                            .font(.manrope(14, weight: .medium))
                            .foregroundStyle(isSelected ? .ink900 : .textSecondary)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.accent50 : Color.appSurface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.slate300.opacity(0.4), lineWidth: 1))
                            .onTapGesture { style = option }
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var style: ManifestationStyle = .present
    return StyleChipPicker(style: $style, language: "en")
        .padding(24)
        .background(Color.appBackground)
}
