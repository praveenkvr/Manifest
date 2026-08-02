//
//  RitualLog.swift
//  Manifest
//
//  One row per calendar day the ritual window was reached — feeds the streak
//  pill and the Journey consistency grid.
//

import Foundation
import SwiftData

@Model
final class RitualLog {
    var date: Date
    var completed: Bool
    var skipped: Bool
    var linesRead: Int
    var totalLines: Int
    var graceSkipUsed: Bool

    init(
        date: Date,
        completed: Bool = false,
        skipped: Bool = false,
        linesRead: Int = 0,
        totalLines: Int = 0,
        graceSkipUsed: Bool = false
    ) {
        self.date = date
        self.completed = completed
        self.skipped = skipped
        self.linesRead = linesRead
        self.totalLines = totalLines
        self.graceSkipUsed = graceSkipUsed
    }
}
