import Foundation

/// An arrow/overlay cue drawn directly on the body (promt.md §8).
struct OverlayCue: Sendable {
    let part: String
    let type: String          // "arrow"
    let direction: String     // Direction.rawValue
}

struct AICoachingResponse: Sendable {
    let mainCue: String           // Vietnamese, ≤ 40 characters
    let secondaryCue: String?
    let cameraInstruction: String?
    let score: Int                // 1–5
    let feedback: String          // Vietnamese, 1–2 sentences
    let editingRecipe: EditingRecipe
    let overlay: [OverlayCue]
    /// Structured signal for the UI — do NOT let the UI infer readiness from text.
    /// Orchestrator sets = `RuleEngineResult.readyToCapture`.
    let isReadyToCapture: Bool

    init(
        mainCue: String,
        secondaryCue: String?,
        cameraInstruction: String?,
        score: Int,
        feedback: String,
        editingRecipe: EditingRecipe,
        overlay: [OverlayCue] = [],
        isReadyToCapture: Bool = false
    ) {
        self.mainCue = mainCue
        self.secondaryCue = secondaryCue
        self.cameraInstruction = cameraInstruction
        self.score = score
        self.feedback = feedback
        self.editingRecipe = editingRecipe
        self.overlay = overlay
        self.isReadyToCapture = isReadyToCapture
    }

    /// Direction of the first overlay — used to render the arrow on CoachingCard.
    var primaryDirection: Direction? {
        overlay.first.flatMap { Direction(rawValue: $0.direction) }
    }

    static let placeholder = AICoachingResponse(
        mainCue: "Ngẩng đầu lên",
        secondaryCue: "Nhấc vai trái lên",
        cameraInstruction: nil,
        score: 3,
        feedback: "Tư thế ổn, cần điều chỉnh thêm một chút.",
        editingRecipe: .neutral,
        overlay: [OverlayCue(part: "chin", type: "arrow", direction: Direction.up.rawValue)]
    )
}
