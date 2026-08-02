//
//  WelcomeView.swift
//  Manifest
//
//  Screen 1/19 — images/screens/01-welcome.png
//

import SwiftUI

struct WelcomeView: View {
    var coordinator: OnboardingCoordinator

    var body: some View {
        ZStack {
            LinearGradient.welcomeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                RoadMarkGlyph(size: 130)
                    .breathingGlow()

                Spacer().frame(height: 36)

                Text("Your intentions,\nprotected daily.")
                    .font(.newsreader(37))
                    .foregroundStyle(.ink900)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer().frame(height: 16)

                Text("Manifest turns your goal into a two-minute morning ritual — and keeps your distractions locked until it's done.")
                    .font(.manrope(15))
                    .foregroundStyle(.slate500)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 12)

                Spacer()

                PageDots(count: 3, activeIndex: 0)

                Spacer().frame(height: 20)

                PrimaryButton(title: "Begin") {
                    coordinator.advance()
                }

                Spacer().frame(height: 16)

                HStack(spacing: 8) {
                    LumenMascot(mood: .calm, size: 24)
                    Text("No account. Everything stays on your iPhone.")
                        .font(.manrope(13))
                        .foregroundStyle(.slate500)
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    WelcomeView(coordinator: OnboardingCoordinator())
}
