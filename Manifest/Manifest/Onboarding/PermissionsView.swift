//
//  PermissionsView.swift
//  Manifest
//
//  Screen 4/19 — images/screens/04-permissions.png
//

import SwiftUI
import FamilyControls

struct PermissionsView: View {
    var coordinator: OnboardingCoordinator
    @Bindable var settings: AppSettings

    @Environment(\.scenePhase) private var scenePhase
    @State private var authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    @State private var didAttemptRequest = false
    @State private var isRequesting = false
    @State private var showWhyAlert = false

    // A real denial reliably lands on .denied, but a request that fails for
    // any other reason (Simulator has no Family Controls support at all, so
    // it throws without ever moving off .notDetermined) still means "not
    // authorized" — either way, once an attempt has happened, don't sit on
    // a button that will just silently fail again.
    private var showDeniedState: Bool {
        (didAttemptRequest || authorizationStatus == .denied) && authorizationStatus != .approved
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 68)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.lavender50)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Color.lavender500)
                    )

                Spacer().frame(height: 20)

                Text("Two permissions,\nthen you're set")
                    .font(.newsreader(34))
                    .foregroundStyle(.ink900)
                    .lineSpacing(2)

                Spacer().frame(height: 24)

                VStack(spacing: 14) {
                    permissionRow(
                        title: "Screen Time access",
                        badge: "Required",
                        badgeBackground: .gold50,
                        badgeForeground: .gold600,
                        body: "Lets Manifest hold your chosen apps closed until the ritual is done. Apple keeps the selection private — even we can't see it."
                    )
                    permissionRow(
                        title: "Notifications",
                        badge: "Optional",
                        badgeBackground: Color.slate300.opacity(0.25),
                        badgeForeground: .slate500,
                        body: "One gentle nudge when your window opens. Nothing else, ever."
                    )
                    ambientSoundRow
                }

                Spacer().frame(height: 14)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.accent600)
                    Text("No account, no cloud. Your goals never leave the device.")
                        .font(.manrope(14))
                        .foregroundStyle(.ink900.opacity(0.75))
                        .lineSpacing(3)
                }
                .padding(16)
                .background(Color.accent50)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer()

                if showDeniedState {
                    deniedState
                } else {
                    PrimaryButton(
                        title: authorizationStatus == .approved ? "Continue" : "Allow Screen Time",
                        isEnabled: !isRequesting
                    ) {
                        if authorizationStatus == .approved {
                            coordinator.advance()
                        } else {
                            requestScreenTime()
                        }
                    }

                    Spacer().frame(height: 14)

                    Button {
                        showWhyAlert = true
                    } label: {
                        Text("Why is this needed?")
                            .font(.manrope(14))
                            .foregroundStyle(.slate500)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 12)
                }
            }
            .padding(.horizontal, 24)
        }
        .alert("Why Screen Time?", isPresented: $showWhyAlert) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Manifest uses Apple's on-device Screen Time API to hold your chosen apps closed until you've completed the daily ritual. Your selection never leaves your iPhone.")
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Catches coming back from Settings after enabling it there.
            if newPhase == .active {
                authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            }
        }
        // Fire-and-forget, matching the "Optional" badge above — this asks
        // once via the system's own dialog and never blocks advancing.
        .task {
            await NotificationScheduler.requestAuthorization()
        }
    }

    /// Shown after a denial — but never a dead end. Unlike most iOS
    /// permissions, re-calling requestAuthorization reliably re-shows the
    /// system consent sheet even after a prior denial (Settings has no
    /// discoverable per-app toggle for this one, so "Open Settings" was a
    /// dead link — "Try again" is the actual working recovery path). Since
    /// blocking apps isn't Manifest's only value, continuing without it is a
    /// real, first-class option here, not a buried afterthought.
    private var deniedState: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                LumenMascot(mood: .resting, size: 28)
                Text("Screen Time isn't on, so Manifest can't lock your apps yet — but you can still do your daily ritual without that part.")
                    .font(.manrope(14))
                    .foregroundStyle(.ink900.opacity(0.8))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.gold50)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            PrimaryButton(title: "Try again", isEnabled: !isRequesting) {
                requestScreenTime()
            }

            Button {
                Analytics.track("screen_time_skipped")
                coordinator.advance()
            } label: {
                Text("Continue without blocking apps")
                    .font(.manropeBold(15.5))
                    .foregroundStyle(.ink900)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.slate300.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Or check Settings \u{2192} Screen Time")
                    .font(.manrope(13))
                    .foregroundStyle(.slate500)
            }
        }
        .padding(.bottom, 12)
    }

    private func permissionRow(
        title: String,
        badge: String,
        badgeBackground: Color,
        badgeForeground: Color,
        body: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedStringKey(title))
                    .font(.manropeBold(15.5))
                    .foregroundStyle(.ink900)
                Spacer()
                Text(LocalizedStringKey(badge))
                    .font(.manrope(12.5, weight: .semibold))
                    .foregroundStyle(badgeForeground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(badgeBackground)
                    .clipShape(Capsule())
            }
            Text(LocalizedStringKey(body))
                .font(.manrope(14))
                .foregroundStyle(.slate500)
                .lineSpacing(3)
        }
        .padding(16)
        .manifestCard()
    }

    /// Unlike the two rows above, this is a real toggle, not just
    /// informational — you can turn it off right here, before your first
    /// ritual, instead of only discovering it later in Settings.
    private var ambientSoundRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Ambient sound")
                    .font(.manropeBold(15.5))
                    .foregroundStyle(.ink900)
                Text("Plays softly during the ritual")
                    .font(.manrope(14))
                    .foregroundStyle(.slate500)
            }
            Spacer()
            Toggle("", isOn: $settings.ambientSoundEnabled).labelsHidden().tint(.accent500)
        }
        .padding(16)
        .manifestCard()
    }

    private func requestScreenTime() {
        isRequesting = true
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                // Simulator has no Family Controls support — requesting
                // always throws there, which correctly lands on .denied
                // below so the flow stays visually testable.
                print("[Permissions] Screen Time authorization failed: \(error)")
            }
            isRequesting = false
            didAttemptRequest = true
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            Analytics.track(authorizationStatus == .approved ? "screen_time_authorized" : "screen_time_denied")
            if authorizationStatus == .approved {
                coordinator.advance()
            }
            // If denied, stay put — deniedState takes over and the user
            // decides: fix it in Settings, or explicitly skip for now.
        }
    }
}

#Preview {
    PermissionsView(coordinator: OnboardingCoordinator(), settings: AppSettings())
}
