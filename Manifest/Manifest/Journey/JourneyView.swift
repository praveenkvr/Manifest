//
//  JourneyView.swift
//  Manifest
//
//  Screen 18/19 — images/screens/18-journey.png
//

import SwiftUI
import SwiftData

struct JourneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RitualLog.date, order: .reverse) private var logs: [RitualLog]
    @Query(sort: \DailyScript.date, order: .reverse) private var scripts: [DailyScript]
    @Query private var goals: [Goal]

    private var streak: Int { RitualLog.currentStreak(in: modelContext) }
    private var totalRead: Int { logs.filter(\.completed).reduce(0) { $0 + $1.linesRead } }
    private var fulfilledCount: Int { goals.filter(\.isFulfilled).count }

    /// Oldest-to-newest across the last 35 days, 7 per row.
    private var last5Weeks: [Bool?] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let byDate = Dictionary(uniqueKeysWithValues: logs.map { (calendar.startOfDay(for: $0.date), $0.completed) })
        return (0..<35).reversed().map { offset -> Bool? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return byDate[day]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Your journey").font(.newsreader(30)).foregroundStyle(.textPrimary)
                        Spacer()
                        LumenMascot(mood: .delighted, size: 40)
                    }

                    HStack(spacing: 10) {
                        statCard(value: "\(streak)", label: "day streak")
                        statCard(value: "\(totalRead)", label: "rituals read")
                        statCard(value: "\(fulfilledCount)", label: "fulfilled", highlighted: true)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("LAST 5 WEEKS").eyebrowStyle(.textSecondary)
                        gridView
                    }
                    .padding(18)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    if !quoteArchive.isEmpty {
                        Text("QUOTE ARCHIVE").eyebrowStyle(.textSecondary)
                        VStack(spacing: 12) {
                            ForEach(Array(quoteArchive.enumerated()), id: \.offset) { index, entry in
                                quoteCard(entry, alternate: index % 2 == 1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 68)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar(.hidden)
        }
    }

    private var quoteArchive: [(line: String, date: Date)] {
        scripts.compactMap { script in
            script.lines.first.map { (line: $0, date: script.date) }
        }.prefix(6).map { $0 }
    }

    private func statCard(value: String, label: String, highlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.newsreader(30)).foregroundStyle(highlighted ? .gold600 : .textPrimary)
            Text(label).font(.manrope(12.5)).foregroundStyle(.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(highlighted ? Color.gold50 : Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var gridView: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(last5Weeks.enumerated()), id: \.offset) { _, completed in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(completed == true ? Color.accent500 : Color.slate300.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    private func quoteCard(_ entry: (line: String, date: Date), alternate: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\u{201C}\(entry.line)\u{201D}")
                .font(.newsreaderItalic(17))
                .foregroundStyle(.ink900)
                .lineSpacing(3)
            Text(entry.date, format: .dateTime.day().month(.abbreviated))
                .font(.manrope(12.5))
                .foregroundStyle(.ink900.opacity(0.5))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alternate ? Color.accent50 : Color.lavender50)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    JourneyView()
        .modelContainer(for: [RitualLog.self, DailyScript.self, Goal.self], inMemory: true)
}
