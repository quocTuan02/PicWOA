import SwiftUI
import OSLog

private let cameraScreenLogger = Logger(subsystem: "com.picwoa.app", category: "CameraScreen")

struct CameraScreen: View {
    @State private var viewModel: CameraViewModel
    @State private var overlayViewModel: OverlayViewModel
    @State private var poseSuggestionViewModel: PoseSuggestionViewModel
    @State private var capturedImage: UIImage?
    @State private var coachingResponse: AICoachingResponse?
    @State private var showReview = false
    @State private var isRequestingAI = false

    /// Fired when the user taps the AI button — wired to `AppCoordinator.requestAICoaching()`.
    private let onRequestAICoaching: () async -> Void

    // Zoom state
    @State private var baseZoom: CGFloat = 1.0
    @State private var showZoomIndicator = false
    @State private var zoomHideTask: Task<Void, Never>?

    init(
        viewModel: CameraViewModel = CameraViewModel(),
        overlayViewModel: OverlayViewModel = OverlayViewModel(),
        poseSuggestionViewModel: PoseSuggestionViewModel = PoseSuggestionViewModel(),
        onRequestAICoaching: @escaping () async -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        _overlayViewModel = State(initialValue: overlayViewModel)
        _poseSuggestionViewModel = State(initialValue: poseSuggestionViewModel)
        self.onRequestAICoaching = onRequestAICoaching
    }

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(previewLayer: viewModel.previewLayer)
                .ignoresSafeArea()
                .gesture(pinchGesture)

            // Skeleton pose overlay
            SkeletonOverlay(pose: overlayViewModel.currentPose)
                .ignoresSafeArea()

            // Coaching overlay
            CoachingOverlay(viewModel: overlayViewModel)

            // Pose suggestion — top-left reference dáng that fits the scene
            VStack {
                HStack {
                    PoseSuggestionCard(viewModel: poseSuggestionViewModel)
                    Spacer()
                }
                Spacer()
            }
            .padding(Spacing.m)

            // Zoom indicator — top center, fades after gesture ends
            VStack {
                ZoomIndicator(factor: viewModel.zoomFactor)
                    .opacity(showZoomIndicator ? 1 : 0)
                    .animation(Anim.normal, value: showZoomIndicator)
                    .padding(.top, 60)
                Spacer()
            }

            // Bottom toolbar
            VStack {
                Spacer()
                BottomToolbar(
                    isCapturing: viewModel.isCapturing,
                    isReadyToCapture: overlayViewModel.isReadyToCapture,
                    isRequestingAI: isRequestingAI,
                    onCapture: handleCapture,
                    onRequestAI: handleRequestAI
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
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func handleRequestAI() {
        guard !isRequestingAI else { return }
        Task {
            isRequestingAI = true
            await onRequestAICoaching()
            isRequestingAI = false
        }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let proposed = baseZoom * value.magnification
                viewModel.setZoom(proposed)
                showZoomIndicator = true
                zoomHideTask?.cancel()
            }
            .onEnded { value in
                baseZoom = viewModel.zoomFactor
                zoomHideTask = Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run { showZoomIndicator = false }
                }
            }
    }

    private func handleCapture() {
        Task {
            if let image = await viewModel.capture() {
                // Safety net: prefer the live response, fall back to the last-known one
                // (kept even when the subject briefly leaves frame), then a static placeholder.
                let response = overlayViewModel.currentResponse
                    ?? overlayViewModel.lastResponse
                    ?? .placeholder
                let source = overlayViewModel.currentResponse != nil ? "currentResponse"
                    : overlayViewModel.lastResponse != nil ? "lastResponse"
                    : "placeholder"
                cameraScreenLogger.info(
                    "handleCapture coachingResponse source=\(source, privacy: .public) mainCue=\(response.mainCue, privacy: .public) score=\(response.score) ready=\(response.isReadyToCapture) overlayCount=\(response.overlay.count)"
                )
                #if DEBUG
                print("[CameraScreen] handleCapture coachingResponse source=\(source) mainCue=\"\(response.mainCue)\" score=\(response.score) ready=\(response.isReadyToCapture) overlayCount=\(response.overlay.count)")
                #endif
                capturedImage = image
                coachingResponse = response
                showReview = true
            }
        }
    }
}

private struct ZoomIndicator: View {
    let factor: CGFloat

    var body: some View {
        Text(String(format: "%.1f×", factor))
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundColor(.picTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }
}
