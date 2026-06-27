import Vision
import AVFoundation

struct PoseDetector {
    private static let confidenceThreshold: Float = 0.5

    static func detect(in sampleBuffer: CMSampleBuffer) -> PoseObservation? {
        // TODO: Dev B — implement full VNDetectHumanBodyPoseRequest
        // Parse VNHumanBodyPoseObservation.recognizedPoint for each landmark
        // Map to PoseObservation domain model
        return nil
    }

    private static func point(
        from observation: VNHumanBodyPoseObservation,
        joint: VNHumanBodyPoseObservation.JointName
    ) -> CGPoint? {
        guard let point = try? observation.recognizedPoint(joint),
              point.confidence > confidenceThreshold else { return nil }
        return CGPoint(x: point.location.x, y: 1 - point.location.y)
    }
}
