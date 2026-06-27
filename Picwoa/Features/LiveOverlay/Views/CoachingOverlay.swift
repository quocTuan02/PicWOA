import SwiftUI

struct CoachingOverlay: View {
    let viewModel: OverlayViewModel

    var body: some View {
        VStack {
            Spacer()
            if !viewModel.personDetected {
                CoachingCard(
                    message: "Bước vào khung hình",
                    direction: nil,
                    isReady: false
                )
                .padding(.bottom, 100)
            } else if viewModel.showOverlay, let response = viewModel.currentResponse {
                CoachingCard(
                    message: response.mainCue,
                    direction: nil,
                    isReady: viewModel.isReadyToCapture
                )
                .padding(.bottom, 100)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(Anim.normal, value: viewModel.currentResponse?.mainCue)
    }
}
