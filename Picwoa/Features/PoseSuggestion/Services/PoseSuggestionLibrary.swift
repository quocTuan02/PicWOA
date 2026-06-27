import Foundation

/// Loads the bundled pose catalog (`PoseSuggestions.json`) and prefilters it locally.
///
/// Decoded once and cached. The local prefilter runs every frame (cheap, no allocation
/// beyond the filtered array) and produces the shortlist the AI ranks — so the feature
/// works offline / before the AI replies, mirroring the orchestrator's "fallback first" UX.
struct PoseSuggestionLibrary: Sendable {

    let all: [PoseSuggestion]

    init(all: [PoseSuggestion]) {
        self.all = all
    }

    /// Load from a JSON resource in the bundle. Falls back to the built-in catalog if the
    /// file is missing or malformed, so the card always has something to show.
    init(bundle: Bundle = .main, resource: String = "PoseSuggestions") {
        guard
            let url = bundle.url(forResource: resource, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let catalog = try? JSONDecoder().decode(Catalog.self, from: data),
            !catalog.poses.isEmpty
        else {
            self.all = Self.builtIn
            return
        }
        self.all = catalog.poses
    }

    /// Candidates that fit the scene + framing + frame position, most-specific first.
    /// Never empty when the catalog is non-empty: scene-agnostic poses backstop the list.
    func candidates(scene: SceneContext, framing: String, framePosition: String) -> [PoseSuggestion] {
        let sceneMatches = all.filter { $0.matches(scene: scene) }
        let pool = sceneMatches.isEmpty ? all : sceneMatches

        let ranked = pool.sorted { lhs, rhs in
            specificity(lhs, framing: framing, framePosition: framePosition)
                > specificity(rhs, framing: framing, framePosition: framePosition)
        }
        return ranked
    }

    /// Higher = better local fit. Exact scene/framing/position beats `any`.
    private func specificity(_ pose: PoseSuggestion, framing: String, framePosition: String) -> Int {
        var score = 0
        if !pose.scenes.contains("any") { score += 4 }
        if pose.matches(framePosition: framePosition) { score += pose.framePosition == "any" ? 1 : 2 }
        if pose.matches(framing: framing) { score += pose.framing == "any" ? 0 : 1 }
        return score
    }

    private struct Catalog: Decodable {
        let poses: [PoseSuggestion]
    }

    /// Minimal safety net if the JSON resource is absent (e.g. not yet added to the target).
    static let builtIn: [PoseSuggestion] = [
        PoseSuggestion(
            id: "any_portrait_classic",
            displayName: "Chân dung cổ điển",
            imageName: "pose_any_portrait_classic",
            description: "Xoay vai nhẹ khỏi camera, cổ vươn dài, cằm đưa ra trước và hơi hạ xuống, ánh mắt nhìn thẳng ống kính.",
            scenes: ["any"],
            framing: "any",
            framePosition: "center",
            bodyCoverage: "portrait",
            tags: ["safe", "classic"]
        )
    ]
}
