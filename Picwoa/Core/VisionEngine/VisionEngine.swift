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
        let pose = PoseDetector.detect(in: sampleBuffer)
        _poseContinuation.yield(pose)

        if pose != nil {
            _personContinuation.yield(true)
        } else {
            _personContinuation.yield(PersonDetector.detect(in: sampleBuffer))
        }
    }
}
