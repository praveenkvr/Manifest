//
//  RangeSlider.swift
//  Manifest
//
//  Dual-thumb slider for the ritual window (Schedule screen, Settings).
//  Values are minutes since midnight, snapped to 15-minute increments.
//

import SwiftUI

struct RangeSlider: View {
    @Binding var startMinutes: Int
    @Binding var endMinutes: Int
    var bounds: ClosedRange<Int> = 0...(24 * 60 - 1)

    private let span = 24 * 60

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let startX = position(for: startMinutes, width: width)
            let endX = position(for: endMinutes, width: width)

            ZStack(alignment: .leading) {
                Capsule().fill(Color.slate300.opacity(0.35)).frame(height: 6)
                Capsule()
                    .fill(LinearGradient.progressBar)
                    .frame(width: max(0, endX - startX), height: 6)
                    .offset(x: startX)

                thumb.position(x: startX, y: geo.size.height / 2)
                    .gesture(dragGesture(width: width, isStart: true))
                thumb.position(x: endX, y: geo.size.height / 2)
                    .gesture(dragGesture(width: width, isStart: false))
            }
        }
        .frame(height: 28)
    }

    private var thumb: some View {
        Circle()
            .fill(.white)
            .frame(width: 24, height: 24)
            .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
    }

    private func position(for minutes: Int, width: CGFloat) -> CGFloat {
        CGFloat(minutes) / CGFloat(span) * width
    }

    private func minutes(for x: CGFloat, width: CGFloat) -> Int {
        let raw = Double(x / width) * Double(span)
        let snapped = (Int(raw.rounded()) / 15) * 15
        return min(max(snapped, bounds.lowerBound), bounds.upperBound)
    }

    private func dragGesture(width: CGFloat, isStart: Bool) -> some Gesture {
        DragGesture(minimumDistance: 0).onChanged { value in
            let m = minutes(for: value.location.x, width: width)
            if isStart {
                startMinutes = min(m, endMinutes - 15)
            } else {
                endMinutes = max(m, startMinutes + 15)
            }
        }
    }
}

/// Locale-aware — respects each language's own time conventions (12-hour
/// with AM/PM for English, 24-hour for most others) instead of always
/// forcing English AM/PM regardless of the app's language setting.
func formatMinutesAsTime(_ minutes: Int, language: String = Locale.current.language.languageCode?.identifier ?? "en") -> String {
    var components = DateComponents()
    components.hour = minutes / 60
    components.minute = minutes % 60
    guard let date = Calendar.current.date(from: components) else { return "" }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: language)
    // "j" is ICU's locale-preferred-hour skeleton symbol — unlike "h"
    // (which hardcodes 12-hour with AM/PM regardless of locale), "j" lets
    // each locale pick 12- vs 24-hour formatting on its own.
    formatter.setLocalizedDateFormatFromTemplate(minutes % 60 == 0 ? "j" : "jmm")
    return formatter.string(from: date)
}
