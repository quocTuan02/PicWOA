import AVFoundation

protocol CameraBufferProvider: AnyObject {
    nonisolated var sampleBufferStream: AsyncStream<CMSampleBuffer> { get }
}
