import Foundation
import Testing
@testable import Anycard

@MainActor
struct WalletViewModelTests {
    private func makeModel() -> WalletViewModel {
        let directory = URL.temporaryDirectory.appending(path: "WalletVMTests-\(UUID().uuidString)")
        return WalletViewModel(store: CardStore(directory: directory, seedIfEmpty: false))
    }

    @Test func openAddCreatesDraftAndPushesScanner() {
        let model = makeModel()
        model.openAdd()
        #expect(model.draft != nil)
        #expect(model.path == [.add])
    }

    @Test func simulateScanFillsCodeAndPushesCustomize() {
        let model = makeModel()
        model.openAdd()
        model.simulateScan()
        #expect(model.path == [.add, .customize])
        #expect(model.draft?.codeType != nil)
        #expect(model.draft?.codeValue.isEmpty == false)
    }

    @Test func realScanUsesDetectedValue() {
        let model = makeModel()
        model.openAdd()
        model.handleScan(type: .qr, value: "MUS-102035")
        #expect(model.draft?.codeType == .qr)
        #expect(model.draft?.codeValue == "MUS-102035")
        #expect(model.path == [.add, .customize])
    }

    @Test func scanIgnoredWhenNotOnScanner() {
        let model = makeModel()
        model.handleScan(type: .qr, value: "X")
        #expect(model.path.isEmpty)
        #expect(model.draft == nil)
    }

    @Test func manualContinueRespectsTypedValues() {
        let model = makeModel()
        model.openAdd()
        model.draft?.codeType = .aztec
        model.draft?.codeValue = "AZ-777"
        model.continueManualEntry()
        #expect(model.draft?.codeType == .aztec)
        #expect(model.draft?.codeValue == "AZ-777")
        #expect(model.path == [.add, .customize])
    }

    @Test func manualContinueDefaultsToBarcodeAndGeneratesValue() {
        let model = makeModel()
        model.openAdd()
        model.continueManualEntry()
        #expect(model.draft?.codeType == .code128)
        #expect(model.draft?.codeValue.isEmpty == false)
    }

    @Test func captureImageCodeSetsImageType() {
        let model = makeModel()
        model.openAdd()
        model.captureImageCode()
        #expect(model.draft?.codeType == .image)
        #expect(model.draft?.codeValue.isEmpty == true)
        #expect(model.path == [.add, .customize])
    }

    @Test func confirmAddSavesCardAndResetsFlow() {
        let model = makeModel()
        model.openAdd()
        model.simulateScan()
        model.draft?.name = "Test Pass"
        model.addToWallet()
        #expect(model.showConfirm)

        model.confirmAdd()
        #expect(model.store.cards.first?.name == "Test Pass")
        #expect(model.path.isEmpty)
        #expect(model.draft == nil)
        #expect(!model.showConfirm)
        #expect(model.toast == "Added to your wallet")
    }

    @Test func confirmAddDefaultsEmptyNameToMyCard() {
        let model = makeModel()
        model.openAdd()
        model.simulateScan()
        model.confirmAdd()
        #expect(model.store.cards.first?.name == "My card")
    }

    @Test func beginEditCopiesCardAndOpensCustomize() {
        let model = makeModel()
        model.openAdd()
        model.simulateScan()
        model.draft?.name = "Original"
        model.confirmAdd()
        let card = model.store.cards[0]
        model.openDetail(card)

        model.beginEdit(card)
        #expect(model.isEditing)
        #expect(model.draft == card)
        #expect(model.detailCardID == nil)
        #expect(model.path == [.customize])
    }

    @Test func saveEditsUpdatesStoreAndResetsFlow() {
        let model = makeModel()
        model.openAdd()
        model.simulateScan()
        model.draft?.name = "Original"
        model.confirmAdd()
        let card = model.store.cards[0]

        model.beginEdit(card)
        model.draft?.name = "Edited"
        model.draft?.theme = .slate
        model.saveEdits()

        #expect(model.store.cards.count == 1)
        #expect(model.store.cards[0].id == card.id)
        #expect(model.store.cards[0].name == "Edited")
        #expect(model.store.cards[0].theme == .slate)
        #expect(!model.isEditing)
        #expect(model.draft == nil)
        #expect(model.path.isEmpty)
        #expect(model.toast == "Changes saved")
    }

    @Test func saveEditsDefaultsEmptyNameToMyCard() {
        let model = makeModel()
        model.openAdd()
        model.simulateScan()
        model.confirmAdd()
        let card = model.store.cards[0]

        model.beginEdit(card)
        model.draft?.name = "  "
        model.saveEdits()
        #expect(model.store.cards[0].name == "My card")
    }

    @Test func cancelEditDiscardsChanges() {
        let model = makeModel()
        model.openAdd()
        model.simulateScan()
        model.draft?.name = "Original"
        model.confirmAdd()
        let card = model.store.cards[0]

        model.beginEdit(card)
        model.draft?.name = "Edited"
        model.cancelEdit()

        #expect(model.store.cards[0].name == "Original")
        #expect(!model.isEditing)
        #expect(model.draft == nil)
        #expect(model.path.isEmpty)
    }

    @Test func deleteRemovesCardAndShowsToast() {
        let model = makeModel()
        model.openAdd()
        model.simulateScan()
        model.confirmAdd()
        let card = model.store.cards[0]

        model.delete(card)
        #expect(model.store.cards.isEmpty)
        #expect(model.toast == "Removed from your wallet")
    }

    @Test func removeDetailCardDeletesAndCloses() {
        let model = makeModel()
        model.openAdd()
        model.simulateScan()
        model.confirmAdd()
        let card = model.store.cards[0]
        model.openDetail(card)
        #expect(model.detailCard?.id == card.id)

        model.removeDetailCard()
        #expect(model.detailCardID == nil)
        #expect(model.store.cards.isEmpty)
    }

    @Test func generatedValuesMatchDesignFormats() {
        #expect(WalletViewModel.generatedValue(for: .qr).hasPrefix("QR-"))
        #expect(WalletViewModel.generatedValue(for: .pdf417).hasPrefix("PDF-"))
        #expect(WalletViewModel.generatedValue(for: .aztec).hasPrefix("AZ-"))
        let barcode = WalletViewModel.generatedValue(for: .code128)
        #expect(barcode.count == 12)
        #expect(barcode.allSatisfy { $0.isNumber })
        #expect(WalletViewModel.generatedValue(for: .image).isEmpty)
    }
}
