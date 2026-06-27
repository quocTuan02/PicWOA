import SwiftUI

@main
struct PicwoaApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            CameraScreen(
                viewModel: coordinator.cameraViewModel,
                overlayViewModel: coordinator.overlayViewModel
            )
                .preferredColorScheme(.dark)
                .task { coordinator.start() }
        }
    }
}
