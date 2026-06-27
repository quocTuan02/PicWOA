import SwiftUI

struct CaptureButton: View {
    let isCapturing: Bool
    let isReadyToCapture: Bool
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isReadyToCapture {
                    Circle()
                        .stroke(Color.picAccent.opacity(0.4), lineWidth: 8)
                        .frame(width: 88, height: 88)
                        .scaleEffect(isPulsing ? 1.15 : 1.0)
                        .opacity(isPulsing ? 0 : 1)
                        .animation(
                            .easeOut(duration: 0.9).repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                }

                Circle()
                    .stroke(isReadyToCapture ? Color.picAccent : Color.white, lineWidth: 4)
                    .frame(width: 72, height: 72)
                    .animation(Anim.normal, value: isReadyToCapture)

                Circle()
                    .fill(isCapturing ? Color.picAccent : Color.white)
                    .frame(width: 58, height: 58)
                    .scaleEffect(isCapturing ? 0.85 : 1.0)
                    .animation(Anim.spring, value: isCapturing)
            }
        }
        .disabled(isCapturing)
        .accessibilityLabel(isReadyToCapture ? "Chụp ngay" : "Chụp ảnh")
        .onChange(of: isReadyToCapture) { _, ready in
            isPulsing = ready
        }
        .onAppear {
            isPulsing = isReadyToCapture
        }
    }
}

#Preview {
    HStack(spacing: 32) {
        CaptureButton(isCapturing: false, isReadyToCapture: false, action: {})
        CaptureButton(isCapturing: false, isReadyToCapture: true, action: {})
        CaptureButton(isCapturing: true, isReadyToCapture: false, action: {})
    }
    .padding()
    .background(Color.black)
}
