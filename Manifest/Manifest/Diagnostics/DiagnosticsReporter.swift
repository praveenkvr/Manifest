//
//  DiagnosticsReporter.swift
//  Manifest
//
//  Apple's own crash/hang reporting — MetricKit, not a third-party SDK.
//  Payloads are delivered at most once a day per Apple's own docs, covering
//  the prior 24h. Forwarded to the Worker's /v1/diagnostics so they're
//  visible via `wrangler tail` instead of only living in Xcode Organizer,
//  which can lag days behind for symbolicated crash reports.
//

import Foundation
import MetricKit

final class DiagnosticsReporter: NSObject, MXMetricManagerSubscriber {
    static let shared = DiagnosticsReporter()

    private override init() {
        super.init()
    }

    func startListening() {
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let data = payload.jsonRepresentation()
            Task { await WorkerClient.reportDiagnostics(jsonData: data) }
        }
    }
}
