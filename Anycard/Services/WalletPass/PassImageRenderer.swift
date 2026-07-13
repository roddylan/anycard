import UIKit

/// Renders the PNG assets a `.pkpass` needs (icon, logo, optional thumbnail)
/// from the card's theme, glyph and photo.
@MainActor
enum PassImageRenderer {
    /// All image files for the pass, keyed by `.pkpass` filename.
    static func images(for card: Card) -> [String: Data] {
        var files: [String: Data] = [:]
        for scale in 1...3 {
            let suffix = scale == 1 ? "" : "@\(scale)x"
            files["icon\(suffix).png"] = iconPNG(for: card, scale: CGFloat(scale))
            files["logo\(suffix).png"] = logoPNG(for: card, scale: CGFloat(scale))
            if card.template.usesPhoto, let photo = ImageStore.image(named: card.photoFileName) {
                files["thumbnail\(suffix).png"] = thumbnailPNG(photo, scale: CGFloat(scale))
            }
        }
        return files
    }

    /// icon.png (29pt): theme-colored tile with the card's glyph.
    private static func iconPNG(for card: Card, scale: CGFloat) -> Data? {
        let side: CGFloat = 29
        return png(size: CGSize(width: side, height: side), scale: scale) { _ in
            UIColor(hex: WalletPassBuilder.backgroundHex(for: card)).setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: side, height: side))
            drawGlyph(for: card, pointSize: 15, centeredIn: CGSize(width: side, height: side))
        }
    }

    /// logo.png (shown top-left on the pass): the glyph on a transparent
    /// background, tinted for the pass background color.
    private static func logoPNG(for card: Card, scale: CGFloat) -> Data? {
        let size = CGSize(width: 40, height: 40)
        return png(size: size, scale: scale) { _ in
            drawGlyph(for: card, pointSize: 26, centeredIn: size)
        }
    }

    /// thumbnail.png: square aspect-fill crop of the card photo.
    private static func thumbnailPNG(_ photo: UIImage, scale: CGFloat) -> Data? {
        let side: CGFloat = 80
        let size = CGSize(width: side, height: side)
        return png(size: size, scale: scale) { _ in
            guard photo.size.width > 0, photo.size.height > 0 else { return }
            let fill = max(side / photo.size.width, side / photo.size.height)
            let drawSize = CGSize(width: photo.size.width * fill, height: photo.size.height * fill)
            photo.draw(in: CGRect(
                x: (side - drawSize.width) / 2,
                y: (side - drawSize.height) / 2,
                width: drawSize.width,
                height: drawSize.height
            ))
        }
    }

    // MARK: - Drawing helpers

    private static func png(
        size: CGSize,
        scale: CGFloat,
        draw: (UIGraphicsImageRendererContext) -> Void
    ) -> Data? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image(actions: draw).pngData()
    }

    private static func drawGlyph(for card: Card, pointSize: CGFloat, centeredIn size: CGSize) {
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        let tint = UIColor(hex: WalletPassBuilder.foregroundHex(for: card))
        guard let glyph = UIImage(systemName: card.icon.systemName, withConfiguration: configuration)?
            .withTintColor(tint, renderingMode: .alwaysOriginal) else { return }
        glyph.draw(in: CGRect(
            x: (size.width - glyph.size.width) / 2,
            y: (size.height - glyph.size.height) / 2,
            width: glyph.size.width,
            height: glyph.size.height
        ))
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
