import Foundation

/// The five pass layouts from the design packet.
enum PassTemplate: String, Codable, CaseIterable, Identifiable, Sendable {
    case minimal
    case membership
    case feature
    case poster
    case photo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .minimal: "Minimal"
        case .membership: "Membership"
        case .feature: "Feature"
        case .poster: "Poster"
        case .photo: "Full Photo"
        }
    }

    var hint: String {
        switch self {
        case .minimal: "Color only"
        case .membership: "Color + fields"
        case .feature: "Photo background"
        case .poster: "Photo + code below"
        case .photo: "Photo fills card"
        }
    }

    var systemImage: String {
        switch self {
        case .minimal: "rectangle.lefthalf.filled"
        case .membership: "person.text.rectangle"
        case .feature: "photo"
        case .poster: "photo.on.rectangle"
        case .photo: "viewfinder"
        }
    }

    /// Templates that show a user photo and therefore need one picked.
    var usesPhoto: Bool {
        switch self {
        case .feature, .poster, .photo: true
        case .minimal, .membership: false
        }
    }

    /// Templates where the photo fills the entire card (dark canvas, white text).
    var usesFullBleedPhoto: Bool {
        switch self {
        case .feature, .photo: true
        case .minimal, .membership, .poster: false
        }
    }

    /// The Background section (fill style + swatches + icon toggle) is hidden
    /// for full-bleed photo templates.
    var showsColorControls: Bool { !usesFullBleedPhoto }
}
