import Foundation
import Testing
@testable import Anycard

struct CardTests {
    @Test func emptyFieldsFallBackToPlaceholders() {
        let card = Card()
        #expect(card.displayName == "Your name")
        #expect(card.displayOrg == "Organization")
        #expect(card.displayTier == "Member")
        #expect(card.displayMemberId == "000 000 000")
        #expect(card.displaySince == "01/2025")
        #expect(card.displayExpires == "01/2027")
        #expect(card.displayGuestPass == "None")
        #expect(card.displayGuestNo == "000000")
        #expect(card.displayPassType == "Standard")
    }

    @Test func filledFieldsAreUsedVerbatim() {
        var card = Card()
        card.name = "Ana Reyes"
        card.org = "Metro Transit"
        #expect(card.displayName == "Ana Reyes")
        #expect(card.displayOrg == "Metro Transit")
    }

    @Test func whitespaceOnlyFieldsFallBack() {
        var card = Card()
        card.name = "   "
        #expect(card.displayName == "Your name")
    }

    @Test func codeLabelReflectsType() {
        var card = Card()
        #expect(card.codeLabel == "Barcode")
        card.codeType = .qr
        #expect(card.codeLabel == "QR Code")
        card.codeType = .image
        #expect(card.codeLabel == "Image code")
    }

    @Test func watermarkOnlyOnColorTemplatesWhenEnabled() {
        var card = Card()
        card.showsIconBackground = true
        card.template = .membership
        #expect(card.showsWatermarkIcon)
        card.template = .minimal
        #expect(card.showsWatermarkIcon)
        card.template = .feature
        #expect(!card.showsWatermarkIcon)
        card.template = .membership
        card.showsIconBackground = false
        #expect(!card.showsWatermarkIcon)
    }

    @Test func newDraftMatchesDesignDefaults() {
        let draft = Card.newDraft()
        #expect(draft.template == .membership)
        #expect(draft.theme == .coral)
        #expect(draft.fill == .gradient)
        #expect(draft.showsIconBackground)
        #expect(draft.icon == .barbell)
        #expect(draft.codeType == nil)
        #expect(draft.tier == "Standard")
        #expect(draft.guestPass == "Available")
        #expect(draft.passType == "Member Pass")
    }

    @Test func templateTraitsMatchDesign() {
        #expect(PassTemplate.minimal.showsColorControls)
        #expect(PassTemplate.membership.showsColorControls)
        #expect(PassTemplate.poster.showsColorControls)
        #expect(!PassTemplate.feature.showsColorControls)
        #expect(!PassTemplate.photo.showsColorControls)

        #expect(!PassTemplate.minimal.usesPhoto)
        #expect(!PassTemplate.membership.usesPhoto)
        #expect(PassTemplate.feature.usesPhoto)
        #expect(PassTemplate.poster.usesPhoto)
        #expect(PassTemplate.photo.usesPhoto)
    }
}
