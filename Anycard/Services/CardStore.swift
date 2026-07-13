import Foundation
import Observation

/// Persistent store for wallet cards. Cards are saved as JSON in
/// Application Support; the wallet is seeded with sample passes on first launch.
@MainActor
@Observable
final class CardStore {
    private(set) var cards: [Card] = []

    private let fileURL: URL

    /// - Parameters:
    ///   - directory: storage directory override (used by tests). Defaults to Application Support.
    ///   - seedIfEmpty: seed sample cards when no saved file exists.
    init(directory: URL? = nil, seedIfEmpty: Bool = true) {
        let base = directory ?? URL.applicationSupportDirectory.appending(path: "Anycard")
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        fileURL = base.appending(path: "cards.json")
        load(seedIfEmpty: seedIfEmpty)
    }

    /// Newly added cards go to the top of the wallet.
    func add(_ card: Card) {
        cards.insert(card, at: 0)
        save()
    }

    /// Replaces the stored card with the same id (no-op if it was deleted meanwhile).
    func update(_ card: Card) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        cards[index] = card
        save()
    }

    func remove(id: UUID) {
        cards.removeAll { $0.id == id }
        save()
    }

    func card(id: UUID) -> Card? {
        cards.first { $0.id == id }
    }

    // MARK: - Persistence

    private func load(seedIfEmpty: Bool) {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Card].self, from: data) {
            cards = decoded
        } else if seedIfEmpty {
            cards = Card.samples
            save()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(cards) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
