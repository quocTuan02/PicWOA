import SwiftUI

struct CaptureButton: View {
    let isCapturing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 72, height: 72)
                Circle()
                    .fill(isCapturing ? Color.picAccent : Color.white)
                    .frame(width: 58, height: 58)
                    .scaleEffect(isCapturing ? 0.85 : 1.0)
                    .animation(Anim.spring, value: isCapturing)
            }
        }
        .disabled(isCapturing)
        .accessibilityLabel("Chụp ảnh")
    }
}
