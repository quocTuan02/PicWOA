import AVFoundation

enum CameraPermissionStatus {
    case notDetermined, granted, denied
}

@MainActor
final class CameraPermissionManager: ObservableObject {
    @Published private(set) var status: CameraPermissionStatus = .notDetermined

    func request() async {
        let current = AVCaptureDevice.authorizationStatus(for: .video)
        switch current {
        case .authorized:
            status = .granted
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            status = granted ? .granted : .denied
        default:
            status = .denied
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
