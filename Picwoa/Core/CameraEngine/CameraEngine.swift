import AVFoundation
import UIKit

final class CameraEngine: NSObject, CameraBufferProvider, @unchecked Sendable {
    static let shared = CameraEngine()

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.picwoa.camera.session")
    private let bufferQueue = DispatchQueue(label: "com.picwoa.camera.buffer")
    private let bufferContinuation: AsyncStream<CMSampleBuffer>.Continuation
    private var photoDelegate: PhotoCaptureDelegate?
    private var isConfigured = false

    let sampleBufferStream: AsyncStream<CMSampleBuffer>

    private override init() {
        let (stream, continuation) = AsyncStream<CMSampleBuffer>.makeStream()
        sampleBufferStream = stream
        bufferContinuation = continuation
        super.init()
    }

    func startSession() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraError.engineUnavailable)
                    return
                }
                do {
                    try self.configureSessionIfNeeded()
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capturePhoto() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraError.engineUnavailable)
                    return
                }
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .off

                let delegate = PhotoCaptureDelegate { [weak self] result in
                    self?.photoDelegate = nil
                    continuation.resume(with: result)
                }
                self.photoDelegate = delegate
                self.photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    func didOutputSampleBuffer(_ buffer: CMSampleBuffer) {
        bufferContinuation.yield(buffer)
    }

    private func configureSessionIfNeeded() throws {
        guard !isConfigured else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            throw CameraError.deviceUnavailable
        }

        guard session.canAddInput(input) else {
            throw CameraError.configurationFailed
        }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            throw CameraError.configurationFailed
        }
        session.addOutput(photoOutput)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: bufferQueue)

        guard session.canAddOutput(videoOutput) else {
            throw CameraError.configurationFailed
        }
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        if let connection = photoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        isConfigured = true
    }
}

extension CameraEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        didOutputSampleBuffer(sampleBuffer)
    }
}

enum CameraError: Error {
    case engineUnavailable
    case deviceUnavailable
    case configurationFailed
    case photoCaptureFailed
    case imageConversionFailed
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<UIImage, Error>) -> Void

    init(completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            completion(.failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            completion(.failure(CameraError.photoCaptureFailed))
            return
        }

        guard let image = UIImage(data: data) else {
            completion(.failure(CameraError.imageConversionFailed))
            return
        }

        completion(.success(image))
    }
}
