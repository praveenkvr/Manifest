//
//  WorkerClient.swift
//  Manifest
//
//  Talks to the Cloudflare Worker — the only place Gemini/OpenAI keys live.
//  Never call an AI provider directly from the app. The shared secret is
//  injected at build time via Config.xcconfig (gitignored) -> Info.plist ->
//  here, so it's never hardcoded in tracked source.
//

import Foundation

enum WorkerClientError: Error {
    case missingSharedSecret
    case invalidResponse
    case server(status: Int, body: String)
}

enum GoalCheckResult {
    case allowed(reflection: String, sampleLines: [String])
    case blocked(reason: String)
}

enum WorkerClient {
    static let baseURL = URL(string: "https://manifest-worker.praveen-kuruvada.workers.dev")!

    private static var sharedSecret: String {
        Bundle.main.object(forInfoDictionaryKey: "ManifestSharedSecret") as? String ?? ""
    }

    /// Doubles as the content-safety check — every goal goes through this
    /// before it's ever saved. Costs one call whether allowed or blocked.
    static func checkGoal(goal: String, style: ManifestationStyle, language: String) async throws -> GoalCheckResult {
        let json = try await send(path: "v1/reflect", body: [
            "goal": goal,
            "style": style.rawValue,
            "language": language,
        ])
        guard let allowed = json["allowed"] as? Bool else { throw WorkerClientError.invalidResponse }
        if allowed {
            guard let reflection = json["reflection"] as? String else { throw WorkerClientError.invalidResponse }
            let sampleLines = json["sampleLines"] as? [String] ?? []
            return .allowed(reflection: reflection, sampleLines: sampleLines)
        } else {
            let reason = json["reason"] as? String
                ?? "This goal isn't something Manifest can help with — try reframing it toward something positive for yourself."
            return .blocked(reason: reason)
        }
    }

    /// On-demand only — the user tapped "Need suggestions" while crafting a goal.
    static func suggestPhrasing(goal: String, language: String) async throws -> [String] {
        let json = try await send(path: "v1/suggest-phrasing", body: [
            "goal": goal,
            "language": language,
        ])
        guard let suggestions = json["suggestions"] as? [String] else { throw WorkerClientError.invalidResponse }
        return suggestions
    }

    static func dailyScript(
        goal: String,
        style: ManifestationStyle,
        language: String,
        dayNumber: Int
    ) async throws -> [String] {
        let json = try await send(path: "v1/daily-script", body: [
            "goal": goal,
            "style": style.rawValue,
            "language": language,
            "dayNumber": dayNumber,
        ])
        guard let lines = json["lines"] as? [String] else { throw WorkerClientError.invalidResponse }
        return lines
    }

    /// Fire-and-forget — a MetricKit crash/hang diagnostic payload, logged
    /// server-side (visible via `wrangler tail`) rather than shown anywhere
    /// in the app.
    static func reportDiagnostics(jsonData: Data) async {
        guard let payload = try? JSONSerialization.jsonObject(with: jsonData) else { return }
        _ = try? await send(path: "v1/diagnostics", body: [
            "platform": "ios",
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            "payload": payload,
        ])
    }

    /// Remote kill switch for client-side analytics — checked on launch and
    /// foreground so disabling it server-side (no app update) takes effect
    /// within one app open, not just for future installs.
    static func fetchAnalyticsEnabled() async -> Bool? {
        guard !sharedSecret.isEmpty else { return nil }
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/config"))
        request.setValue(sharedSecret, forHTTPHeaderField: "X-App-Secret")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let analyticsEnabled = json["analyticsEnabled"] as? Bool else {
            return nil
        }
        return analyticsEnabled
    }

    private static func send(path: String, body: [String: Any]) async throws -> [String: Any] {
        guard !sharedSecret.isEmpty else { throw WorkerClientError.missingSharedSecret }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sharedSecret, forHTTPHeaderField: "X-App-Secret")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WorkerClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw WorkerClientError.server(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WorkerClientError.invalidResponse
        }
        return json
    }
}
