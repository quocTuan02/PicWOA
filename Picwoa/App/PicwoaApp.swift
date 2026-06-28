import SwiftUI

@main
struct PicwoaApp: App {
    @State private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            CameraScreen(
                viewModel: coordinator.cameraViewModel,
                overlayViewModel: coordinator.overlayViewModel,
                poseSuggestionViewModel: coordinator.poseSuggestionViewModel,
                onRequestAICoaching: { await coordinator.requestAICoaching() }
            )
                .preferredColorScheme(.dark)
                .task { coordinator.start() }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        coordinator.start()
                    case .background, .inactive:
                        coordinator.stop()
                    @unknown default:
                        coordinator.stop()
                    }
                }
        }
    }
}
