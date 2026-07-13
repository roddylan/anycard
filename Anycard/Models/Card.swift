import Foundation

/// A saved wallet pass. Also used as the in-progress draft while adding a card.
struct Card: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id = UUID()
    var name = ""
    var org = ""
    var tier = ""
    var memberId = ""
    var since = ""
    var expires = ""
    var guestPass = ""
    var guestNo = ""
    var passType = ""
    var template = PassTemplate.membership
    var theme = PassTheme.coral
    var fill = BackgroundFill.gradient
    var showsIconBackground = true
    var icon = PassIcon.barbell
    var codeType: CodeType?
    var codeValue = ""
    /// Filename (in the image store) of the pass background photo.
    var photoFileName: String?
    /// Filename (in the image store) of the photographed code, when `codeType == .image`.
    var codePhotoFileName: String?
}

// MARK: - Display fallbacks (empty fields render placeholder defaults on the pass)

extension Card {
    var displayName: String { fallback(name, "Your name") }
    var displayOrg: String { fallback(org, "Organization") }
    var displayTier: String { fallback(tier, "Member") }
    var displayMemberId: String { fallback(memberId, "000 000 000") }
    var displaySince: String { fallback(since, "01/2025") }
    var displayExpires: String { fallback(expires, "01/2027") }
    var displayGuestPass: String { fallback(guestPass, "None") }
    var displayGuestNo: String { fallback(guestNo, "000000") }
    var displayPassType: String { fallback(passType, "Standard") }

    /// Code-format label shown on the wallet row.
    var codeLabel: String { codeType?.label ?? "Barcode" }

    /// Watermark icon shows only on color templates when enabled.
    var showsWatermarkIcon: Bool {
        (template == .minimal || template == .membership) && showsIconBackground
    }

    private func fallback(_ value: String, _ placeholder: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? placeholder : trimmed
    }
}

// MARK: - Fresh draft & sample data

extension Card {
    /// The starting draft when the user taps "Add a card" (matches the design's defaults).
    static func newDraft() -> Card {
        Card(
            tier: "Standard",
            guestPass: "Available",
            passType: "Member Pass",
            template: .membership,
            theme: .coral,
            fill: .gradient,
            showsIconBackground: true,
            icon: .barbell
        )
    }

    /// The four sample passes the wallet is seeded with on first launch.
    static let samples: [Card] = [
        Card(
            name: "Marcus Web", org: "Iron & Oak", tier: "Premier",
            memberId: "123 456 789", since: "06/2024", expires: "06/2026",
            guestPass: "Available",
            template: .membership, theme: .forest, fill: .gradient,
            showsIconBackground: true, icon: .barbell,
            codeType: .qr, codeValue: "GYM-880213"
        ),
        Card(
            name: "Ryan Notch", org: "City Museum",
            expires: "01/2027", guestNo: "102035", passType: "Family Pass",
            template: .feature, theme: .slate, fill: .gradient,
            showsIconBackground: false, icon: .butterfly,
            codeType: .qr, codeValue: "MUS-102035"
        ),
        Card(
            name: "Field & Roast", org: "Rewards", tier: "Gold",
            template: .minimal, theme: .sand, fill: .solid,
            showsIconBackground: true, icon: .coffee,
            codeType: .code128, codeValue: "490154203237518"
        ),
        Card(
            name: "Ana Reyes", org: "Metro Transit", tier: "Commuter",
            memberId: "4471 902 03", since: "02/2023", expires: "12/2026",
            guestPass: "None",
            template: .membership, theme: .plum, fill: .gradient,
            showsIconBackground: true, icon: .train,
            codeType: .pdf417, codeValue: "TRN-4471902"
        ),
    ]
}
