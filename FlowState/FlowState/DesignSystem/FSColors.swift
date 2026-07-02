import SwiftUI

enum FSColors {
    static let bgPrimary    = Color(hex: "000000")
    static let bgSurface    = Color(hex: "0A0A0A")
    static let bgCard       = Color(hex: "111111")
    static let bgCardBorder = Color(hex: "1A1A1A")

    static let textPrimary   = Color.white
    static let textSecondary = Color(hex: "888888")
    static let textMuted     = Color(hex: "444444")

    // Contribution dot intensity levels
    static let dotL1 = Color(hex: "1A1A1A")
    static let dotL2 = Color(hex: "2A2A2A")
    static let dotL3 = Color(hex: "4A4A4A")
    static let dotL4 = Color(hex: "7A7A7A")
    static let dotL5 = Color.white
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
