import CoreImage.CIFilterBuiltins
import UIKit

/// Renders real, scannable codes with Core Image (QR, Code 128, PDF417, Aztec).
/// Output is dark ink (#141410) on transparent, meant for a white code box.
@MainActor
enum BarcodeRenderer {
    private static let context = CIContext()
    private static let cache = NSCache<NSString, UIImage>()

    /// Generates a code image for the given type and value, or nil for
    /// `.image` codes / unencodable values. Results are cached.
    static func image(type: CodeType, value: String) -> UIImage? {
        let key = "\(type.rawValue)|\(value)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = render(type: type, value: value) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    private static func render(type: CodeType, value: String) -> UIImage? {
        guard type != .image, !value.isEmpty,
              let message = value.data(using: .ascii) ?? value.data(using: .utf8)
        else { return nil }

        let filter: CIFilter
        switch type {
        case .qr:
            let f = CIFilter.qrCodeGenerator()
            f.message = message
            f.correctionLevel = "M"
            filter = f
        case .code128:
            let f = CIFilter.code128BarcodeGenerator()
            f.message = message
            f.quietSpace = 0
            filter = f
        case .pdf417:
            let f = CIFilter.pdf417BarcodeGenerator()
            f.message = message
            filter = f
        case .aztec:
            let f = CIFilter.aztecCodeGenerator()
            f.message = message
            filter = f
        case .image:
            return nil
        }

        guard let output = filter.outputImage else { return nil }

        // Map black modules to the design's ink color, white to transparent.
        let colored = output.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(red: 20 / 255, green: 20 / 255, blue: 16 / 255),
            "inputColor1": CIColor(red: 1, green: 1, blue: 1, alpha: 0),
        ])

        // Upscale with nearest-neighbor so modules stay crisp.
        let scale = max(1, (720 / max(output.extent.width, 1)).rounded(.down))
        let scaled = colored.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
