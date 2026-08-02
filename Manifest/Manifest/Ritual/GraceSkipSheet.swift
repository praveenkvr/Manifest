//
//  GraceSkipSheet.swift
//  Manifest
//
//  Screen 15/19 — images/screens/15-grace-skip.png
//

import SwiftUI

struct GraceSkipSheet: View {
    var settings: AppSettings
    var onUseGraceSkip: () -> Void
    var onReadNow: () -> Void

    private var skipsLeft: Int { max(settings.graceSkipsPerWeek - settings.graceSkipsUsedThisWeek, 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                LumenMascot(mood: .calm, size: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Rough morning?").font(.newsreader(25)).foregroundStyle(.textPrimary)
                    Text("Grace skip \u{00B7} \(skipsLeft) left this week")
                        .font(.manrope(13.5)).foregroundStyle(.textSecondary)
                }
            }

            Text("A skip unlocks your apps now and keeps your streak intact. Your ritual will be waiting tomorrow \u{2014} no guilt attached.")
                .font(.manrope(15))
                .foregroundStyle(.textPrimary.opacity(0.75))
                .lineSpacing(3)

            VStack(spacing: 0) {
                sheetRow("Postpone 30 minutes")
                Divider()
                sheetRow("Read a shorter version")
            }
            .manifestCard(adaptive: true)

            Button {
                onUseGraceSkip()
            } label: {
                Text("Use a grace skip")
                    .font(.manropeBold(17))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.ink900)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(skipsLeft <= 0)
            .opacity(skipsLeft <= 0 ? 0.4 : 1)

            Button("I'll read it now") { onReadNow() }
                .font(.manropeBold(15))
                .foregroundStyle(.accent500)
                .frame(maxWidth: .infinity)
        }
        .padding(24)
        .padding(.bottom, 12)
        .background(Color.appBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func sheetRow(_ text: String) -> some View {
        HStack {
            Text(LocalizedStringKey(text)).font(.manropeBold(15.5)).foregroundStyle(.textPrimary)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.slate300)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    GraceSkipSheet(settings: AppSettings(), onUseGraceSkip: {}, onReadNow: {})
}
