import SwiftUI
import AVFoundation

@MainActor
@Observable
final class CameraViewModel {

    var permissionStatus: CameraPermissionStatus = .notDetermined
    var isCapturing: Bool = false

    private let cameraEngine = CameraEngine.shared
    private let permissionManager = CameraPermissionManager()

    var previewLayer: AVCaptureVideoPreviewLayer {
        // TODO: Dev A — return layer from CameraEngine
        AVCaptureVideoPreviewLayer()
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
        return try? await cameraEngine.capturePhoto()
    }

    func openSettings() {
        permissionManager.openSettings()
    }
}
