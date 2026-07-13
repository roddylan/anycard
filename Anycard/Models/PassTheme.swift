import SwiftUI

/// The six color themes from the design packet.
/// Each theme defines a gradient background, a solid variant, and a foreground text color.
enum PassTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case forest
    case coral
    case midnight
    case sand
    case plum
    case slate

    var id: String { rawValue }

    /// Gradient stops (155° in the design; rendered top-leading → bottom-trailing).
    var gradientColors: [Color] {
        switch self {
        case .forest: [Color(hex: 0x455A4D), Color(hex: 0x33463C)]
        case .coral: [Color(hex: 0xCB6142), Color(hex: 0xB14A30)]
        case .midnight: [Color(hex: 0x2C2C33), Color(hex: 0x1E1E23)]
        case .sand: [Color(hex: 0xE7DBC0), Color(hex: 0xDACBA6)]
        case .plum: [Color(hex: 0x7E5CA8), Color(hex: 0x5F3F86)]
        case .slate: [Color(hex: 0x42506A), Color(hex: 0x333F54)]
        }
    }

    /// Solid fill hex (also used for exported Apple Wallet pass colors).
    var solidHex: UInt32 {
        switch self {
        case .forest: 0x3E5145
        case .coral: 0xC05939
        case .midnight: 0x26262B
        case .sand: 0xDDCEAB
        case .plum: 0x6E4E96
        case .slate: 0x3B4860
        }
    }

    /// Foreground hex (also used for exported Apple Wallet pass colors).
    var foregroundHex: UInt32 {
        switch self {
        case .forest: 0xECE6D5
        case .coral: 0xFBEEE6
        case .midnight: 0xF3F1EC
        case .sand: 0x3B352A
        case .plum: 0xF0E7F7
        case .slate: 0xE8EEF5
        }
    }

    /// Solid fill (also the swatch dot and the detail-screen background).
    var solid: Color { Color(hex: solidHex) }

    /// Foreground (text/icon) color on top of the theme background.
    var foreground: Color { Color(hex: foregroundHex) }

    /// Whether the theme background is dark (light status bar / light text).
    var isDark: Bool { self != .sand }

    var gradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: UnitPoint(x: 0.26, y: 0),
            endPoint: UnitPoint(x: 0.74, y: 1)
        )
    }
}

/// Solid vs. gradient background fill for non-photo templates.
enum BackgroundFill: String, Codable, CaseIterable, Sendable {
    case solid
    case gradient

    var label: String {
        switch self {
        case .solid: "Solid"
        case .gradient: "Gradient"
        }
    }
}
