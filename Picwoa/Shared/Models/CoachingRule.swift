import Foundation

enum Direction: String, Sendable {
    case up, down, left, right
    case rotateLeft, rotateRight
    case forward, backward
}

struct CoachingRule: Identifiable, Sendable {
    let id: String
    let message: String       // tiếng Việt
    let direction: Direction?
    let priority: Int         // 1 = highest
}

struct RuleEngineResult: Sendable {
    let issues: [CoachingRule]
    let readyToCapture: Bool

    static let empty = RuleEngineResult(issues: [], readyToCapture: false)
}
