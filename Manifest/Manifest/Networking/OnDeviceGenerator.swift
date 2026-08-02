//
//  OnDeviceGenerator.swift
//  Manifest
//
//  Generates daily scripts using Apple's on-device FoundationModels (Apple
//  Intelligence) — free, private, no network. Only usable on Apple
//  Intelligence-capable hardware with it enabled; AIService decides whether
//  to use this or fall back to the Worker. Goal creation (content-safety
//  check + reflection) is Worker-only — that moderation logic lives there.
//

import Foundation
import FoundationModels

enum OnDeviceGenerator {
    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    @Generable
    struct ScriptOutput {
        @Guide(description: "Exactly three short affirmation lines for the ritual, each one sentence, speakable in a single breath, varied in phrasing")
        var lines: [String]
    }

    static func dailyScript(goal: String, style: ManifestationStyle, language: String, dayNumber: Int) async throws -> [String] {
        let session = LanguageModelSession(instructions: Self.systemInstructions)
        let prompt = """
        Goal: "\(goal)". This is day \(dayNumber) of the user's daily ritual for this goal.
        Manifestation style: \(Self.styleBrief(style))
        \(Self.languageInstruction(language))
        Vary the imagery and wording from a typical day so it doesn't feel repeated — but every \
        line, without exception, stays in the already-true present tense described above.
        """
        let response = try await session.respond(to: prompt, generating: ScriptOutput.self)
        return response.content.lines
    }

    private static let systemInstructions = """
    You are Lumen, the calm guide inside the Manifest app. You help people turn a goal into a \
    daily mindset practice. Keep responses warm, grounded, and concise — never saccharine or \
    preachy, never use emoji, never use clichés.
    """

    // Kept in sync with worker/src/prompts.ts's PRESENT_TENSE_RULE — every
    // line must read as literally, presently true, never a hope or a plan.
    private static let presentTenseRule = """
    Every line must be spoken as if the goal is already fully real, right now — not approaching, \
    not in progress, not intended. Apply this test to each line before writing it: if it can't be \
    said with a straight face as a true statement about this exact moment, rewrite it. \
    Never use future tense, "will", "going to", "soon", "someday", "working toward", \
    "on my way to", "hope to", "trying to", or conditionals like "if" or "when I". \
    Do not describe the goal as a destination being approached — describe the arrived reality: \
    how it looks, feels, and functions now that it's done. \
    Bad: "I will launch my studio and it will succeed." \
    Good: "My studio is open. My work is already in people's hands."
    """

    private static func styleBrief(_ style: ManifestationStyle) -> String {
        switch style {
        case .present:
            "Present-tense manifestation: first-person statements declaring the goal as already accomplished fact (e.g. \"I am...\", \"My studio is open\"). \(presentTenseRule)"
        case .water:
            "Water-charging ritual: statements spoken over a glass of water before drinking it, infusing the water with intention. Warmer, more sensory language, but still first person and still describing the goal as already true. \(presentTenseRule)"
        case .threeSixNine:
            "369 method: a single, potent affirmation line meant to be handwritten 3 times in the morning, 6 times in the afternoon, and 9 times at night. Short enough to write by hand quickly and repeatedly. Plainer and more declarative than the other styles. \(presentTenseRule)"
        }
    }

    private static func languageInstruction(_ language: String) -> String {
        "Write entirely in \(language), using natural, fluent, culturally appropriate phrasing for a native speaker."
    }
}
