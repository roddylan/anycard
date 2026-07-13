import Foundation
import PassKit
import Security
import Testing
@testable import Anycard

private let testConfiguration = WalletPassConfiguration(
    passTypeIdentifier: "pass.com.example.test",
    teamIdentifier: "TEAM123456",
    p12Password: "anycard"
)

// MARK: - pass.json

struct WalletPassBuilderTests {
    @Test func definitionCarriesIdentifiersAndSerial() {
        let card = Card.samples[0]
        let definition = WalletPassBuilder.definition(for: card, configuration: testConfiguration)
        #expect(definition.passTypeIdentifier == "pass.com.example.test")
        #expect(definition.teamIdentifier == "TEAM123456")
        #expect(definition.serialNumber == card.id.uuidString)
        #expect(definition.formatVersion == 1)
        #expect(definition.organizationName == "Iron & Oak")
    }

    @Test(arguments: [
        (CodeType.qr, "PKBarcodeFormatQR"),
        (CodeType.code128, "PKBarcodeFormatCode128"),
        (CodeType.pdf417, "PKBarcodeFormatPDF417"),
        (CodeType.aztec, "PKBarcodeFormatAztec"),
    ])
    func barcodeFormatsMap(type: CodeType, format: String) {
        var card = Card()
        card.codeType = type
        card.codeValue = "VALUE-1"
        let barcode = WalletPassBuilder.barcode(for: card)
        #expect(barcode?.format == format)
        #expect(barcode?.message == "VALUE-1")
        #expect(barcode?.messageEncoding == "iso-8859-1")
    }

    @Test func imageCodesAndEmptyValuesProduceNoBarcode() {
        var card = Card()
        card.codeType = .image
        card.codeValue = "ignored"
        #expect(WalletPassBuilder.barcode(for: card) == nil)

        card.codeType = .qr
        card.codeValue = ""
        #expect(WalletPassBuilder.barcode(for: card) == nil)
    }

    @Test func membershipTemplateMapsAllFields() {
        let card = Card.samples[0] // membership template
        let fields = WalletPassBuilder.fields(for: card)
        #expect(fields.headerFields.map(\.value) == ["Premier"])
        #expect(fields.primaryFields.map(\.value) == ["Marcus Web"])
        #expect(fields.secondaryFields.map(\.value) == ["123 456 789"])
        #expect(fields.auxiliaryFields.map(\.value) == ["06/2024", "06/2026", "Available"])
        #expect(fields.backFields.map(\.value) == ["Iron & Oak", "GYM-880213"])
    }

    @Test func themeColorsBecomeRGBStrings() {
        var card = Card()
        card.template = .membership
        card.theme = .forest
        let definition = WalletPassBuilder.definition(for: card, configuration: testConfiguration)
        #expect(definition.backgroundColor == "rgb(62,81,69)")
        #expect(definition.foregroundColor == "rgb(236,230,213)")
    }

    @Test func fullBleedPhotoTemplatesUseCanvasColors() {
        var card = Card()
        card.template = .photo
        card.theme = .coral
        let definition = WalletPassBuilder.definition(for: card, configuration: testConfiguration)
        #expect(definition.backgroundColor == "rgb(20,18,16)")
        #expect(definition.foregroundColor == "rgb(255,255,255)")
    }

    @Test func encodedPassJSONDecodesBack() throws {
        let card = Card.samples[1]
        let data = try WalletPassBuilder.encodedPassJSON(for: card, configuration: testConfiguration)
        let decoded = try JSONDecoder().decode(WalletPassDefinition.self, from: data)
        #expect(decoded == WalletPassBuilder.definition(for: card, configuration: testConfiguration))
    }
}

// MARK: - DER

struct DERTests {
    @Test func objectIDEncodesKnownVector() {
        // 1.2.840.113549.1.7.2 (CMS signedData)
        let expected = Data([0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x02])
        #expect(DER.objectID([1, 2, 840, 113549, 1, 7, 2]) == expected)
    }

    @Test func lengthEncodingSwitchesToLongForm() {
        #expect(DER.encodedLength(0x7F) == Data([0x7F]))
        #expect(DER.encodedLength(0x80) == Data([0x81, 0x80]))
        #expect(DER.encodedLength(0x1234) == Data([0x82, 0x12, 0x34]))
    }

    @Test func setOfSortsElementsByEncoding() {
        let a = DER.octetString(Data([0x02]))
        let b = DER.octetString(Data([0x01]))
        let set = DER.setOf([a, b])
        // Content should be b then a (lexicographic DER ordering).
        #expect(set == Data([0x31, 0x06]) + b + a)
    }

    @Test func utcTimeUsesUTCFormat() {
        let date = Date(timeIntervalSince1970: 0)
        let encoded = DER.utcTime(date)
        #expect(encoded == Data([0x17, 0x0D]) + Data("700101000000Z".utf8))
    }

    @Test func readerRoundTripsNestedStructures() throws {
        let inner = DER.sequence([DER.integer(1), DER.octetString(Data([0xAB]))])
        var reader = DERReader(inner)
        let tlv = try reader.readTLV()
        #expect(tlv.tag == 0x30)
        #expect(Data(tlv.raw) == inner)
    }
}

// MARK: - Zip

struct ZipArchiveTests {
    @Test func crc32MatchesKnownVector() {
        #expect(ZipArchive.crc32(Data("123456789".utf8)) == 0xCBF4_3926)
    }

    @Test func archiveHasZipStructure() {
        var archive = ZipArchive()
        archive.addFile(named: "pass.json", data: Data("{}".utf8))
        archive.addFile(named: "icon.png", data: Data([0x89, 0x50]))
        let data = archive.finalized()

        // Local header signature at the start, EOCD signature near the end.
        #expect(data.prefix(4) == Data([0x50, 0x4B, 0x03, 0x04]))
        let eocd = data.suffix(22)
        #expect(eocd.prefix(4) == Data([0x50, 0x4B, 0x05, 0x06]))
        // Entry count in the EOCD.
        #expect(eocd[eocd.startIndex + 10] == 2)
    }
}

// MARK: - Manifest & archive assembly

@MainActor
struct WalletPassExporterTests {
    @Test func manifestHashesAreSHA1Hex() throws {
        let manifest = try WalletPassExporter.manifestJSON(for: ["a.txt": Data("abc".utf8)])
        let decoded = try JSONDecoder().decode([String: String].self, from: manifest)
        #expect(decoded == ["a.txt": "a9993e364706816aba3e25717850c26c9cd0d89d"])
    }

    @Test func passDataContainsExpectedFiles() throws {
        let data = try WalletPassExporter.passData(
            for: Card.samples[0],
            configuration: testConfiguration,
            signing: nil
        )
        #expect(data.prefix(2) == Data("PK".utf8))
        for name in ["pass.json", "manifest.json", "icon.png", "icon@2x.png", "logo.png"] {
            #expect(data.range(of: Data(name.utf8)) != nil, "missing \(name)")
        }
    }

    /// PassKit rejects a pass whose `signature` file is missing, even in the
    /// Simulator (only the trust chain is unenforced there).
    @Test func unsignedPassDataIsRejectedByPassKit() throws {
        let data = try WalletPassExporter.passData(
            for: Card.samples[0],
            configuration: testConfiguration,
            signing: nil
        )
        #expect(throws: (any Error).self) { try PKPass(data: data) }
    }

    @Test func signedPassDataOpensAsPKPass() throws {
        let signing = SigningAssets(identity: try TestSigningFixture.identity(), intermediates: [])
        let data = try WalletPassExporter.passData(
            for: Card.samples[0],
            configuration: testConfiguration,
            signing: signing
        )
        let pass = try PKPass(data: data)
        #expect(pass.serialNumber == Card.samples[0].id.uuidString)
        #expect(pass.passType == .barcode)
    }
}

// MARK: - CMS signature

private final class FixtureToken {}

enum TestSigningFixture {
    static func identity() throws -> SecIdentity {
        let url = try #require(
            Bundle(for: FixtureToken.self).url(forResource: "TestSigning", withExtension: "p12")
        )
        let p12 = try Data(contentsOf: url)
        var items: CFArray?
        let options = [kSecImportExportPassphrase as String: "anycard"] as CFDictionary
        let status = SecPKCS12Import(p12 as CFData, options, &items)
        #expect(status == errSecSuccess)
        let first = try #require((items as? [[String: Any]])?.first)
        let value = try #require(first[kSecImportItemIdentity as String])
        #expect(CFGetTypeID(value as CFTypeRef) == SecIdentityGetTypeID())
        return value as! SecIdentity
    }
}

struct CMSSignerTests {
    @Test func signatureIsWellFormedSignedData() throws {
        let identity = try TestSigningFixture.identity()
        let manifest = Data(#"{"pass.json":"00"}"#.utf8)
        let signature = try CMSSigner.sign(manifest: manifest, identity: identity, intermediates: [])

        // Outer SEQUENCE wrapping the signedData OID.
        var reader = DERReader(signature)
        let outer = try reader.readTLV()
        #expect(outer.tag == 0x30)
        let signedDataOID = Data([0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x02])
        #expect(Data(outer.content).prefix(signedDataOID.count) == signedDataOID)

        // The signer certificate is embedded.
        var certificateRef: SecCertificate?
        SecIdentityCopyCertificate(identity, &certificateRef)
        let certificate = try #require(certificateRef.map { SecCertificateCopyData($0) as Data })
        #expect(signature.range(of: certificate) != nil)
    }
}
