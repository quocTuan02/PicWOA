import Foundation

/// Offline pose picker — deterministic, no network, no API key.
/// Default provider (same role as `MockAIClient`): picks the candidate whose frame position
/// matches the subject, otherwise the most-specific candidate the library already ranked first.
final class MockPoseSuggestionProvider: PoseSuggestionProviding, Sendable {

    let simulatedLatency: UInt64

    init(simulatedLatencyNanos: UInt64 = 150_000_000) {
        self.simulatedLatency = simulatedLatencyNanos
    }

    func selectSuggestion(
        context: PoseSuggestionContext,
        candidates: [PoseSuggestion]
    ) async throws -> PoseSelection {
        if simulatedLatency > 0 {
            try await Task.sleep(nanoseconds: simulatedLatency)
        }
        guard let first = candidates.first else {
            throw PoseSuggestionError.noCandidates
        }
        let exact = candidates.first { $0.framePosition == context.framePosition }
        let chosen = exact ?? first
        return PoseSelection(id: chosen.id, reason: nil)
    }
}

enum PoseSuggestionError: Error {
    case noCandidates
    case invalidResponse
}
