//
//  RitualPreviewView.swift
//  Manifest
//
//  Screen 7/19 — images/screens/07-ritual-preview.png
//  A generic teaser of the reading flow — no Worker call here; the real
//  daily script is only fetched once a day inside the actual ritual (screen 13).
//

import SwiftUI

struct RitualPreviewView: View {
    var coordinator: OnboardingCoordinator

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 68)

                Text("PREVIEW").eyebrowStyle()

                Spacer().frame(height: 8)

                Text("This is your\nmorning ritual")
                    .font(.newsreader(34))
                    .foregroundStyle(.ink900)
                    .lineSpacing(2)

                Spacer().frame(height: 22)

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.ink700)

                    WaveBackground()
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 10) {
                            ProgressRing(progress: 2.0 / 6.0, size: 30)
                            Text("Line 2 of 6")
                                .font(.manrope(14))
                                .foregroundStyle(.white.opacity(0.75))
                        }

                        Text("\u{201C}My hands know this work. Every piece I make finds the person it was meant for.\u{201D}")
                            .font(.newsreader(24))
                            .foregroundStyle(.white)
                            .lineSpacing(3)

                        Spacer(minLength: 0)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 340)

                Spacer().frame(height: 20)

                featureRow(icon: "waveform", tint: .accent500, well: .accent50, text: "Read aloud while the waves breathe with you")
                featureRow(icon: "sparkle", tint: .gold600, well: .gold50, text: "Finish for a closing line, then your apps open")

                Spacer()

                PrimaryButton(title: "Choose apps to lock") {
                    coordinator.advance()
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
    }

    private func featureRow(icon: String, tint: Color, well: Color, text: String) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(well)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(tint))
            Text(LocalizedStringKey(text))
                .font(.manrope(14.5))
                .foregroundStyle(.ink900.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    RitualPreviewView(coordinator: OnboardingCoordinator())
}
