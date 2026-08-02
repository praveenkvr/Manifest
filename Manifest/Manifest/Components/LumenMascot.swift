//
//  LumenMascot.swift
//  Manifest
//
//  Manifest's mascot: a soft droplet spirit (colored by the user's chosen
//  accent theme) with a gold sparkle, blush
//  cheeks and dot eyes. Built as a native vector view (no raster assets) so
//  it stays crisp at any size and recolors cleanly — the design spec says it
//  never renders larger than 64pt in-app anyway.
//

import SwiftUI

enum LumenMood {
    case calm       // default: dot eyes, gentle closed smile
    case delighted  // eyes raised, open smile — celebration contexts
    case resting    // closed curved eyes — night / wind-down contexts
}

struct LumenMascot: View {
    var mood: LumenMood = .calm
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            bodyShape
            cheeks
            eyes.offset(y: eyeOffsetY)
            mouth
            sparkle
        }
        .frame(width: size, height: size)
    }

    private var bodyShape: some View {
        Ellipse()
            .fill(
                LinearGradient(colors: [.accent300, .accent500], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .frame(width: size * 0.82, height: size * 0.94)
    }

    private var cheeks: some View {
        HStack(spacing: size * 0.34) {
            blushDot
            blushDot
        }
        .offset(y: size * 0.1)
    }

    private var blushDot: some View {
        Circle()
            .fill(Color(hex: 0xF6B99E).opacity(0.5))
            .frame(width: size * 0.13, height: size * 0.13)
    }

    private var eyeOffsetY: CGFloat {
        switch mood {
        case .calm, .resting: 0
        case .delighted: -size * 0.05
        }
    }

    private var eyes: some View {
        HStack(spacing: size * 0.17) {
            eye
            eye
        }
    }

    @ViewBuilder
    private var eye: some View {
        if mood == .resting {
            ClosedEye()
                .stroke(Color.ink900, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                .frame(width: size * 0.11, height: size * 0.05)
        } else {
            Circle()
                .fill(Color.ink900)
                .frame(width: size * 0.075, height: size * 0.075)
        }
    }

    private var mouth: some View {
        Smile(open: mood == .delighted)
            .stroke(Color.ink900.opacity(0.85), style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
            .frame(width: size * 0.22, height: size * 0.1)
            .offset(y: size * 0.15 + eyeOffsetY / 2)
    }

    private var sparkle: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * 0.32, weight: .semibold))
            .foregroundStyle(Color.gold500)
            .offset(x: size * 0.36, y: -size * 0.42)
    }
}

/// A single closed-eye curve — a shallow upward arc, like "⌣" flipped.
private struct ClosedEye: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

/// The mouth curve — deeper and slightly wider when `open` (delighted mood).
private struct Smile: Shape {
    var open: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        let dip = open ? rect.maxY * 1.5 : rect.maxY
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: dip))
        return path
    }
}

#Preview {
    HStack(spacing: 24) {
        LumenMascot(mood: .calm)
        LumenMascot(mood: .delighted)
        LumenMascot(mood: .resting)
    }
    .padding(40)
    .background(Color.paper)
}
