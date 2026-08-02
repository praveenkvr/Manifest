//
//  PageDots.swift
//  Manifest
//
//  3-dot onboarding pager — active dot stretches into a pill.
//

import SwiftUI

struct PageDots: View {
    var count: Int
    var activeIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == activeIndex ? Color.accent500 : Color.slate300.opacity(0.5))
                    .frame(width: index == activeIndex ? 20 : 6, height: 6)
            }
        }
        .animation(.easeOut(duration: 0.15), value: activeIndex)
    }
}

#Preview {
    PageDots(count: 3, activeIndex: 0)
        .padding(24)
        .background(Color.paper)
}
