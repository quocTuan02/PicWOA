import Foundation
import CoreGraphics

struct PoseObservation: Sendable {
    let head: CGPoint?
    let neck: CGPoint?
    let leftShoulder: CGPoint?
    let rightShoulder: CGPoint?
    let hip: CGPoint?
    let leftKnee: CGPoint?
    let rightKnee: CGPoint?
    let leftFoot: CGPoint?
    let rightFoot: CGPoint?
    let confidence: Float
    let timestamp: TimeInterval

    static let empty = PoseObservation(
        head: nil, neck: nil,
        leftShoulder: nil, rightShoulder: nil,
        hip: nil, leftKnee: nil, rightKnee: nil,
        leftFoot: nil, rightFoot: nil,
        confidence: 0, timestamp: 0
    )
}
