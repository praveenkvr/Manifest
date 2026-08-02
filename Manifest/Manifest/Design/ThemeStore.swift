//
//  ThemeStore.swift
//  Manifest
//
//  Color+Palette.swift's `.accent*` tokens are zero-argument static
//  properties (needed so every existing `.foregroundStyle(.accent500)` call
//  site across the app keeps working unchanged) — they can't take an
//  AppSettings parameter directly, so this is the live mirror they read
//  from instead. RootView keeps it in sync with settings.accentTheme.
//

import Observation

@Observable
final class ThemeStore {
    static let shared = ThemeStore()
    var current: AccentTheme = .jade

    private init() {}
}
