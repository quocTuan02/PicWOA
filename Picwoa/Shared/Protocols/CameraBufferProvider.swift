import AVFoundation

protocol CameraBufferProvider: AnyObject {
    var sampleBufferStream: AsyncStream<CMSampleBuffer> { get }
}
