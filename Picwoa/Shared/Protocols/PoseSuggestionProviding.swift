import Foundation

/// Context handed to the AI so it can pick the dáng that fits the surrounding scenery.
struct PoseSuggestionContext: Sendable, Equatable {
    let scene: SceneContext
    let framing: String
    let framePosition: String
    /// Scene composition cues (reused from `SceneCues`), e.g. "chiều sâu nền".
    let sceneCues: [String]

    /// Stable key for throttle/dedup — re-rank only when the meaningful context changes.
    var key: String { "\(scene.rawValue)|\(framing)|\(framePosition)" }
}

/// The AI's pick from a candidate shortlist.
struct PoseSelection: Sendable, Equatable {
    let id: String
    /// Short, friendly Vietnamese reason — why this dáng fits the scene (optional).
    let reason: String?
}

/// Selects the best reference pose for the current context from a candidate shortlist.
///
/// Mirrors `AIBackendProtocol`: one async method, swappable Mock ↔ OpenAI implementation,
/// so the app runs offline (Mock) with no API key and upgrades to AI ranking when configured.
protocol PoseSuggestionProviding: Sendable {
    func selectSuggestion(
        context: PoseSuggestionContext,
        candidates: [PoseSuggestion]
    ) async throws -> PoseSelection
}
