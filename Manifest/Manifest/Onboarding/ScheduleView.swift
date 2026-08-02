//
//  ScheduleView.swift
//  Manifest
//
//  Screen 9/19 — images/screens/09-schedule.png
//

import SwiftUI

private enum DayPreset: String, CaseIterable {
    case everyDay, weekdays, custom

    func label(language: String) -> String {
        let locale = Locale(identifier: language)
        switch self {
        case .everyDay: return String(localized: "Every day", locale: locale)
        case .weekdays: return String(localized: "Weekdays", locale: locale)
        case .custom: return String(localized: "Custom", locale: locale)
        }
    }

    var weekdays: [Int] {
        switch self {
        case .everyDay: Array(1...7)
        case .weekdays: [2, 3, 4, 5, 6]
        case .custom: Array(1...7)
        }
    }
}

struct ScheduleView: View {
    var coordinator: OnboardingCoordinator
    var settings: AppSettings

    @State private var startMinutes: Int
    @State private var endMinutes: Int
    @State private var graceSkipsEnabled: Bool
    @State private var nudgeEnabled: Bool
    @State private var preset: DayPreset = .everyDay

    init(coordinator: OnboardingCoordinator, settings: AppSettings) {
        self.coordinator = coordinator
        self.settings = settings
        _startMinutes = State(initialValue: settings.windowStartMinutes)
        _endMinutes = State(initialValue: settings.windowEndMinutes)
        _graceSkipsEnabled = State(initialValue: settings.graceSkipsPerWeek > 0)
        _nudgeEnabled = State(initialValue: true)
    }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 68)

                Text("When do you\nwant to show up?")
                    .font(.newsreader(34))
                    .foregroundStyle(.ink900)
                    .lineSpacing(2)

                Spacer().frame(height: 22)

                VStack(alignment: .leading, spacing: 14) {
                    Text("RITUAL WINDOW").eyebrowStyle()

                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(formatMinutesAsTime(startMinutes, language: settings.language)).font(.newsreader(37)).foregroundStyle(.ink900)
                        Text("\u{2014}").font(.newsreader(24)).foregroundStyle(.slate400)
                        Text(formatMinutesAsTime(endMinutes, language: settings.language)).font(.newsreader(37)).foregroundStyle(.ink900)
                    }

                    RangeSlider(startMinutes: $startMinutes, endMinutes: $endMinutes)
                        .padding(.vertical, 4)

                    HStack(alignment: .top, spacing: 10) {
                        LumenMascot(mood: .resting, size: 28)
                        Text("Apps lock when the window opens and unlock the moment you finish reading.")
                            .font(.manrope(14))
                            .foregroundStyle(.slate500)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
                .manifestCard()

                Spacer().frame(height: 16)

                VStack(spacing: 0) {
                    toggleRow(title: "Grace skips", subtitle: "2 per week, for the hard mornings", isOn: $graceSkipsEnabled)
                    Divider().padding(.leading, 0)
                    toggleRow(title: "Morning nudge", subtitle: "One notification at \(formatMinutesAsTime(startMinutes, language: settings.language))", isOn: $nudgeEnabled)
                }
                .padding(.vertical, 6)
                .manifestCard()

                Spacer().frame(height: 16)

                HStack(spacing: 10) {
                    ForEach(DayPreset.allCases, id: \.self) { option in
                        let isSelected = preset == option
                        Text(option.label(language: settings.language))
                            .font(.manrope(15, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : .ink900)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? Color.ink900 : Color.paperAlt)
                            .clipShape(Capsule())
                            .onTapGesture { preset = option }
                    }
                }

                Spacer()

                PrimaryButton(title: "Continue") {
                    settings.windowStartMinutes = startMinutes
                    settings.windowEndMinutes = endMinutes
                    settings.graceSkipsPerWeek = graceSkipsEnabled ? 2 : 0
                    settings.activeWeekdays = preset.weekdays
                    coordinator.advance()
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(title)).font(.manropeBold(15.5)).foregroundStyle(.ink900)
                Text(LocalizedStringKey(subtitle)).font(.manrope(13.5)).foregroundStyle(.slate500)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(.accent500)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

#Preview {
    ScheduleView(coordinator: OnboardingCoordinator(), settings: AppSettings())
}
