//
//  SignOffView.swift
//  Manifest
//
//  Screen 14/19 — images/screens/14-sign-off.png
//

import SwiftUI
import FamilyControls

struct SignOffView: View {
    var settings: AppSettings
    var onDone: () -> Void

    @Environment(\.modelContext) private var modelContext

    private var streak: Int { RitualLog.currentStreak(in: modelContext) }

    private var lockedCount: Int {
        guard let data = settings.familyActivitySelectionData,
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return 0
        }
        return selection.applicationTokens.count + selection.categoryTokens.count
    }

    private static let closingLines = [
        "You showed up before the noise did. Carry that quiet with you.",
        "That's one more morning you kept your word to yourself.",
        "The apps can wait. You already did the important part.",
    ]

    var body: some View {
        ZStack {
            LinearGradient.signOffBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                RoadMarkGlyph(size: 110).breathingGlow()

                Spacer().frame(height: 24)

                LumenMascot(mood: .delighted, size: 56)

                Spacer().frame(height: 20)

                Text("RITUAL COMPLETE \u{00B7} DAY \(max(streak, 1))")
                    .eyebrowStyle(.accent300)

                Spacer().frame(height: 14)

                Text(Self.closingLines.randomElement() ?? Self.closingLines[0])
                    .font(.newsreader(28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 12)

                Spacer().frame(height: 22)

                HStack(spacing: 8) {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold))
                    Text("\(lockedCount) apps unlocked")
                }
                .font(.manropeBold(14))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())

                Spacer()

                PrimaryButton(title: "Start my day") { onDone() }

                Spacer().frame(height: 10)

                Text("Tomorrow's script arrives at \(formatMinutesAsTime(settings.windowStartMinutes, language: settings.language))")
                    .font(.manrope(13))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    SignOffView(settings: AppSettings()) {}
}
