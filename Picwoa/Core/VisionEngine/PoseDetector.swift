import Vision
import AVFoundation
import CoreGraphics

struct PoseDetector {
    private static let confidenceThreshold: Float = 0.5

    static func detect(in sampleBuffer: CMSampleBuffer) -> PoseObservation? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)

        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observation = request.results?.max(by: { $0.confidence < $1.confidence }) else {
            return nil
        }

        let leftShoulder = point(from: observation, joint: .leftShoulder)
        let rightShoulder = point(from: observation, joint: .rightShoulder)
        let leftHip = point(from: observation, joint: .leftHip)
        let rightHip = point(from: observation, joint: .rightHip)

        guard observation.confidence >= confidenceThreshold,
              leftShoulder != nil || rightShoulder != nil || point(from: observation, joint: .nose) != nil else {
            return nil
        }

        return PoseObservation(
            head: headPoint(from: observation),
            neck: point(from: observation, joint: .neck),
            leftShoulder: leftShoulder,
            rightShoulder: rightShoulder,
            hip: midpoint(leftHip, rightHip),
            leftKnee: point(from: observation, joint: .leftKnee),
            rightKnee: point(from: observation, joint: .rightKnee),
            leftFoot: point(from: observation, joint: .leftAnkle),
            rightFoot: point(from: observation, joint: .rightAnkle),
            confidence: observation.confidence,
            timestamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        )
    }

    private static func point(
        from observation: VNHumanBodyPoseObservation,
        joint: VNHumanBodyPoseObservation.JointName
    ) -> CGPoint? {
        guard let point = try? observation.recognizedPoint(joint),
              point.confidence > confidenceThreshold else { return nil }
        return CGPoint(x: point.location.x, y: 1 - point.location.y)
    }

    private static func headPoint(from observation: VNHumanBodyPoseObservation) -> CGPoint? {
        point(from: observation, joint: .nose)
            ?? midpoint(
                point(from: observation, joint: .leftEye),
                point(from: observation, joint: .rightEye)
            )
    }

    private static func midpoint(_ lhs: CGPoint?, _ rhs: CGPoint?) -> CGPoint? {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return CGPoint(x: (lhs.x + rhs.x) / 2, y: (lhs.y + rhs.y) / 2)
        case let (lhs?, nil):
            return lhs
        case let (nil, rhs?):
            return rhs
        case (nil, nil):
            return nil
        }
    }
}
