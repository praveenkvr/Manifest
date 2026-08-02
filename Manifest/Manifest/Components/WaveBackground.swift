//
//  WaveBackground.swift
//  Manifest
//
//  Three-layer wave stack anchored to the bottom of a dark card — used on
//  the ritual preview and the real ritual reading screen. Drifts slowly
//  (~10s per loop) per the design's "calming, continuous" wave interaction.
//

import SwiftUI

struct WaveBackground: View {
    var animate: Bool = true
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            WaveShape(phase: phase, amplitude: 8, wavelength: 220)
                .fill(Color.accent700.opacity(0.55))
                .frame(height: 90)
            WaveShape(phase: phase * 1.3, amplitude: 11, wavelength: 260)
                .fill(Color.accent600.opacity(0.8))
                .frame(height: 66)
            WaveShape(phase: phase * 1.6, amplitude: 9, wavelength: 200)
                .fill(Color.accent300)
                .frame(height: 42)
        }
        .onAppear {
            guard animate else { return }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                phase = 220
            }
        }
    }
}

private struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var wavelength: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseline = rect.height * 0.45
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: baseline))
        var x: CGFloat = 0
        while x <= rect.width {
            let y = baseline + sin((x + phase) / wavelength * .pi * 2) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += 6
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

#Preview {
    WaveBackground()
        .frame(height: 200)
        .background(Color.ink700)
}
