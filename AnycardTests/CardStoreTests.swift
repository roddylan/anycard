import Foundation
import Testing
@testable import Anycard

@MainActor
struct CardStoreTests {
    private func makeTempDirectory() -> URL {
        let url = URL.temporaryDirectory.appending(path: "CardStoreTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func seedsSampleCardsOnFirstLaunch() {
        let store = CardStore(directory: makeTempDirectory())
        #expect(store.cards.count == 4)
        #expect(store.cards.first?.name == "Marcus Web")
    }

    @Test func startsEmptyWhenSeedingDisabled() {
        let store = CardStore(directory: makeTempDirectory(), seedIfEmpty: false)
        #expect(store.cards.isEmpty)
    }

    @Test func addPrependsCard() {
        let store = CardStore(directory: makeTempDirectory())
        var card = Card.newDraft()
        card.name = "New Pass"
        store.add(card)
        #expect(store.cards.count == 5)
        #expect(store.cards.first?.name == "New Pass")
    }

    @Test func persistsAcrossInstances() {
        let directory = makeTempDirectory()
        let store = CardStore(directory: directory)
        var card = Card.newDraft()
        card.name = "Persisted"
        card.codeType = .qr
        card.codeValue = "QR-123456"
        store.add(card)

        let reloaded = CardStore(directory: directory)
        #expect(reloaded.cards.count == 5)
        #expect(reloaded.cards.first?.name == "Persisted")
        #expect(reloaded.cards.first?.codeType == .qr)
        #expect(reloaded.cards.first?.codeValue == "QR-123456")
    }

    @Test func removeDeletesCardAndPersists() {
        let directory = makeTempDirectory()
        let store = CardStore(directory: directory)
        let id = store.cards[0].id
        store.remove(id: id)
        #expect(store.cards.count == 3)
        #expect(store.card(id: id) == nil)

        let reloaded = CardStore(directory: directory)
        #expect(reloaded.cards.count == 3)
    }

    @Test func updateReplacesCardInPlaceAndPersists() {
        let directory = makeTempDirectory()
        let store = CardStore(directory: directory)
        var card = store.cards[1]
        card.name = "Renamed"
        card.theme = .midnight
        store.update(card)

        #expect(store.cards[1].name == "Renamed")
        #expect(store.cards[1].theme == .midnight)
        #expect(store.cards.count == 4)

        let reloaded = CardStore(directory: directory)
        #expect(reloaded.cards[1].name == "Renamed")
    }

    @Test func updateIgnoresUnknownCard() {
        let store = CardStore(directory: makeTempDirectory())
        var stranger = Card.newDraft()
        stranger.name = "Ghost"
        store.update(stranger)
        #expect(store.cards.count == 4)
        #expect(!store.cards.contains { $0.name == "Ghost" })
    }

    @Test func lookupFindsCardById() {
        let store = CardStore(directory: makeTempDirectory())
        let sample = store.cards[2]
        #expect(store.card(id: sample.id)?.name == sample.name)
    }
}
