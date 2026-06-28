import SwiftUI
import AVFoundation

@MainActor
@Observable
final class CameraViewModel {

    var permissionStatus: CameraPermissionStatus = .notDetermined
    var isCapturing: Bool = false
    var errorMessage: String?
    var zoomFactor: CGFloat = 1.0

    let minZoom: CGFloat = 1.0
    let maxZoom: CGFloat = CameraEngine.maxZoomFactor

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
            do {
                try await cameraEngine.startSession()
                errorMessage = nil
            } catch {
                errorMessage = "Không thể khởi động camera. Vui lòng thử lại."
            }
        }
    }

    func capture() async -> UIImage? {
        guard !isCapturing else { return nil }
        isCapturing = true
        defer { isCapturing = false }

        do {
            let image = try await captureService.capture()
            errorMessage = nil
            return image
        } catch {
            errorMessage = "Không thể chụp ảnh. Vui lòng thử lại."
            return nil
        }
    }

    func setZoom(_ factor: CGFloat) {
        let clamped = max(minZoom, min(factor, maxZoom))
        zoomFactor = clamped
        cameraEngine.setZoom(clamped)
    }

    func openSettings() {
        permissionManager.openSettings()
    }
}
