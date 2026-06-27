import SwiftUI
import AVFoundation

@MainActor
@Observable
final class CameraViewModel {

    var permissionStatus: CameraPermissionStatus = .notDetermined
    var isCapturing: Bool = false

    private let cameraEngine: CameraEngine
    private let permissionManager: CameraPermissionManager
    private let captureService: CaptureService
    let previewLayer: AVCaptureVideoPreviewLayer

    init(
        cameraEngine: CameraEngine = .shared,
        permissionManager: CameraPermissionManager = CameraPermissionManager(),
        captureService: CaptureService = CaptureService()
    ) {
        self.cameraEngine = cameraEngine
        self.permissionManager = permissionManager
        self.captureService = captureService
        self.previewLayer = cameraEngine.makePreviewLayer()
    }

    func onAppear() async {
        await permissionManager.request()
        permissionStatus = permissionManager.status
        if permissionStatus == .granted {
            try? await cameraEngine.startSession()
        }
    }

    func capture() async -> UIImage? {
        guard !isCapturing else { return nil }
        isCapturing = true
        defer { isCapturing = false }
        return try? await captureService.capture()
    }

    func openSettings() {
        permissionManager.openSettings()
    }
}
