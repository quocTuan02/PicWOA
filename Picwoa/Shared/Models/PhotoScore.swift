import Foundation

struct PhotoScore: Sendable {
    let stars: Int          // 1–5
    let feedback: String    // tiếng Việt
    let improvementTip: String

    var starDisplay: String { String(repeating: "★", count: stars) + String(repeating: "☆", count: 5 - stars) }
}
