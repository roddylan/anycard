import Foundation

/// Codable model of a Wallet `pass.json` for a generic pass.
/// See "Pass Design and Creation" in the Wallet developer guide.
struct WalletPassDefinition: Codable, Equatable {
    var formatVersion = 1
    var passTypeIdentifier: String
    var serialNumber: String
    var teamIdentifier: String
    var organizationName: String
    var description: String
    var logoText: String
    var foregroundColor: String
    var backgroundColor: String
    var labelColor: String
    var barcodes: [Barcode]?
    var generic: FieldSets

    struct Barcode: Codable, Equatable {
        var format: String
        var message: String
        var messageEncoding = "iso-8859-1"
        var altText: String?
    }

    struct FieldSets: Codable, Equatable {
        var headerFields: [Field] = []
        var primaryFields: [Field] = []
        var secondaryFields: [Field] = []
        var auxiliaryFields: [Field] = []
        var backFields: [Field] = []
    }

    struct Field: Codable, Equatable {
        var key: String
        var label: String?
        var value: String
    }
}
