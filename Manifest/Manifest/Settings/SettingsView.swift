//
//  SettingsView.swift
//  Manifest
//
//  Screen 19/19 — images/screens/19-settings.png
//
//  Ambient sound plays via AmbientAudioPlayer (procedurally generated white/
//  brown noise, not bundled audio files — see that file's header for why).
//  Subscription status comes from RevenueCat rather than being hardcoded,
//  per the design's "no fabricated numbers" spirit.
//
//  "Language" drives both the AI content language (settings.language, sent
//  to the Worker on every /v1/reflect and /v1/daily-script call) and the
//  app's own UI chrome, via .environment(\.locale) applied at RootView —
//  overriding the device's system language, not just following it.
//

import SwiftUI
import SwiftData
import FamilyControls
import RevenueCat

private struct LanguageOption: Identifiable {
    let code: String
    let name: String
    let flag: String
    var id: String { code }
}

private let languageOptions: [LanguageOption] = [
    .init(code: "en", name: "English", flag: "\u{1F1FA}\u{1F1F8}"),
    .init(code: "es", name: "Español", flag: "\u{1F1EA}\u{1F1F8}"),
    .init(code: "fr", name: "Français", flag: "\u{1F1EB}\u{1F1F7}"),
    .init(code: "de", name: "Deutsch", flag: "\u{1F1E9}\u{1F1EA}"),
    .init(code: "pt", name: "Português", flag: "\u{1F1F5}\u{1F1F9}"),
    .init(code: "it", name: "Italiano", flag: "\u{1F1EE}\u{1F1F9}"),
    .init(code: "ja", name: "日本語", flag: "\u{1F1EF}\u{1F1F5}"),
    .init(code: "ko", name: "한국어", flag: "\u{1F1F0}\u{1F1F7}"),
    .init(code: "zh", name: "中文", flag: "\u{1F1E8}\u{1F1F3}"),
    .init(code: "hi", name: "हिन्दी", flag: "\u{1F1EE}\u{1F1F3}"),
    .init(code: "ar", name: "العربية", flag: "\u{1F1F8}\u{1F1E6}"),
    .init(code: "ru", name: "Русский", flag: "\u{1F1F7}\u{1F1FA}"),
]

struct SettingsView: View {
    @Bindable var settings: AppSettings

    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @State private var subscriptionSummary = "Checking..."
    @State private var managementURL: URL?
    @State private var showAppPicker = false
    @State private var selection = FamilyActivitySelection()
    @State private var showStylePicker = false
    @State private var showColorThemePicker = false
    @State private var showAmbientSoundPicker = false
    @State private var previewingSound: AmbientSoundOption?
    @State private var showLanguagePicker = false
    @State private var showWindowPicker = false
    @State private var backupURL: URL?
    @State private var isScreenTimeAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    @State private var isRequestingScreenTime = false
    @State private var showPaywall = false

    private var isSubscribed: Bool { EntitlementStore.shared.isSubscribed }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Settings").font(.newsreader(30)).foregroundStyle(.textPrimary)

                    subscriptionRow

                    VStack(spacing: 0) {
                        toggleRow(title: "Dark theme", subtitle: "Follows your ritual mood", isOn: Binding(
                            get: { settings.theme == .dark },
                            set: {
                                settings.theme = $0 ? .dark : .light
                                Analytics.track("settings_dark_theme_toggled", ["enabled": $0])
                            }
                        ))
                        Divider()
                        navRow(title: "Default style", value: settings.defaultStyle.displayName(language: settings.language)) {
                            showStylePicker = true
                        }
                        Divider()
                        navRow(title: "Color theme", value: settings.accentTheme.displayName(language: settings.language)) {
                            showColorThemePicker = true
                        }
                        Divider()
                        navRow(title: "Language", value: currentLanguageName) { showLanguagePicker = true }
                    }
                    .manifestCard(adaptive: true)

                    VStack(spacing: 0) {
                        if !isScreenTimeAuthorized {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Screen Time is off").font(.manropeBold(15.5)).foregroundStyle(.textPrimary)
                                    Text("Turn it on to lock apps during your ritual").font(.manrope(13.5)).foregroundStyle(.textSecondary)
                                }
                                Spacer()
                                Button(isRequestingScreenTime ? "Asking\u{2026}" : "Enable") {
                                    requestScreenTime()
                                }
                                .disabled(isRequestingScreenTime)
                                .font(.manrope(14, weight: .semibold))
                                .foregroundStyle(.accent600)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            Divider()
                        }
                        navRow(title: "Blocked apps", value: selectedCountText(lockedCount)) { showAppPicker = true }
                        Divider()
                        navRow(title: "Ritual window", value: "\(formatMinutesAsTime(settings.windowStartMinutes, language: settings.language)) \u{2013} \(formatMinutesAsTime(settings.windowEndMinutes, language: settings.language))") {
                            showWindowPicker = true
                        }
                        Divider()
                        toggleRow(title: "Lock all day until done", subtitle: "Stay locked past the window, not just during it", isOn: Binding(
                            get: { settings.lockAllDayUntilDone },
                            set: {
                                settings.lockAllDayUntilDone = $0
                                Analytics.track("settings_lock_all_day_toggled", ["enabled": $0])
                            }
                        ))
                        Divider()
                        toggleRow(title: "Grace skips", subtitle: perWeekText(settings.graceSkipsPerWeek), isOn: Binding(
                            get: { settings.graceSkipsPerWeek > 0 },
                            set: { settings.graceSkipsPerWeek = $0 ? 2 : 0 }
                        ))
                    }
                    .manifestCard(adaptive: true)

                    VStack(spacing: 0) {
                        toggleRow(title: "Ambient sound", subtitle: "Plays softly during the ritual", isOn: Binding(
                            get: { settings.ambientSoundEnabled },
                            set: {
                                settings.ambientSoundEnabled = $0
                                Analytics.track("settings_ambient_sound_toggled", ["enabled": $0])
                            }
                        ))
                        if settings.ambientSoundEnabled {
                            Divider()
                            navRow(title: "Sound", value: settings.ambientSoundOption.displayName(language: settings.language)) {
                                showAmbientSoundPicker = true
                            }
                        }
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Local backup").font(.manropeBold(15.5)).foregroundStyle(.textPrimary)
                                Text("Export your goals as a JSON file").font(.manrope(13.5)).foregroundStyle(.textSecondary)
                            }
                            Spacer()
                            if let backupURL {
                                ShareLink(item: backupURL) {
                                    Image(systemName: "square.and.arrow.up").foregroundStyle(.accent500)
                                }
                            } else {
                                Button { exportBackup() } label: {
                                    Image(systemName: "square.and.arrow.up").foregroundStyle(.accent500)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                    .manifestCard(adaptive: true)

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.shield").foregroundStyle(.accent600)
                        Text("No account, no cloud sync. Everything lives on this iPhone.")
                            .font(.manrope(13.5))
                            .foregroundStyle(.ink900.opacity(0.75))
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .background(Color.accent50)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.top, 68)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar(.hidden)
        }
        .familyActivityPicker(isPresented: $showAppPicker, selection: $selection)
        .onChange(of: selection) { _, newValue in
            settings.familyActivitySelectionData = try? PropertyListEncoder().encode(newValue)
        }
        .sheet(isPresented: $showStylePicker) {
            styleSheet
        }
        .sheet(isPresented: $showColorThemePicker) {
            colorThemeSheet
        }
        .sheet(isPresented: $showAmbientSoundPicker) {
            ambientSoundSheet
        }
        .sheet(isPresented: $showLanguagePicker) {
            languageSheet
        }
        .sheet(isPresented: $showWindowPicker) {
            windowSheet
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(settings: settings, source: "settings") { showPaywall = false }
        }
        .task {
            await loadSubscriptionStatus()
            if let data = settings.familyActivitySelectionData,
               let decoded = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
                selection = decoded
            }
            isScreenTimeAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        }
    }

    // Re-calling requestAuthorization reliably re-shows the system consent
    // sheet even after a prior denial — there's no discoverable per-app
    // Screen Time toggle in Settings to send users to instead.
    private func requestScreenTime() {
        isRequestingScreenTime = true
        Task {
            try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isRequestingScreenTime = false
            isScreenTimeAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        }
    }

    private var lockedCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count
    }

    private var subscriptionRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                RoadMarkGlyph(size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(subscriptionSummary).font(.manropeBold(15.5)).foregroundStyle(.textPrimary)
                    Text(isSubscribed ? "Manage subscription" : "Subscribe to unlock Manifest")
                        .font(.manrope(13.5))
                        .foregroundStyle(isSubscribed ? .textSecondary : .accent600)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(.slate300)
            }
            .padding(15)
            .contentShape(Rectangle())
            .onTapGesture {
                if isSubscribed {
                    if let managementURL {
                        UIApplication.shared.open(managementURL)
                    }
                } else {
                    showPaywall = true
                }
            }

            // Purchases restore by App Store account, not by device — and
            // this app has no login system to otherwise link a new device
            // back to a past purchase, so this needs to be reachable without
            // going through the full paywall first (matters for every plan,
            // not just lifetime).
            if !isSubscribed {
                Divider().padding(.horizontal, 15)
                Button {
                    Task {
                        if let info = try? await Purchases.shared.restorePurchases() {
                            await EntitlementStore.shared.apply(info)
                        }
                        await loadSubscriptionStatus()
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.manrope(14, weight: .semibold))
                        .foregroundStyle(.accent600)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .manifestCard(adaptive: true)
    }

    private var styleSheet: some View {
        VStack(spacing: 14) {
            Text("Default style").font(.newsreader(25)).foregroundStyle(.textPrimary)
            Text("Pre-fills the style when you start a new manifestation \u{2014} you can still change it per goal.")
                .font(.manrope(13.5))
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            ForEach(ManifestationStyle.allCases, id: \.self) { style in
                Button {
                    settings.defaultStyle = style
                    Analytics.track("settings_default_style_changed", ["style": style.rawValue])
                    showStylePicker = false
                } label: {
                    HStack {
                        Text(style.displayName(language: settings.language))
                            .font(.manropeBold(15.5))
                            .foregroundStyle(.textPrimary)
                        Spacer()
                        if settings.defaultStyle == style {
                            Image(systemName: "checkmark").foregroundStyle(.accent500)
                        }
                    }
                    .padding(16)
                    .manifestCard(adaptive: true)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
    }

    private var ambientSoundSheet: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Sound").font(.newsreader(25)).foregroundStyle(.textPrimary)
                Text("Plays softly in the background during your ritual. \u{201C}Random\u{201D} picks a different one each session.")
                    .font(.manrope(13.5))
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                ForEach(AmbientSoundOption.allCases) { option in
                    HStack(spacing: 12) {
                        Button {
                            settings.ambientSoundOption = option
                            Analytics.track("settings_ambient_sound_changed", ["option": option.rawValue])
                            showAmbientSoundPicker = false
                        } label: {
                            HStack {
                                Text(option.displayName(language: settings.language))
                                    .font(.manropeBold(15.5))
                                    .foregroundStyle(.textPrimary)
                                Spacer()
                                if settings.ambientSoundOption == option {
                                    Image(systemName: "checkmark").foregroundStyle(.accent500)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if option != .random {
                            AmbientSoundPreviewButton(option: option, previewing: $previewingSound)
                        }
                    }
                    .padding(16)
                    .manifestCard(adaptive: true)
                }

                Text("Music by Kevin MacLeod (incompetech.com), licensed under Creative Commons: By Attribution 3.0")
                    .font(.manrope(11))
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
        .onDisappear { AmbientAudioPlayer.shared.stop(); previewingSound = nil }
    }

    private var colorThemeSheet: some View {
        VStack(spacing: 14) {
            Text("Color theme").font(.newsreader(25)).foregroundStyle(.textPrimary)
            Text("Changes the app's accent color everywhere \u{2014} buttons, progress, the ritual and paywall backgrounds.")
                .font(.manrope(13.5))
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            ForEach(AccentTheme.allCases) { theme in
                Button {
                    settings.accentTheme = theme
                    Analytics.track("settings_color_theme_changed", ["theme": theme.rawValue])
                    showColorThemePicker = false
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(LinearGradient(colors: [theme.c300, theme.c500], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 24, height: 24)
                        Text(theme.displayName(language: settings.language))
                            .font(.manropeBold(15.5))
                            .foregroundStyle(.textPrimary)
                        Spacer()
                        if settings.accentTheme == theme {
                            Image(systemName: "checkmark").foregroundStyle(theme.c500)
                        }
                    }
                    .padding(16)
                    .manifestCard(adaptive: true)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
    }

    private var currentLanguageName: String {
        guard let option = languageOptions.first(where: { $0.code == settings.language }) else {
            return settings.language
        }
        return "\(option.flag) \(option.name)"
    }

    private var languageSheet: some View {
        VStack(spacing: 14) {
            Text("Ritual language").font(.newsreader(25)).foregroundStyle(.textPrimary)
            Text("Changes both the app's language and your AI-generated reflections and daily scripts.")
                .font(.manrope(13.5))
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(languageOptions) { option in
                        Button {
                            settings.language = option.code
                            Analytics.track("settings_language_changed", ["language": option.code])
                            showLanguagePicker = false
                        } label: {
                            HStack(spacing: 12) {
                                Text(option.flag).font(.system(size: 24))
                                Text(option.name).font(.manropeBold(15.5)).foregroundStyle(.textPrimary)
                                Spacer()
                                if settings.language == option.code {
                                    Image(systemName: "checkmark").foregroundStyle(.accent500)
                                }
                            }
                            .padding(16)
                            .manifestCard(adaptive: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(24)
        .presentationDetents([.large])
    }

    private var windowSheet: some View {
        VStack(spacing: 18) {
            Text("Ritual window").font(.newsreader(25)).foregroundStyle(.textPrimary)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(formatMinutesAsTime(settings.windowStartMinutes, language: settings.language)).font(.newsreader(34)).foregroundStyle(.textPrimary)
                Text("\u{2014}").font(.newsreader(22)).foregroundStyle(.textSecondary)
                Text(formatMinutesAsTime(settings.windowEndMinutes, language: settings.language)).font(.newsreader(34)).foregroundStyle(.textPrimary)
            }

            RangeSlider(
                startMinutes: Binding(get: { settings.windowStartMinutes }, set: { settings.windowStartMinutes = $0 }),
                endMinutes: Binding(get: { settings.windowEndMinutes }, set: { settings.windowEndMinutes = $0 })
            )
            .padding(.horizontal, 12)

            Spacer()

            PrimaryButton(title: "Done") {
                NotificationScheduler.reschedule(settings: settings, activeGoals: goals.filter { $0.fulfilledAt == nil })
                showWindowPicker = false
            }
        }
        .padding(24)
        .presentationDetents([.medium])
    }

    // Wrapping an already-interpolated String (e.g. "2 per week") in
    // LocalizedStringKey can't match a catalog key stored as a format
    // string ("%lld per week") — the resolved number breaks the lookup.
    // String(localized:locale:) also turned out not to resolve % keys
    // reliably when hand-authored into the catalog (likely needs Xcode's
    // own substitution metadata, which a manually-edited .xcstrings entry
    // doesn't have) — a small hardcoded table sidesteps that entirely.
    private func perWeekText(_ count: Int) -> String {
        let templates = [
            "en": "%d per week", "es": "%d por semana", "fr": "%d par semaine", "de": "%d pro Woche",
            "pt": "%d por semana", "it": "%d a settimana", "ja": "週%d回", "ko": "주 %d회",
            "zh": "每周%d次", "hi": "%d प्रति सप्ताह", "ar": "%d في الأسبوع", "ru": "%d в неделю",
        ]
        let template = templates[settings.language] ?? templates["en"]!
        return template.replacingOccurrences(of: "%d", with: "\(count)")
    }

    private func selectedCountText(_ count: Int) -> String {
        let templates = [
            "en": "%d selected", "es": "%d seleccionadas", "fr": "%d sélectionnées", "de": "%d ausgewählt",
            "pt": "%d selecionados", "it": "%d selezionate", "ja": "%d件選択中", "ko": "%d개 선택됨",
            "zh": "已选择%d个", "hi": "%d चयनित", "ar": "%d محدد", "ru": "Выбрано: %d",
        ]
        let template = templates[settings.language] ?? templates["en"]!
        return template.replacingOccurrences(of: "%d", with: "\(count)")
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(title)).font(.manropeBold(15.5)).foregroundStyle(.textPrimary)
                Text(LocalizedStringKey(subtitle)).font(.manrope(13.5)).foregroundStyle(.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(.accent500)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func navRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(LocalizedStringKey(title)).font(.manropeBold(15.5)).foregroundStyle(.textPrimary)
                Spacer()
                Text(LocalizedStringKey(value)).font(.manrope(14)).foregroundStyle(.textSecondary)
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(.slate300)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // String(localized:locale:) proved unreliable for hand-authored catalog
    // entries in testing (some resolved correctly, some silently fell back
    // to English with no error) — small hardcoded tables sidestep it
    // entirely, same as perWeekText/selectedCountText above.
    private func notSubscribedText() -> String {
        let table = [
            "en": "Not subscribed", "es": "No suscrito", "fr": "Non abonné", "de": "Kein Abo",
            "pt": "Não assinante", "it": "Non abbonato", "ja": "未購読", "ko": "구독 안 함",
            "zh": "未订阅", "hi": "सब्सक्राइब नहीं है", "ar": "غير مشترك", "ru": "Без подписки",
        ]
        return table[settings.language] ?? table["en"]!
    }

    private func activeLifetimeText() -> String {
        let table = [
            "en": "Active \u{00B7} lifetime", "es": "Activa \u{00B7} de por vida", "fr": "Actif \u{00B7} à vie", "de": "Aktiv \u{00B7} lebenslang",
            "pt": "Ativo \u{00B7} vitalício", "it": "Attivo \u{00B7} a vita", "ja": "有効・永久", "ko": "활성 \u{00B7} 평생",
            "zh": "有效·终身", "hi": "सक्रिय \u{00B7} आजीवन", "ar": "نشط \u{00B7} مدى الحياة", "ru": "Активна \u{00B7} пожизненно",
        ]
        return table[settings.language] ?? table["en"]!
    }

    private func activeRenewsText() -> String {
        let table = [
            "en": "Active \u{00B7} renews", "es": "Activa \u{00B7} se renueva", "fr": "Actif \u{00B7} se renouvelle", "de": "Aktiv \u{00B7} verlängert sich",
            "pt": "Ativo \u{00B7} renova", "it": "Attivo \u{00B7} si rinnova", "ja": "有効・更新日", "ko": "활성 \u{00B7} 갱신일",
            "zh": "有效·续订于", "hi": "सक्रिय \u{00B7} नवीनीकरण", "ar": "نشط \u{00B7} يتجدد", "ru": "Активна \u{00B7} продление",
        ]
        return table[settings.language] ?? table["en"]!
    }

    private func loadSubscriptionStatus() async {
        guard Purchases.isConfigured else {
            subscriptionSummary = notSubscribedText()
            return
        }
        do {
            let info = try await Purchases.shared.customerInfo()
            managementURL = info.managementURL
            if let entitlement = info.entitlements.active.values.first {
                if let expiration = entitlement.expirationDate {
                    subscriptionSummary = "\(activeRenewsText()) \(expiration.formatted(date: .abbreviated, time: .omitted))"
                } else {
                    subscriptionSummary = activeLifetimeText()
                }
            } else {
                subscriptionSummary = notSubscribedText()
            }
        } catch {
            print("[Settings] Failed to load subscription status: \(error)")
            subscriptionSummary = notSubscribedText()
        }
    }

    private struct GoalBackup: Codable {
        var text: String
        var category: String
        var style: String
        var createdAt: Date
        var fulfilledAt: Date?
        var notes: String
    }

    private func exportBackup() {
        let snapshot = goals.map {
            GoalBackup(text: $0.text, category: $0.category.rawValue, style: $0.style.rawValue,
                       createdAt: $0.createdAt, fulfilledAt: $0.fulfilledAt, notes: $0.notes)
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(snapshot) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("manifest-backup.json")
        try? data.write(to: url)
        backupURL = url
    }
}

#Preview {
    SettingsView(settings: AppSettings())
        .modelContainer(for: Goal.self, inMemory: true)
}
