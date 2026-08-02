//
//  GatekeeperView.swift
//  Manifest
//
//  Screen 2/19 — images/screens/02-gatekeeper.png
//

import SwiftUI

private struct ExplainerRow: Identifiable {
    let id = UUID()
    let icon: String
    let iconTint: Color
    let wellTint: Color
    let title: String
    let subtitle: String
}

// String(localized:) — not a Text() literal, so Xcode's String Catalog
// extraction needs the explicit call to pick these up for translation.
private let rows: [ExplainerRow] = [
    ExplainerRow(icon: "lock.fill", iconTint: .lavender500, wellTint: .lavender50,
                 title: String(localized: "Locked at 7:00 AM"),
                 subtitle: String(localized: "Instagram, TikTok, X, Reddit")),
    ExplainerRow(icon: "waveform", iconTint: .accent500, wellTint: .accent50,
                 title: String(localized: "Read your intention"),
                 subtitle: String(localized: "A fresh script each day, about 90 seconds")),
    ExplainerRow(icon: "checkmark", iconTint: .gold600, wellTint: .gold50,
                 title: String(localized: "Your day unlocks"),
                 subtitle: String(localized: "Mind set first, phone second")),
]

struct GatekeeperView: View {
    var coordinator: OnboardingCoordinator

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 68)

                Text("HOW IT WORKS")
                    .eyebrowStyle()

                Spacer().frame(height: 8)

                Text("The gatekeeper")
                    .font(.newsreader(37))
                    .foregroundStyle(.ink900)

                Spacer().frame(height: 12)

                Text("Pick the apps that steal your morning. They stay shut until you've read your intention out loud.")
                    .font(.manrope(15))
                    .foregroundStyle(.slate500)
                    .lineSpacing(4)

                Spacer().frame(height: 24)

                VStack(spacing: 14) {
                    ForEach(rows) { row in
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(row.wellTint)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: row.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(row.iconTint)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                // row.title/subtitle were resolved once at
                                // module load via String(localized:), which
                                // has no access to .environment(\.locale) and
                                // so always resolves to the source (English)
                                // text — re-wrapping as a LocalizedStringKey
                                // here re-looks them up against the current
                                // environment locale instead.
                                Text(LocalizedStringKey(row.title))
                                    .font(.manropeBold(15.5))
                                    .foregroundStyle(.ink900)
                                Text(LocalizedStringKey(row.subtitle))
                                    .font(.manrope(14))
                                    .foregroundStyle(.slate500)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(15)
                        .manifestCard()
                    }
                }

                Spacer()

                PageDots(count: 3, activeIndex: 1)
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
}

#Preview {
    GatekeeperView(coordinator: OnboardingCoordinator())
}
