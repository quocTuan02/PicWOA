import SwiftUI

extension Color {
    // Background
    static let picBackground        = Color(hex: "#000000")
    static let picSurface           = Color(hex: "#1C1C1E")
    static let picSurfaceElevated   = Color(hex: "#2C2C2E")

    // Accent
    static let picAccent            = Color(hex: "#FFD60A")
    static let picAccentSecondary   = Color.white

    // Text
    static let picTextPrimary       = Color.white
    static let picTextSecondary     = Color.white.opacity(0.6)
    static let picTextTertiary      = Color.white.opacity(0.3)

    // Semantic
    static let picSuccess           = Color(hex: "#30D158")
    static let picWarning           = Color(hex: "#FFD60A")
    static let picError             = Color(hex: "#FF453A")
    static let picOverlay           = Color.black.opacity(0.4)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
