import Foundation
import CoreGraphics

struct PoseAnalysisResult: Sendable {
    let chinAngle: Float          // degrees, negative = chin down
    let shoulderDelta: Float      // left.y - right.y, positive = left lower
    let torsoWidth: Float         // shoulder width normalized 0..1
    let frameCenterX: Float       // person center X in frame 0..1
    let framePosition: String     // left, center, or right

    init(
        chinAngle: Float,
        shoulderDelta: Float,
        torsoWidth: Float,
        frameCenterX: Float,
        framePosition: String? = nil
    ) {
        self.chinAngle = chinAngle
        self.shoulderDelta = shoulderDelta
        self.torsoWidth = torsoWidth
        self.frameCenterX = frameCenterX
        self.framePosition = framePosition ?? Self.positionLabel(for: frameCenterX)
    }

    private static func positionLabel(for centerX: Float) -> String {
        if centerX < 0.35 { return "left" }
        if centerX > 0.65 { return "right" }
        return "center"
    }
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
