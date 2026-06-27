import Foundation

/// Validate an AICoachingResponse before emitting — AI_ORCHESTRATION_SPEC §5.
/// Blocks empty responses / out-of-range values / overly long cues from reaching the UI.
enum ResponseValidator {

    static func validate(_ response: AICoachingResponse) -> Bool {
        guard !response.mainCue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard response.mainCue.count <= 40 else { return false }
        guard (1...5).contains(response.score) else { return false }

        let r = response.editingRecipe
        guard (-1.0...1.0).contains(r.exposure) else { return false }
        guard (-100...100).contains(r.contrast) else { return false }
        guard (-100...100).contains(r.highlights) else { return false }
        guard (-100...100).contains(r.shadows) else { return false }
        guard (-100...100).contains(r.temperature) else { return false }
        guard (-100...100).contains(r.vibrance) else { return false }

        // Overlay is optional — but if present, the direction must be valid (to render the arrow).
        for cue in response.overlay where Direction(rawValue: cue.direction) == nil {
            return false
        }

        return true
    }
}
