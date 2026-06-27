import Vision
import AVFoundation

actor VisionEngine: PoseProvider {
    static let shared = VisionEngine()

    private let _poseContinuation: AsyncStream<PoseObservation?>.Continuation
    private let _personContinuation: AsyncStream<Bool>.Continuation

    nonisolated let poseStream: AsyncStream<PoseObservation?>
    nonisolated let personDetectedStream: AsyncStream<Bool>

    private init() {
        let (poseStr, poseCont) = AsyncStream<PoseObservation?>.makeStream()
        let (personStr, personCont) = AsyncStream<Bool>.makeStream()
        poseStream = poseStr
        personDetectedStream = personStr
        _poseContinuation = poseCont
        _personContinuation = personCont
    }

    func process(sampleBuffer: CMSampleBuffer) {
        // TODO: Dev B — implement VNDetectHumanBodyPoseRequest
        // let request = VNDetectHumanBodyPoseRequest()
        // let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
        // try? handler.perform([request])
        // parse result → emit PoseObservation
    }
}
