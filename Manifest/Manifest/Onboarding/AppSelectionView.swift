//
//  AppSelectionView.swift
//  Manifest
//
//  Screen 8/19 — images/screens/08-app-selection.png
//
//  The mockup shows custom-styled category rows with names/icons/counts, but
//  FamilyControls deliberately keeps selected apps/categories opaque to the
//  host app (ApplicationToken/ActivityCategoryToken carry no readable
//  identity) — that's the privacy model, not a gap in this build. The real,
//  honest UI is Apple's own FamilyActivityPicker sheet; this screen wraps it
//  with a summary card built from the token counts we're actually allowed to read.
//

import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    var coordinator: OnboardingCoordinator
    var settings: AppSettings

    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var isScreenTimeAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    @State private var isRequestingScreenTime = false

    private var totalCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    private var footerHint: String {
        if totalCount > 0 {
            return "I'll hold these \(totalCount) selections until you've read"
        }
        if !isScreenTimeAuthorized {
            return "You can pick apps to lock later, once Screen Time is on"
        }
        return "Pick at least one app or category to continue"
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 68)

                Text("What should stay\nclosed?")
                    .font(.newsreader(34))
                    .foregroundStyle(.ink900)
                    .lineSpacing(2)

                Spacer().frame(height: 12)

                Text("Choose whole categories, or pick app by app.")
                    .font(.manrope(15))
                    .foregroundStyle(.slate500)

                Spacer().frame(height: 16)

                if !isScreenTimeAuthorized {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.gold600)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Screen Time is off")
                                .font(.manropeBold(14))
                                .foregroundStyle(.ink900)
                            Text("Your picks are saved, but apps won't actually lock until you enable Screen Time in Settings.")
                                .font(.manrope(13))
                                .foregroundStyle(.slate500)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Button(isRequestingScreenTime ? "Asking\u{2026}" : "Enable Screen Time") {
                                requestScreenTime()
                            }
                            .disabled(isRequestingScreenTime)
                            .font(.manrope(13, weight: .semibold))
                            .foregroundStyle(.accent600)
                        }
                    }
                    .padding(14)
                    .background(Color.gold50)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Spacer().frame(height: 16)

                Button {
                    isPickerPresented = true
                } label: {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.lavender50)
                            .frame(width: 48, height: 48)
                            .overlay(Image(systemName: "apps.iphone").font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.lavender500))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(totalCount > 0 ? "\(totalCount) selected" : "Choose apps & categories")
                                .font(.manropeBold(15.5))
                                .foregroundStyle(.ink900)
                            Text(totalCount > 0 ? "Tap to change your selection" : "Opens Apple's native picker")
                                .font(.manrope(14))
                                .foregroundStyle(.slate500)
                        }

                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.slate300)
                    }
                    .padding(15)
                    .manifestCard()
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(totalCount > 0 ? Color.accent300 : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 8) {
                    LumenMascot(mood: .calm, size: 24)
                    Text(LocalizedStringKey(footerHint))
                        .font(.manrope(13))
                        .foregroundStyle(.slate500)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 12)

                // Without Screen Time, picking apps here can't do anything
                // yet — requiring a selection just to leave this screen would
                // be blocking the user on a choice that doesn't work. They
                // can pick apps later, once Screen Time is actually on.
                PrimaryButton(title: "Continue", isEnabled: totalCount > 0 || !isScreenTimeAuthorized) {
                    settings.familyActivitySelectionData = try? PropertyListEncoder().encode(selection)
                    coordinator.advance()
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
        .onAppear {
            if let data = settings.familyActivitySelectionData,
               let decoded = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
                selection = decoded
            }
            isScreenTimeAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        }
    }

    // Re-calling requestAuthorization reliably re-shows the system consent
    // sheet even after a prior denial — unlike most iOS permissions, there's
    // no discoverable per-app Screen Time toggle in Settings to send users
    // to instead, so retrying in place is the actual working recovery path.
    private func requestScreenTime() {
        isRequestingScreenTime = true
        Task {
            try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isRequestingScreenTime = false
            isScreenTimeAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        }
    }
}

#Preview {
    AppSelectionView(coordinator: OnboardingCoordinator(), settings: AppSettings())
}
