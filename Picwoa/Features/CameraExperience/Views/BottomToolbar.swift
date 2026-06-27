import SwiftUI

struct BottomToolbar: View {
    let isCapturing: Bool
    let isReadyToCapture: Bool
    let onCapture: () -> Void

    var body: some View {
        HStack {
            Spacer()
            CaptureButton(
                isCapturing: isCapturing,
                isReadyToCapture: isReadyToCapture,
                action: onCapture
            )
            Spacer()
        }
        .padding(.bottom, Spacing.xl)
        .background(Color.picBackground.opacity(0.3))
    }
}
