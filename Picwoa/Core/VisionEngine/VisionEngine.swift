import Vision
import AVFoundation

actor VisionEngine: PoseProvider {
    static let shared = VisionEngine()

    private var poseContinuation: AsyncStream<PoseObservation?>.Continuation?
    private var personContinuation: AsyncStream<Bool>.Continuation?

    private(set) lazy var poseStream: AsyncStream<PoseObservation?> = {
        AsyncStream { [weak self] continuation in
            Task { await self?.poseContinuation = continuation }
        }
    }()

    private(set) lazy var personDetectedStream: AsyncStream<Bool> = {
        AsyncStream { [weak self] continuation in
            Task { await self?.personContinuation = continuation }
        }
    }()

    func process(sampleBuffer: CMSampleBuffer) {
        // TODO: Dev B — implement VNDetectHumanBodyPoseRequest
        // let request = VNDetectHumanBodyPoseRequest()
        // let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
        // try? handler.perform([request])
        // parse result → emit PoseObservation
    }
}
