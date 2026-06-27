import SwiftUI

/// Drives the top-left pose-suggestion card.
///
/// UX mirrors `AIOrchestrator`: emit the local prefilter's best candidate IMMEDIATELY
/// (zero latency, offline-safe), then let the AI override it when it picks a better dáng.
/// Re-ranking is throttled and only fires when the meaningful context changes, so the card
/// doesn't flicker as the subject moves slightly within the same frame zone.
@MainActor
@Observable
final class PoseSuggestionViewModel {

    /// The dáng currently shown on the card (nil until the first context arrives).
    private(set) var currentSuggestion: PoseSuggestion?
    /// Friendly AI reason ("vì sao hợp cảnh"), shown in the expanded card when available.
    private(set) var selectionReason: String?
    /// User tapped the card to see the full description.
    var isExpanded: Bool = false

    private let library: PoseSuggestionLibrary
    private let provider: any PoseSuggestionProviding
    private let throttleSeconds: TimeInterval

    private var lastContextKey: String?
    private var lastRefineAt: Date = .distantPast
    private var refineTask: Task<Void, Never>?

    init(
        library: PoseSuggestionLibrary = PoseSuggestionLibrary(),
        provider: (any PoseSuggestionProviding)? = nil,
        throttleSeconds: TimeInterval = 3.0
    ) {
        self.library = library
        self.provider = provider ?? AIConfig.makePoseSuggestionProvider()
        self.throttleSeconds = throttleSeconds
    }

    /// Feed the latest scene + frame position. Cheap to call every frame — the heavy AI
    /// call only runs when the context key actually changes.
    func update(scene: SceneContext, framePosition: String, framing: String = "vertical_9_16") {
        let candidates = library.candidates(scene: scene, framing: framing, framePosition: framePosition)
        guard !candidates.isEmpty else { return }

        let context = PoseSuggestionContext(
            scene: scene,
            framing: framing,
            framePosition: framePosition,
            sceneCues: SceneCues.cues(for: scene)
        )

        // Context unchanged → nothing to do (already showing the right dáng / awaiting AI).
        guard context.key != lastContextKey else { return }
        lastContextKey = context.key

        // Tier 1: show the local best instantly.
        currentSuggestion = candidates.first
        selectionReason = nil

        // Rate-limit the AI refine so frame-position jitter at zone boundaries (left↔center)
        // can't spam the network — the local fallback above already updated the card.
        let elapsed = Date().timeIntervalSince(lastRefineAt) >= throttleSeconds
        guard elapsed else { return }
        lastRefineAt = Date()

        // Tier 2: ask the AI to refine in the background; a newer context cancels this one.
        refineTask?.cancel()
        refineTask = Task { [weak self] in
            await self?.refine(context: context, candidates: candidates)
        }
    }

    private func refine(context: PoseSuggestionContext, candidates: [PoseSuggestion]) async {
        do {
            let selection = try await provider.selectSuggestion(context: context, candidates: candidates)
            if Task.isCancelled { return }
            guard let match = candidates.first(where: { $0.id == selection.id }) else { return }
            currentSuggestion = match
            selectionReason = selection.reason
        } catch {
            // Keep the local fallback already on screen.
        }
    }

    func toggleExpanded() {
        isExpanded.toggle()
    }
}
