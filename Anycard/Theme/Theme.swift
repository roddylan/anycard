import SwiftUI

extension Color {
    /// Color from a 0xRRGGBB literal.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// App-wide design tokens from the design packet.
enum Palette {
    /// Light screen background.
    static let screen = Color(hex: 0xF4F1EA)
    /// Dark scanner screen background.
    static let scannerBackground = Color(hex: 0x12110E)
    /// Primary text.
    static let ink = Color(hex: 0x221E17)
    /// Muted text.
    static let muted = Color(hex: 0x8A8478)
    /// Fainter field labels.
    static let faintLabel = Color(hex: 0xA39B8B)
    /// Primary accent (buttons, active ring).
    static let accent = Color(hex: 0xC6512F)
    /// Secondary accent on dark surfaces (links).
    static let accentOnDark = Color(hex: 0xE7724E)
    /// Input border.
    static let inputBorder = Color(hex: 0xE4DFD3)
    /// Segmented-control track.
    static let segmentTrack = Color(hex: 0xEBE6DA)
    /// Hint panel background / border / icon / text.
    static let hintBackground = Color(hex: 0xF0E9DA)
    static let hintBorder = Color(hex: 0xD8CDB4)
    static let hintIcon = Color(hex: 0xB8703E)
    static let hintText = Color(hex: 0x6E675A)
    /// Toast check icon.
    static let toastCheck = Color(hex: 0x8FC79E)
    /// Barcode ink on the white code box.
    static let codeInk = Color(hex: 0x141410)
    /// Dark canvas behind full-bleed photo passes.
    static let photoCanvas = Color(hex: 0x141210)
    /// Inactive toggle track.
    static let toggleOff = Color(hex: 0xD8D2C4)
}

/// Design fonts. Fall back to system styles automatically if the custom
/// font failed to register (Font.custom falls back to the system font).
enum AppFont {
    /// Newsreader — display serif for titles, org and member names.
    static func serif(_ size: CGFloat, semiBold: Bool = false) -> Font {
        .custom(semiBold ? "Newsreader16pt16pt-SemiBold" : "Newsreader16pt16pt-Medium", size: size)
    }

    enum SansWeight { case regular, medium, semiBold, bold }

    /// Hanken Grotesk — UI text, labels, buttons.
    static func sans(_ size: CGFloat, _ weight: SansWeight = .regular) -> Font {
        switch weight {
        case .regular: .custom("HankenGrotesk-Regular", size: size)
        case .medium: .custom("HankenGrotesk-Medium", size: size)
        case .semiBold: .custom("HankenGrotesk-SemiBold", size: size)
        case .bold: .custom("HankenGrotesk-Bold", size: size)
        }
    }

    /// JetBrains Mono — code values, member IDs, dates.
    static func mono(_ size: CGFloat, semiBold: Bool = false) -> Font {
        .custom(semiBold ? "JetBrainsMono-SemiBold" : "JetBrainsMono-Medium", size: size)
    }
}

// MARK: - Shared small styles

/// Uppercase section/eyebrow label ("TEMPLATE", "ICON", …).
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(AppFont.sans(12, .semiBold))
            .tracking(1.1)
            .foregroundStyle(Palette.muted)
    }
}

/// Press feedback used on cards, swatches and icon tiles.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.972

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}
