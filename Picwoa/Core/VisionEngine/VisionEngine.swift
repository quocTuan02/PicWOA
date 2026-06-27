import Vision
import AVFoundation

actor VisionEngine: PoseProvider {
    static let shared = VisionEngine()

    // Multicast so each `start()` can re-subscribe with a fresh stream — a bare AsyncStream
    // only supports one iteration and would go silent after a lifecycle stop/start.
    private let poseBroadcaster = AsyncBroadcaster<PoseObservation?>()
    private let personBroadcaster = AsyncBroadcaster<Bool>()

    nonisolated var poseStream: AsyncStream<PoseObservation?> { poseBroadcaster.subscribe() }
    nonisolated var personDetectedStream: AsyncStream<Bool> { personBroadcaster.subscribe() }

    private init() {}

    func process(sampleBuffer: CMSampleBuffer) {
        let pose = PoseDetector.detect(in: sampleBuffer)
        poseBroadcaster.yield(pose)

        if pose != nil {
            personBroadcaster.yield(true)
        } else {
            personBroadcaster.yield(PersonDetector.detect(in: sampleBuffer))
        }
    }
}
