import SwiftUI

struct CameraScreen: View {
    @State private var viewModel: CameraViewModel
    @State private var overlayViewModel: OverlayViewModel
    @State private var capturedImage: UIImage?
    @State private var coachingResponse: AICoachingResponse?
    @State private var showReview = false

    init(
        viewModel: CameraViewModel = CameraViewModel(),
        overlayViewModel: OverlayViewModel = OverlayViewModel()
    ) {
        _viewModel = State(initialValue: viewModel)
        _overlayViewModel = State(initialValue: overlayViewModel)
    }

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(previewLayer: viewModel.previewLayer)
                .ignoresSafeArea()

            // Skeleton pose overlay
            SkeletonOverlay(pose: overlayViewModel.currentPose)
                .ignoresSafeArea()

            // Coaching overlay
            CoachingOverlay(viewModel: overlayViewModel)

            // Bottom toolbar
            VStack {
                Spacer()
                BottomToolbar(
                    isCapturing: viewModel.isCapturing,
                    isReadyToCapture: overlayViewModel.isReadyToCapture,
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
        .alert(
            "Camera error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
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
