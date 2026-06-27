import SwiftUI

struct BottomToolbar: View {
    let isCapturing: Bool
    let isReadyToCapture: Bool
    let isRequestingAI: Bool
    let onCapture: () -> Void
    let onRequestAI: () -> Void

    var body: some View {
        HStack {
            Spacer()
            AICoachButton(isLoading: isRequestingAI, action: onRequestAI)
            Spacer()
            CaptureButton(
                isCapturing: isCapturing,
                isReadyToCapture: isReadyToCapture,
                action: onCapture
            )
            Spacer()
            // Symmetry spacer so the capture button stays centered.
            Color.clear.frame(width: 56, height: 56)
            Spacer()
        }
        .padding(.bottom, Spacing.xl)
        .background(Color.picBackground.opacity(0.3))
    }
}

/// Tap-to-coach button — the single trigger for an OpenAI call. Shows a spinner while in flight
/// and disables itself so a tap can't fire overlapping requests.
private struct AICoachButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.picSurfaceElevated)
                    .frame(width: 56, height: 56)
                if isLoading {
                    ProgressView()
                        .tint(Color.picAccent)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.picAccent)
                }
            }
        }
        .disabled(isLoading)
        .accessibilityLabel("Gợi ý AI")
    }
}
