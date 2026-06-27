import AVFoundation

protocol CameraBufferProvider: AnyObject {
    nonisolated func makeSampleBufferStream() -> AsyncStream<CMSampleBuffer>
}
