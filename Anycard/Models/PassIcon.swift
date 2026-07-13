import Foundation

/// The ten pickable pass icons (Phosphor names in the design, mapped to SF Symbols).
enum PassIcon: String, Codable, CaseIterable, Identifiable, Sendable {
    case barbell
    case train
    case coffee
    case storefront
    case ticket
    case book
    case butterfly
    case key
    case heart
    case mountains

    var id: String { rawValue }

    var systemName: String {
        switch self {
        case .barbell: "dumbbell.fill"
        case .train: "tram.fill"
        case .coffee: "cup.and.saucer.fill"
        case .storefront: "storefront.fill"
        case .ticket: "ticket.fill"
        case .book: "book.fill"
        case .butterfly: "bird.fill"
        case .key: "key.fill"
        case .heart: "heart.fill"
        case .mountains: "mountain.2.fill"
        }
    }
}
