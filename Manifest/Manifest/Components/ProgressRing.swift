//
//  ProgressRing.swift
//  Manifest
//
//  Circular completion indicator — ritual preview, ritual reading, goal detail.
//

import SwiftUI

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 3
    var size: CGFloat = 32
    var trackColor: Color = .white.opacity(0.2)
    var fillColor: Color = .accent300

    var body: some View {
        ZStack {
            Circle().stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(fillColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.3), value: progress)
    }
}

#Preview {
    ProgressRing(progress: 0.4)
        .padding(40)
        .background(Color.ink700)
}
