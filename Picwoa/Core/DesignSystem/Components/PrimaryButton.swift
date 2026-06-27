import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.picHeadline)
                .foregroundStyle(isDestructive ? Color.picError : Color.picBackground)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isDestructive ? Color.picError.opacity(0.15) : Color.picAccent)
                .clipShape(RoundedRectangle(cornerRadius: Radius.l))
        }
    }
}
