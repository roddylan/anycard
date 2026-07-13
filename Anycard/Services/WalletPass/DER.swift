import Foundation

/// Minimal DER (ASN.1) encoding helpers — just enough to assemble the CMS
/// `signature` file of a `.pkpass`.
enum DER {
    // MARK: - Encoding

    static func node(_ tag: UInt8, _ content: Data) -> Data {
        var out = Data([tag])
        out.append(encodedLength(content.count))
        out.append(content)
        return out
    }

    static func encodedLength(_ length: Int) -> Data {
        if length < 0x80 { return Data([UInt8(length)]) }
        var bytes: [UInt8] = []
        var value = length
        while value > 0 {
            bytes.insert(UInt8(value & 0xFF), at: 0)
            value >>= 8
        }
        return Data([0x80 | UInt8(bytes.count)] + bytes)
    }

    static func sequence(_ parts: [Data]) -> Data {
        node(0x30, join(parts))
    }

    /// SET OF with DER canonical ordering (elements sorted by encoded octets).
    static func setOf(_ parts: [Data]) -> Data {
        node(0x31, join(parts.sorted { lexicographicallyPrecedes($0, $1) }))
    }

    /// Context-specific constructed tag [n].
    static func contextTag(_ number: UInt8, _ content: Data) -> Data {
        node(0xA0 | number, content)
    }

    static func integer(_ value: UInt8) -> Data {
        // Values ≥ 0x80 would need a leading zero; only small versions are used here.
        node(0x02, Data([value]))
    }

    static func octetString(_ data: Data) -> Data {
        node(0x04, data)
    }

    static let null = Data([0x05, 0x00])

    static func objectID(_ arcs: [UInt]) -> Data {
        var content = Data([UInt8(arcs[0] * 40 + arcs[1])])
        for arc in arcs.dropFirst(2) {
            content.append(base128(arc))
        }
        return node(0x06, content)
    }

    static func utcTime(_ date: Date) -> Data {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMddHHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return node(0x17, Data(formatter.string(from: date).utf8))
    }

    // MARK: - Private

    private static func join(_ parts: [Data]) -> Data {
        parts.reduce(into: Data()) { $0.append($1) }
    }

    private static func base128(_ value: UInt) -> Data {
        var bytes: [UInt8] = [UInt8(value & 0x7F)]
        var rest = value >> 7
        while rest > 0 {
            bytes.insert(0x80 | UInt8(rest & 0x7F), at: 0)
            rest >>= 7
        }
        return Data(bytes)
    }

    private static func lexicographicallyPrecedes(_ a: Data, _ b: Data) -> Bool {
        a.lexicographicallyPrecedes(b)
    }
}

/// Minimal DER reader used to pull the exact issuer Name and serial number
/// out of an X.509 certificate for the CMS SignerInfo.
struct DERReader {
    private let bytes: [UInt8]
    private var offset = 0

    init(_ data: Data) {
        bytes = Array(data)
    }

    init(_ slice: [UInt8]) {
        bytes = slice
    }

    struct TLV {
        var tag: UInt8
        /// The value octets.
        var content: [UInt8]
        /// The complete tag + length + value encoding.
        var raw: [UInt8]
    }

    enum ParseError: Error {
        case truncated
    }

    mutating func readTLV() throws -> TLV {
        let start = offset
        guard offset < bytes.count else { throw ParseError.truncated }
        let tag = bytes[offset]
        offset += 1

        guard offset < bytes.count else { throw ParseError.truncated }
        var length = Int(bytes[offset])
        offset += 1
        if length & 0x80 != 0 {
            let count = length & 0x7F
            guard count <= 4, offset + count <= bytes.count else { throw ParseError.truncated }
            length = 0
            for _ in 0..<count {
                length = (length << 8) | Int(bytes[offset])
                offset += 1
            }
        }

        guard offset + length <= bytes.count else { throw ParseError.truncated }
        let content = Array(bytes[offset..<(offset + length)])
        offset += length
        return TLV(tag: tag, content: content, raw: Array(bytes[start..<offset]))
    }
}

enum CertificateParser {
    /// Extracts the exact `issuer` Name TLV and `serialNumber` INTEGER TLV
    /// from a certificate's DER encoding.
    static func issuerAndSerial(fromCertificate der: Data) throws -> (issuer: Data, serial: Data) {
        var certReader = DERReader(der)
        let certificate = try certReader.readTLV() // Certificate ::= SEQUENCE

        var tbsOuter = DERReader(certificate.content)
        let tbs = try tbsOuter.readTLV() // tbsCertificate ::= SEQUENCE

        var fields = DERReader(tbs.content)
        var serial = try fields.readTLV()
        if serial.tag == 0xA0 { // optional [0] EXPLICIT version
            serial = try fields.readTLV()
        }
        _ = try fields.readTLV() // signature AlgorithmIdentifier
        let issuer = try fields.readTLV() // issuer Name
        return (Data(issuer.raw), Data(serial.raw))
    }
}
