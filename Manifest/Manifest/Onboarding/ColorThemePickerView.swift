//
//  ColorThemePickerView.swift
//  Manifest
//
//  Comes right after Style in onboarding — both are "how this should feel
//  to you" choices. Also re-editable later from Settings > Color theme.
//

import SwiftUI

struct ColorThemePickerView: View {
    var coordinator: OnboardingCoordinator
    var settings: AppSettings

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 68)

                Text("YOUR COLOR")
                    .eyebrowStyle()

                Spacer().frame(height: 8)

                Text("Pick a shade that\nfeels like you")
                    .font(.newsreader(37))
                    .foregroundStyle(.ink900)
                    .lineSpacing(2)

                Spacer().frame(height: 24)

                VStack(spacing: 14) {
                    ForEach(AccentTheme.allCases) { theme in
                        themeCard(theme)
                    }
                }

                Spacer().frame(height: 14)

                HStack(alignment: .top, spacing: 12) {
                    LumenMascot(mood: .calm, size: 40)
                    Text("Change this any time in Settings.")
                        .font(.manrope(14))
                        .foregroundStyle(.ink900.opacity(0.75))
                        .lineSpacing(3)
                }
                .padding(16)
                .background(Color.lavender50)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer()

                PrimaryButton(title: "Continue") {
                    coordinator.advance()
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
    }

    private func themeCard(_ theme: AccentTheme) -> some View {
        let isSelected = settings.accentTheme == theme

        return HStack(spacing: 14) {
            Circle()
                .fill(LinearGradient(colors: [theme.c300, theme.c500], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)

            Text(theme.displayName(language: settings.language))
                .font(.manropeBold(16))
                .foregroundStyle(.ink900)

            Spacer()

            ZStack {
                Circle()
                    .strokeBorder(isSelected ? Color.clear : Color.slate300, lineWidth: 1.5)
                    .background(Circle().fill(isSelected ? theme.c500 : Color.clear))
                    .frame(width: 24, height: 24)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(16)
        .manifestCard()
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? theme.c300 : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            settings.accentTheme = theme
        }
    }
}

#Preview {
    ColorThemePickerView(coordinator: OnboardingCoordinator(), settings: AppSettings())
}
