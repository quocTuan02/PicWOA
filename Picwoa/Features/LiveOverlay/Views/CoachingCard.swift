import SwiftUI

struct CoachingCard: View {
    let message: String
    let direction: Direction?
    let isReady: Bool

    var body: some View {
        HStack(spacing: Spacing.s) {
            if let direction {
                DirectionArrow(direction: direction)
            }
            Text(message)
                .font(.picCoaching)
                .foregroundStyle(isReady ? Color.picSuccess : Color.picTextPrimary)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
    }
}
