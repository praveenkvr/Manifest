//
//  RitualFlowView.swift
//  Manifest
//
//  Small coordinator wrapping the reading -> sign-off sequence presented
//  full-screen from Home.
//

import SwiftUI

struct RitualFlowView: View {
    var settings: AppSettings
    var goals: [Goal]

    @Environment(\.dismiss) private var dismiss
    @State private var isComplete = false

    var body: some View {
        if isComplete {
            SignOffView(settings: settings) { dismiss() }
        } else {
            RitualReadingView(
                settings: settings,
                goals: goals,
                onComplete: { isComplete = true },
                onDismiss: { dismiss() }
            )
        }
    }
}
