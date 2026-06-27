import UIKit

struct CaptureService {
    private let cameraEngine: CameraEngine

    init(cameraEngine: CameraEngine = .shared) {
        self.cameraEngine = cameraEngine
    }

    func capture() async throws -> UIImage {
        try await cameraEngine.capturePhoto()
    }
}
