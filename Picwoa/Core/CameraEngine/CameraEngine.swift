import AVFoundation
import UIKit

actor CameraEngine: CameraBufferProvider {
    static let shared = CameraEngine()

    private let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    nonisolated private let bufferContinuation: AsyncStream<CMSampleBuffer>.Continuation

    nonisolated let sampleBufferStream: AsyncStream<CMSampleBuffer>

    private init() {
        let (stream, continuation) = AsyncStream<CMSampleBuffer>.makeStream()
        sampleBufferStream = stream
        bufferContinuation = continuation
    }

    func startSession() async throws {
        // TODO: Dev A — configure session, add video input, add photo output
        // session.sessionPreset = .photo
        // session.addInput(...)
        // session.addOutput(photoOutput)
        // session.startRunning()
    }

    func stopSession() {
        session.stopRunning()
        bufferContinuation.finish()
    }

    func capturePhoto() async throws -> UIImage {
        // TODO: Dev A — implement AVCapturePhotoCaptureDelegate via continuation
        fatalError("TODO: implement capturePhoto")
    }

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    nonisolated func didOutputSampleBuffer(_ buffer: CMSampleBuffer) {
        bufferContinuation.yield(buffer)
    }
}
