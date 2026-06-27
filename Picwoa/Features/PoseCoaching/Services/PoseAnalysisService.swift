import Foundation
import CoreGraphics

struct PoseAnalysisResult: Sendable {
    let chinAngle: Float          // degrees, negative = chin down
    let shoulderDelta: Float      // left.y - right.y, positive = left lower
    let torsoWidth: Float         // shoulder width normalized 0..1
    let frameCenterX: Float       // person center X in frame 0..1
}

struct PoseAnalysisService {

    func analyze(_ pose: PoseObservation) -> PoseAnalysisResult? {
        guard let left = pose.leftShoulder, let right = pose.rightShoulder else { return nil }

        let shoulderMidX = Float((left.x + right.x) / 2)
        let shoulderDelta = Float(left.y - right.y)
        let torsoWidth = Float(abs(left.x - right.x))

        let chinAngle: Float
        if let head = pose.head, let neck = pose.neck {
            chinAngle = Float(head.y - neck.y)
        } else {
            chinAngle = 0
        }

        return PoseAnalysisResult(
            chinAngle: chinAngle,
            shoulderDelta: shoulderDelta,
            torsoWidth: torsoWidth,
            frameCenterX: shoulderMidX
        )
    }
}
