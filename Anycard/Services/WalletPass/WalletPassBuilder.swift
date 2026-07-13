import Foundation

/// Builds the `pass.json` content for a card, mirroring the app's template layouts.
enum WalletPassBuilder {
    static func definition(for card: Card, configuration: WalletPassConfiguration) -> WalletPassDefinition {
        WalletPassDefinition(
            passTypeIdentifier: configuration.passTypeIdentifier,
            serialNumber: card.id.uuidString,
            teamIdentifier: configuration.teamIdentifier,
            organizationName: card.displayOrg,
            description: "\(card.displayOrg) pass",
            logoText: card.displayOrg,
            foregroundColor: rgbString(foregroundHex(for: card)),
            backgroundColor: rgbString(backgroundHex(for: card)),
            labelColor: rgbString(foregroundHex(for: card)),
            barcodes: barcode(for: card).map { [$0] },
            generic: fields(for: card)
        )
    }

    static func encodedPassJSON(for card: Card, configuration: WalletPassConfiguration) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(definition(for: card, configuration: configuration))
    }

    // MARK: - Colors

    /// Full-bleed photo templates use the dark photo canvas (Palette.photoCanvas)
    /// with white text; everything else uses the theme's solid colors.
    static func backgroundHex(for card: Card) -> UInt32 {
        card.template.usesFullBleedPhoto ? 0x141210 : card.theme.solidHex
    }

    static func foregroundHex(for card: Card) -> UInt32 {
        card.template.usesFullBleedPhoto ? 0xFFFFFF : card.theme.foregroundHex
    }

    static func rgbString(_ hex: UInt32) -> String {
        "rgb(\((hex >> 16) & 0xFF),\((hex >> 8) & 0xFF),\(hex & 0xFF))"
    }

    // MARK: - Barcode

    /// Image-captured codes have no encodable payload, so they get no Wallet barcode.
    static func barcode(for card: Card) -> WalletPassDefinition.Barcode? {
        guard let type = card.codeType, !card.codeValue.isEmpty else { return nil }
        let format: String
        switch type {
        case .qr: format = "PKBarcodeFormatQR"
        case .code128: format = "PKBarcodeFormatCode128"
        case .pdf417: format = "PKBarcodeFormatPDF417"
        case .aztec: format = "PKBarcodeFormatAztec"
        case .image: return nil
        }
        return WalletPassDefinition.Barcode(format: format, message: card.codeValue, altText: card.codeValue)
    }

    // MARK: - Fields

    /// Field placement follows each template's on-card layout as closely as
    /// the generic pass structure allows.
    static func fields(for card: Card) -> WalletPassDefinition.FieldSets {
        var sets = WalletPassDefinition.FieldSets()

        switch card.template {
        case .minimal:
            sets.headerFields = [field("tier", "TIER", card.displayTier)]
            sets.primaryFields = [field("name", "MEMBER", card.displayName)]
        case .membership:
            sets.headerFields = [field("tier", "MEMBERSHIP", card.displayTier)]
            sets.primaryFields = [field("name", "MEMBER NAME", card.displayName)]
            sets.secondaryFields = [field("memberId", "MEMBER ID", card.displayMemberId)]
            sets.auxiliaryFields = [
                field("since", "SINCE", card.displaySince),
                field("expires", "EXPIRES", card.displayExpires),
                field("guestPass", "GUEST PASS", card.displayGuestPass),
            ]
        case .feature, .photo:
            sets.headerFields = [field("guestNo", "GUEST NO.", card.displayGuestNo)]
            sets.primaryFields = [field("name", "MEMBER NAME", card.displayName)]
            sets.secondaryFields = [field("passType", "PASS TYPE", card.displayPassType)]
            sets.auxiliaryFields = [field("expires", "EXPIRES", card.displayExpires)]
        case .poster:
            sets.primaryFields = [field("name", "MEMBER", card.displayName)]
            sets.secondaryFields = [field("passType", "PASS TYPE", card.displayPassType)]
            sets.auxiliaryFields = [field("expires", "EXPIRES", card.displayExpires)]
        }

        sets.backFields = [field("org", "ORGANIZATION", card.displayOrg)]
        if !card.codeValue.isEmpty {
            sets.backFields.append(field("code", "CODE", card.codeValue))
        }
        return sets
    }

    private static func field(_ key: String, _ label: String, _ value: String) -> WalletPassDefinition.Field {
        WalletPassDefinition.Field(key: key, label: label, value: value)
    }
}
