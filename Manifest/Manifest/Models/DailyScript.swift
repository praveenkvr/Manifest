//
//  DailyScript.swift
//  Manifest
//
//  One AI-generated ritual script per goal per active day, fetched on-demand
//  and cached here — this is what makes the Worker call "once per active day"
//  instead of once per app open.
//

import Foundation
import SwiftData

@Model
final class DailyScript {
    var goalID: UUID
    /// Start-of-day the script was generated for (device-local calendar day).
    var date: Date
    var style: ManifestationStyle
    var language: String
    var lines: [String]
    var fetchedAt: Date

    init(
        goalID: UUID,
        date: Date,
        style: ManifestationStyle,
        language: String,
        lines: [String],
        fetchedAt: Date = .now
    ) {
        self.goalID = goalID
        self.date = date
        self.style = style
        self.language = language
        self.lines = lines
        self.fetchedAt = fetchedAt
    }
}
