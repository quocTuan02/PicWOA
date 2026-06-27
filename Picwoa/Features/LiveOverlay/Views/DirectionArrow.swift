import SwiftUI

struct DirectionArrow: View {
    let direction: Direction

    var systemName: String {
        switch direction {
        case .up:           return "arrow.up"
        case .down:         return "arrow.down"
        case .left:         return "arrow.left"
        case .right:        return "arrow.right"
        case .rotateLeft:   return "arrow.counterclockwise"
        case .rotateRight:  return "arrow.clockwise"
        case .forward:      return "arrow.up.circle"
        case .backward:     return "arrow.down.circle"
        }
    }

    var body: some View {
        Image(systemName: systemName)
            .font(.picHeadline)
            .foregroundStyle(Color.picAccent)
            .accessibilityHidden(true)
    }
}
