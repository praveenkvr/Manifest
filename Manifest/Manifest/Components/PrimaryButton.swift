//
//  PrimaryButton.swift
//  Manifest
//
//  Full-width accent CTA — 52-56pt tall, press = scale 0.98, per the design spec.
//

import SwiftUI

struct PrimaryButton: View {
    var title: String
    var isEnabled: Bool = true
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            // `title` is a String parameter, not a literal — Text(String)
            // renders verbatim and skips catalog lookup entirely. Wrapping
            // it as a LocalizedStringKey forces the same runtime lookup a
            // literal Text("...") would get, so translations actually apply
            // to every screen that uses this button (nearly all of them).
            Text(LocalizedStringKey(title))
                .font(.manropeBold(17))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? Color.accent500 : Color.slate300)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(hex: 0x0C8168).opacity(isEnabled ? 0.28 : 0), radius: 11, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.easeOut(duration: 0.12), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Begin") {}
        PrimaryButton(title: "Disabled", isEnabled: false) {}
    }
    .padding(24)
    .background(Color.paper)
}
