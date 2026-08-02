//
//  ScratchOffView.swift
//  Manifest
//
//  Screen 16/19 — images/screens/16-scratch-off.png
//  Real drag-to-erase mask (Canvas + destinationOut blend), not a fake
//  progress bar — the finger's path punches through the foil layer.
//

import SwiftUI
import SwiftData

struct ScratchOffView: View {
    var goal: Goal

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showShareCard = false

    private var daysToFulfill: Int {
        guard let fulfilledAt = goal.fulfilledAt else { return goal.dayNumber }
        let days = Calendar.current.dateComponents([.day], from: goal.createdAt, to: fulfilledAt).day ?? 0
        return days + 1
    }

    private var showUpStats: (completed: Int, total: Int) {
        let total = (try? modelContext.fetchCount(FetchDescriptor<RitualLog>())) ?? 0
        let completed = RitualLog.totalCompletedCount(in: modelContext)
        return (completed, max(total, completed))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xFDF6E9), .paper], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(.slate500)
                    }
                    Spacer()
                    Text("IT CAME TRUE").eyebrowStyle(.gold600)
                    Spacer()
                    Color.clear.frame(width: 20)
                }
                .padding(.top, 8)

                Spacer().frame(height: 18)

                Text("Scratch to reveal what you built")
                    .font(.newsreader(28))
                    .foregroundStyle(.ink900)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Spacer().frame(height: 22)

                ScratchCard(goal: goal, daysToFulfill: daysToFulfill)
                    .frame(height: 260)

                Spacer().frame(height: 20)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("RITUALS PER WEEK").eyebrowStyle(.textSecondary)
                        Spacer()
                    }
                    Text("You read your intention on \(showUpStats.completed) of \(showUpStats.total) mornings \u{2014} a \(showUpRate)% show-up rate.")
                        .font(.manrope(14.5))
                        .foregroundStyle(.ink900.opacity(0.8))
                        .lineSpacing(3)
                }
                .padding(18)
                .manifestCard()

                Spacer()

                PrimaryButton(title: "Reveal & celebrate") {
                    showShareCard = true
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
        .fullScreenCover(isPresented: $showShareCard) {
            ShareCardView(goal: goal, daysToFulfill: daysToFulfill, ritualsRead: showUpStats.completed)
        }
    }

    private var showUpRate: Int {
        let stats = showUpStats
        guard stats.total > 0 else { return 100 }
        return Int((Double(stats.completed) / Double(stats.total) * 100).rounded())
    }
}

private struct ScratchCard: View {
    var goal: Goal
    var daysToFulfill: Int

    @State private var erasedPath = Path()
    @State private var sampleCount = 0
    @State private var isRevealed = false

    var body: some View {
        ZStack {
            revealedContent

            if !isRevealed {
                foilLayer
                    .mask(
                        Canvas { context, size in
                            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                            context.blendMode = .destinationOut
                            context.fill(erasedPath, with: .color(.white))
                        }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0).onChanged { value in
                            erasedPath.addEllipse(in: CGRect(x: value.location.x - 26, y: value.location.y - 26, width: 52, height: 52))
                            sampleCount += 1
                            if sampleCount > 45 {
                                withAnimation(.easeOut(duration: 0.4)) { isRevealed = true }
                            }
                        }
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.ink900.opacity(0.1), radius: 12, y: 8)
    }

    private var revealedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FULFILLED \u{00B7} \(daysToFulfill) DAYS")
                .font(.manropeEyebrow(11))
                .tracking(1.6)
                .foregroundStyle(.gold300)
            Text(goal.text)
                .font(.newsreader(26))
                .foregroundStyle(.white)
                .lineSpacing(2)
            Spacer()
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(LinearGradient.lockedRitualCard)
    }

    private var foilLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xD9C9A8), Color(hex: 0xC9B58E), Color(hex: 0xE3D6BA)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                LumenMascot(mood: .calm, size: 32)
                Text("scratch to reveal")
                    .font(.manropeBold(14))
                    .foregroundStyle(.ink900.opacity(0.6))
            }
        }
    }
}

#Preview {
    ScratchOffView(goal: Goal(text: "Launch my ceramics studio", category: .career))
        .modelContainer(for: RitualLog.self, inMemory: true)
}
