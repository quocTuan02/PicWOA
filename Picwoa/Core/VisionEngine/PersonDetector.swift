import Vision
import AVFoundation

struct PersonDetector {
    static func detect(in sampleBuffer: CMSampleBuffer) -> Bool {
        let request = VNDetectHumanRectanglesRequest()
        request.upperBodyOnly = false
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)

        do {
            try handler.perform([request])
        } catch {
            return PoseDetector.detect(in: sampleBuffer) != nil
        }

        return request.results?.contains { $0.confidence >= 0.5 } ?? false
    }
}
