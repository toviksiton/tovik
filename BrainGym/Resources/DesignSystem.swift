import SwiftUI

// MARK: - Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design tokens
enum BrainGymColors {
    static let background   = Color(hex: "#0E0C0A")
    static let surface      = Color(hex: "#141210")
    static let accent       = Color(hex: "#C4622D")
    static let accentGreen  = Color(hex: "#4A7B5C")
    static let accentBlue   = Color(hex: "#5B7FA6")
    static let textPrimary  = Color(hex: "#F5F0E8")
    static let textMuted    = Color(hex: "#504540")
}

// MARK: - Font helpers
extension Font {
    static func display(_ size: CGFloat, weight: String = "Regular") -> Font {
        .custom("PlayfairDisplay-\(weight)", size: size)
    }
    static func mono(_ size: CGFloat, weight: String = "Regular") -> Font {
        .custom("DMMono-\(weight)", size: size)
    }
}

// MARK: - ChallengeType → Color
extension ChallengeType {
    var color: Color { Color(hex: colorHex) }
}
