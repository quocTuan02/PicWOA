import SwiftUI

enum Anim {
    static let fast:   Animation = .easeOut(duration: 0.15)
    static let normal: Animation = .easeOut(duration: 0.25)
    static let slow:   Animation = .easeOut(duration: 0.4)
    static let spring: Animation = .spring(response: 0.3, dampingFraction: 0.7)
}
