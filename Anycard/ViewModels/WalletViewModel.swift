import Foundation
import Observation

/// Navigation destinations pushed on the home stack.
enum Route: Hashable {
    case add
    case customize
}

/// Drives the whole add-a-card flow and top-level presentation:
/// home → scanner → customize → confirm, plus the detail overlay and toast.
@MainActor
@Observable
final class WalletViewModel {
    let store: CardStore

    var path: [Route] = []
    /// The in-progress pass being added or edited (nil when neither).
    var draft: Card?
    /// The saved card the draft is editing (nil when adding a new card).
    private(set) var editingCardID: UUID?
    var showConfirm = false
    var detailCardID: UUID?
    var manualEntry = false
    private(set) var toast: String?

    init(store: CardStore) {
        self.store = store
    }

    var detailCard: Card? {
        detailCardID.flatMap { store.card(id: $0) }
    }

    /// Whether the frontmost screen has dark chrome (drives status-bar style).
    var prefersDarkScheme: Bool {
        if showConfirm { return true }
        if let card = detailCard {
            return card.template.usesFullBleedPhoto || card.theme.isDark
        }
        return path.last == .add
    }

    // MARK: - Add flow

    func openAdd() {
        draft = Card.newDraft()
        manualEntry = false
        path.append(.add)
    }

    /// Shutter tap: pick a random code type + generated value (design behavior,
    /// also the Simulator path where no camera exists).
    func simulateScan() {
        guard var draft else { return }
        let type = CodeType.scannable.randomElement() ?? .qr
        draft.codeType = type
        draft.codeValue = Self.generatedValue(for: type)
        self.draft = draft
        pushCustomize()
    }

    /// A real camera detection.
    func handleScan(type: CodeType, value: String) {
        guard path.last == .add, var draft else { return }
        draft.codeType = type
        draft.codeValue = value
        self.draft = draft
        pushCustomize()
    }

    /// Manual entry "Continue": respects typed values, fills in the rest.
    func continueManualEntry() {
        guard var draft else { return }
        let type = draft.codeType ?? .code128
        draft.codeType = type
        if draft.codeValue.trimmingCharacters(in: .whitespaces).isEmpty {
            draft.codeValue = Self.generatedValue(for: type)
        }
        self.draft = draft
        pushCustomize()
    }

    /// "Code won't scan? Capture it as an image."
    func captureImageCode() {
        draft?.codeType = .image
        draft?.codeValue = ""
        pushCustomize()
    }

    private func pushCustomize() {
        guard path.last == .add else { return }
        path.append(.customize)
    }

    // MARK: - Confirm

    func addToWallet() {
        showConfirm = true
    }

    func cancelConfirm() {
        showConfirm = false
    }

    func confirmAdd() {
        guard var card = draft else { return }
        if card.name.trimmingCharacters(in: .whitespaces).isEmpty {
            card.name = "My card"
        }
        store.add(card)
        showConfirm = false
        draft = nil
        path = []
        showToast("Added to your wallet")
    }

    // MARK: - Edit

    var isEditing: Bool { editingCardID != nil }

    /// Opens Customize with a copy of a saved card.
    func beginEdit(_ card: Card) {
        draft = card
        editingCardID = card.id
        detailCardID = nil
        path = [.customize]
    }

    /// Writes the edited draft back to the store (no confirm step when editing).
    func saveEdits() {
        guard editingCardID != nil, var card = draft else { return }
        if card.name.trimmingCharacters(in: .whitespaces).isEmpty {
            card.name = "My card"
        }
        store.update(card)
        draft = nil
        editingCardID = nil
        path = []
        showToast("Changes saved")
    }

    /// Backing out of an edit discards the draft.
    func cancelEdit() {
        draft = nil
        editingCardID = nil
        path = []
    }

    // MARK: - Delete

    func delete(_ card: Card) {
        store.remove(id: card.id)
        showToast("Removed from your wallet")
    }

    // MARK: - Detail

    func openDetail(_ card: Card) {
        detailCardID = card.id
    }

    func closeDetail() {
        detailCardID = nil
    }

    func removeDetailCard() {
        guard let card = detailCard else { return }
        detailCardID = nil
        delete(card)
    }

    // MARK: - Toast

    func showToast(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(for: .seconds(2.4))
            if toast == message { toast = nil }
        }
    }

    /// Generated code values matching the design's formats (e.g. "QR-123456").
    static func generatedValue(for type: CodeType) -> String {
        switch type {
        case .qr: "QR-\(Int.random(in: 100_000...999_999))"
        case .code128: String(490_000_000_000 + Int.random(in: 0...9_999_999))
        case .pdf417: "PDF-\(Int.random(in: 10_000_000...99_999_999))"
        case .aztec: "AZ-\(Int.random(in: 1_000_000...9_999_999))"
        case .image: ""
        }
    }
}
