import Foundation

/// Supported code formats. `image` means the user stored a photo of the code.
enum CodeType: String, Codable, CaseIterable, Identifiable, Sendable {
    case qr
    case code128
    case pdf417
    case aztec
    case image

    var id: String { rawValue }

    var label: String {
        switch self {
        case .qr: "QR Code"
        case .code128: "Barcode"
        case .pdf417: "PDF417"
        case .aztec: "Aztec"
        case .image: "Image code"
        }
    }

    /// The four formats that can be generated/scanned (everything except `image`).
    static var scannable: [CodeType] { [.qr, .code128, .pdf417, .aztec] }

    /// Square code boxes for QR/Aztec, wide strips for the 1D-ish formats.
    var isSquare: Bool {
        switch self {
        case .qr, .aztec, .image: true
        case .code128, .pdf417: false
        }
    }
}
