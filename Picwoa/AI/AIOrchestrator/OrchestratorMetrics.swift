import Foundation

/// The decision path for each RuleEngineResult — AI_ORCHESTRATION_SPEC §9.
enum DecisionPath: String, Sendable {
    case ruleEngineClean    // L3 stop — no more issues
    case ruleEngineThrottle // L3 + throttle active → use cached/rule
    case aiSuccess          // L5 success
    case aiTimeout          // L5 timeout → fallback
    case aiError            // L5 error / invalid → cache or rule
}

/// Internal metric, debug-only. Never exposed to the UI.
struct OrchestratorMetrics: Sendable {
    var decisionPath: DecisionPath
    var executionTimeMs: Double
    var cacheHit: Bool
    var ruleEngineIssueCount: Int
    var failureReason: String?

    #if DEBUG
    func log() {
        let reason = failureReason.map { " reason=\($0)" } ?? ""
        print("[AI] path=\(decisionPath.rawValue) time=\(String(format: "%.0f", executionTimeMs))ms cache=\(cacheHit) issues=\(ruleEngineIssueCount)\(reason)")
    }
    #endif
}
