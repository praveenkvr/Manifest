//
//  StylePickerView.swift
//  Manifest
//
//  Screen 3/19 — images/screens/03-style.png
//

import SwiftUI

struct StylePickerView: View {
    var coordinator: OnboardingCoordinator
    var settings: AppSettings

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 68)

                Text("YOUR STYLE")
                    .eyebrowStyle()

                Spacer().frame(height: 8)

                Text("How should we speak\nto you?")
                    .font(.newsreader(37))
                    .foregroundStyle(.ink900)
                    .lineSpacing(2)

                Spacer().frame(height: 24)

                VStack(spacing: 14) {
                    styleCard(
                        style: .present,
                        icon: nil,
                        title: "Present tense",
                        quote: "\u{201C}I am the person who finishes what she starts. My work is already finding its audience.\u{201D}"
                    )
                    styleCard(
                        style: .water,
                        icon: "drop.fill",
                        title: "Water charging",
                        quote: "\u{201C}Hold the glass. This water carries calm, clarity and steady focus into today.\u{201D}"
                    )
                    styleCard(
                        style: .threeSixNine,
                        icon: "pencil.line",
                        title: "369 method",
                        quote: "Write it 3 times in the morning, 6 in the afternoon, 9 at night."
                    )
                }

                Spacer().frame(height: 14)

                HStack(alignment: .top, spacing: 12) {
                    LumenMascot(mood: .calm, size: 40)
                    Text("Switch styles any time in Settings — I'll rewrite tomorrow's script to match.")
                        .font(.manrope(14))
                        .foregroundStyle(.ink900.opacity(0.75))
                        .lineSpacing(3)
                }
                .padding(16)
                .background(Color.lavender50)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer()

                PageDots(count: 3, activeIndex: 2)
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer().frame(height: 20)

                PrimaryButton(title: "Continue") {
                    coordinator.advance()
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
    }

    private func styleCard(style: ManifestationStyle, icon: String?, title: String, quote: String) -> some View {
        let isSelected = settings.defaultStyle == style

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.sky500)
                }
                Text(LocalizedStringKey(title))
                    .font(.manropeBold(15.5))
                    .foregroundStyle(.ink900)

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.clear : Color.slate300, lineWidth: 1.5)
                        .background(Circle().fill(isSelected ? Color.accent500 : Color.clear))
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }

            Text(LocalizedStringKey(quote))
                .font(.newsreaderItalic(17))
                .foregroundStyle(.ink900.opacity(0.7))
                .lineSpacing(3)
        }
        .padding(16)
        .manifestCard()
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? Color.accent300 : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            settings.defaultStyle = style
        }
    }
}

#Preview {
    StylePickerView(coordinator: OnboardingCoordinator(), settings: AppSettings())
}
