import SwiftUI

struct CameraScreen: View {
    @State private var viewModel = CameraViewModel()
    @State private var overlayViewModel = OverlayViewModel()
    @State private var capturedImage: UIImage?
    @State private var coachingResponse: AICoachingResponse?
    @State private var showReview = false

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(previewLayer: viewModel.previewLayer)
                .ignoresSafeArea()

            // Coaching overlay
            CoachingOverlay(viewModel: overlayViewModel)

            // Bottom toolbar
            VStack {
                Spacer()
                BottomToolbar(
                    isCapturing: viewModel.isCapturing,
                    onCapture: handleCapture
                )
            }
        }
        .task { await viewModel.onAppear() }
        .sheet(isPresented: $showReview) {
            if let image = capturedImage, let coaching = coachingResponse {
                ReviewScreen(originalImage: image, coaching: coaching)
            }
        }
        .overlay {
            if viewModel.permissionStatus == .denied {
                PermissionView(type: .camera, onOpenSettings: viewModel.openSettings)
            }
        }
    }

    private func handleCapture() {
        Task {
            if let image = await viewModel.capture() {
                capturedImage = image
                coachingResponse = overlayViewModel.lastResponse ?? .placeholder
                showReview = true
            }
        }
    }
}
