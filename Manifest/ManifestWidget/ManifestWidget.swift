//
//  ManifestWidget.swift
//  ManifestWidget
//
//  Reads the same App-Group snapshot DeviceActivityMonitor uses
//  (SharedRitualStore, target-membership-shared with the main app) — the
//  widget process can't reach SwiftData either. Colors are hardcoded to
//  match Color+Palette.swift's jade/gold/ink values rather than sharing that
//  file across targets, same call as ShieldConfigurationExtension made.
//

import WidgetKit
import SwiftUI

struct RitualEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let headline: String?
    let isCompletedToday: Bool
}

struct RitualProvider: TimelineProvider {
    func placeholder(in context: Context) -> RitualEntry {
        RitualEntry(date: .now, streak: 4, headline: "I am exactly where I need to be.", isCompletedToday: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (RitualEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RitualEntry>) -> Void) {
        // No push channel from the main app beyond WidgetCenter.reloadTimelines
        // (already called on every ritual/shield state change) — this 15-minute
        // fallback just keeps the day-boundary streak/headline text from going
        // stale if the app never reopens.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [currentEntry()], policy: .after(nextRefresh)))
    }

    private func currentEntry() -> RitualEntry {
        RitualEntry(
            date: .now,
            streak: SharedRitualStore.streak,
            headline: SharedRitualStore.headline,
            isCompletedToday: SharedRitualStore.isHandledToday
        )
    }
}

struct ManifestWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: RitualEntry

    private static let jade = Color(red: 0x17 / 255, green: 0xA1 / 255, blue: 0x83 / 255)
    private static let gold = Color(red: 0xE0 / 255, green: 0xA9 / 255, blue: 0x4A / 255)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkle").font(.system(size: 12, weight: .semibold)).foregroundStyle(Self.gold)
                Text("\(entry.streak) day\(entry.streak == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Self.gold)
            }

            if family == .systemMedium, let headline = entry.headline {
                Text(headline)
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Image(systemName: entry.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11))
                    .foregroundStyle(entry.isCompletedToday ? Self.jade : .white.opacity(0.5))
                Text(entry.isCompletedToday ? "Done for today" : "Ritual pending")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(URL(string: "manifest://open"))
    }
}

struct ManifestWidget: Widget {
    let kind = "ManifestWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RitualProvider()) { entry in
            ManifestWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(red: 0x0B / 255, green: 0x1B / 255, blue: 0x17 / 255),
                            Color(red: 0x17 / 255, green: 0x23 / 255, blue: 0x1D / 255),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Manifest Streak")
        .description("Your streak and today's manifestation, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    ManifestWidget()
} timeline: {
    RitualEntry(date: .now, streak: 4, headline: "I am exactly where I need to be.", isCompletedToday: false)
    RitualEntry(date: .now, streak: 12, headline: "My effort today already matters.", isCompletedToday: true)
}
