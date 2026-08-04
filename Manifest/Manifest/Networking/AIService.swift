//
//  AIService.swift
//  Manifest
//
//  Single entry point the app calls for AI generation. checkGoal (content
//  safety + reflection) and suggestPhrasing always go through the Worker —
//  the moderation logic lives there. dailyScript prefers on-device Apple
//  Intelligence when available, falling back to the Worker.
//

import Foundation

enum AIService {
    // Parked for now — on-device generation is built and verified (see
    // OnDeviceGenerator) but disabled while the Worker is the sole focus.
    // Flip this back to `OnDeviceGenerator.isAvailable` to re-enable.
    private static let onDeviceEnabled = false

    static func checkGoal(goal: String, style: ManifestationStyle, language: String) async throws -> GoalCheckResult {
        try await WorkerClient.checkGoal(goal: goal, style: style, language: language)
    }

    static func suggestPhrasing(goal: String, language: String) async throws -> [String] {
        try await WorkerClient.suggestPhrasing(goal: goal, language: language)
    }

    static func dailyScript(
        goal: String,
        style: ManifestationStyle,
        language: String,
        dayNumber: Int,
        recentLines: [String] = []
    ) async throws -> [String] {
        if onDeviceEnabled && OnDeviceGenerator.isAvailable {
            do {
                return try await OnDeviceGenerator.dailyScript(goal: goal, style: style, language: language, dayNumber: dayNumber)
            } catch {
                print("[AIService] On-device dailyScript failed, falling back to Worker: \(error)")
            }
        }
        return try await WorkerClient.dailyScript(goal: goal, style: style, language: language, dayNumber: dayNumber, recentLines: recentLines)
    }
}
