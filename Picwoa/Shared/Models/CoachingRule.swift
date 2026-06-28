import Foundation

enum Direction: String, Sendable {
    case up, down, left, right
    case rotateLeft, rotateRight
    case forward, backward
}

/// Deviation level of a pose error — fed into the prompt so the AI can choose the correction intensity.
enum Magnitude: String, Sendable {
    case small, medium, large
}

struct CoachingRule: Identifiable, Sendable {
    let id: String
    let message: String       // Vietnamese
    let direction: Direction?
    let priority: Int         // 1 = highest
    let magnitude: Magnitude

    init(
        id: String,
        message: String,
        direction: Direction?,
        priority: Int,
        magnitude: Magnitude = .medium
    ) {
        self.id = id
        self.message = message
        self.direction = direction
        self.priority = priority
        self.magnitude = magnitude
    }
}

struct RuleEngineResult: Sendable {
    let issues: [CoachingRule]
    let readyToCapture: Bool
    let framePosition: String

    init(issues: [CoachingRule], readyToCapture: Bool, framePosition: String = "center") {
        self.issues = issues
        self.readyToCapture = readyToCapture
        self.framePosition = framePosition
    }

    static let empty = RuleEngineResult(issues: [], readyToCapture: false)
}
