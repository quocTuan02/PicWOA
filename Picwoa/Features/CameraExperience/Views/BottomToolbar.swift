import SwiftUI

struct BottomToolbar: View {
    let isCapturing: Bool
    let onCapture: () -> Void

    var body: some View {
        HStack {
            Spacer()
            CaptureButton(isCapturing: isCapturing, action: onCapture)
            Spacer()
        }
        .padding(.bottom, Spacing.xl)
        .background(Color.picBackground.opacity(0.3))
    }
}
