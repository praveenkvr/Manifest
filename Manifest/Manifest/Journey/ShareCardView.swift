//
//  ShareCardView.swift
//  Manifest
//
//  Screen 17/19 — images/screens/17-share-card.png
//  Renders the card to a real UIImage via ImageRenderer for ShareLink/save.
//

import SwiftUI

private enum CardTheme: String, CaseIterable {
    case sage, dusk, gold, night

    var label: String {
        switch self {
        case .sage: String(localized: "Sage")
        case .dusk: String(localized: "Dusk")
        case .gold: String(localized: "Gold")
        case .night: String(localized: "Night")
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .sage: LinearGradient.lockedRitualCard
        case .dusk: LinearGradient(colors: [Color(hex: 0x2A1B3D), Color(hex: 0x4A3363)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold: LinearGradient(colors: [Color(hex: 0x8A6A1F), Color(hex: 0xC9962F)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .night: LinearGradient(colors: [Color(hex: 0x0B1B17), Color(hex: 0x0E1A16)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct ShareCardView: View {
    var goal: Goal
    var daysToFulfill: Int
    var ritualsRead: Int

    @Environment(\.dismiss) private var dismiss
    @State private var theme: CardTheme = .sage
    @State private var renderedImage: Image?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "xmark").foregroundStyle(.slate500) }
                Spacer()
                Button("Save image") { saveImage() }
                    .font(.manrope(15, weight: .semibold))
                    .foregroundStyle(.accent500)
            }
            .padding(.top, 8)

            Spacer().frame(height: 18)

            Text("\(daysToFulfill) days. Worth sharing.")
                .font(.newsreader(28))
                .foregroundStyle(.ink900)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 20)

            card
                .frame(height: 340)

            Spacer().frame(height: 20)

            HStack(spacing: 10) {
                ForEach(CardTheme.allCases, id: \.self) { option in
                    let isSelected = theme == option
                    Text(option.label)
                        .font(.manrope(15, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .ink900)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isSelected ? Color.ink900 : Color.appSurface)
                        .clipShape(Capsule())
                        .onTapGesture { theme = option }
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Add to archive")
                        .font(.manropeBold(15))
                        .foregroundStyle(.ink900)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                if let renderedImage {
                    ShareLink(item: renderedImage, preview: SharePreview("Manifest", image: renderedImage)) {
                        Text("Share")
                            .font(.manropeBold(15))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.accent500)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                } else {
                    Text("Share")
                        .font(.manropeBold(15))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.accent500.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .background(Color.paper.ignoresSafeArea())
        .task(id: theme) { await renderImage() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white.opacity(0.06))
                .frame(height: 140)
                .overlay(
                    VStack(spacing: 6) {
                        Image(systemName: "photo").foregroundStyle(.white.opacity(0.3))
                        Text("Drop your proof photo").font(.manrope(13)).foregroundStyle(.white.opacity(0.4))
                    }
                )

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle").font(.system(size: 11)).foregroundStyle(.gold300)
                    Text("MANIFESTED").font(.manropeEyebrow(11)).tracking(1.6).foregroundStyle(.gold300)
                }
                Text(claimLine)
                    .font(.newsreader(22))
                    .foregroundStyle(.white)
                    .lineSpacing(2)

                Divider().overlay(Color.white.opacity(0.15))

                HStack {
                    statColumn(value: "\(daysToFulfill)", label: "days")
                    statColumn(value: "\(ritualsRead)", label: "rituals")
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right").font(.system(size: 12)).foregroundStyle(.accent300)
                        Text("Manifest").font(.manrope(13)).foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(18)
        }
        .background(theme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var claimLine: String {
        "\(goal.text) \u{2014} manifested."
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.newsreader(22)).foregroundStyle(.white)
            Text(label).font(.manrope(12)).foregroundStyle(.white.opacity(0.6))
        }
        .padding(.trailing, 18)
    }

    @MainActor
    private func renderImage() async {
        let renderer = ImageRenderer(content: card.frame(width: 360, height: 340))
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            renderedImage = Image(uiImage: uiImage)
        }
    }

    private func saveImage() {
        Task { @MainActor in
            let renderer = ImageRenderer(content: card.frame(width: 360, height: 340))
            renderer.scale = 3
            if let uiImage = renderer.uiImage {
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            }
        }
    }
}

#Preview {
    ShareCardView(goal: Goal(text: "Launch my ceramics studio", category: .career), daysToFulfill: 62, ritualsRead: 58)
}
