import Foundation

/// Minimal zip writer (stored entries, no compression) — enough to package a
/// `.pkpass`, whose handful of files are already small.
struct ZipArchive {
    private struct Entry {
        var name: Data
        var crc: UInt32
        var size: UInt32
        var offset: UInt32
    }

    private var body = Data()
    private var entries: [Entry] = []

    // A fixed DOS timestamp (2026-01-01 00:00) keeps archives deterministic.
    private static let dosTime: UInt16 = 0
    private static let dosDate: UInt16 = (46 << 9) | (1 << 5) | 1

    mutating func addFile(named name: String, data: Data) {
        let nameBytes = Data(name.utf8)
        let crc = ZipArchive.crc32(data)
        let entry = Entry(
            name: nameBytes,
            crc: crc,
            size: UInt32(data.count),
            offset: UInt32(body.count)
        )
        entries.append(entry)

        body.appendLE(UInt32(0x04034B50)) // local file header signature
        body.appendLE(UInt16(20)) // version needed
        body.appendLE(UInt16(0)) // flags
        body.appendLE(UInt16(0)) // method: stored
        body.appendLE(ZipArchive.dosTime)
        body.appendLE(ZipArchive.dosDate)
        body.appendLE(crc)
        body.appendLE(entry.size) // compressed size
        body.appendLE(entry.size) // uncompressed size
        body.appendLE(UInt16(nameBytes.count))
        body.appendLE(UInt16(0)) // extra length
        body.append(nameBytes)
        body.append(data)
    }

    func finalized() -> Data {
        var out = body
        let centralStart = UInt32(out.count)

        for entry in entries {
            out.appendLE(UInt32(0x02014B50)) // central directory signature
            out.appendLE(UInt16(20)) // version made by
            out.appendLE(UInt16(20)) // version needed
            out.appendLE(UInt16(0)) // flags
            out.appendLE(UInt16(0)) // method: stored
            out.appendLE(ZipArchive.dosTime)
            out.appendLE(ZipArchive.dosDate)
            out.appendLE(entry.crc)
            out.appendLE(entry.size)
            out.appendLE(entry.size)
            out.appendLE(UInt16(entry.name.count))
            out.appendLE(UInt16(0)) // extra length
            out.appendLE(UInt16(0)) // comment length
            out.appendLE(UInt16(0)) // disk number
            out.appendLE(UInt16(0)) // internal attributes
            out.appendLE(UInt32(0)) // external attributes
            out.appendLE(entry.offset)
            out.append(entry.name)
        }

        let centralSize = UInt32(out.count) - centralStart
        out.appendLE(UInt32(0x06054B50)) // end of central directory signature
        out.appendLE(UInt16(0)) // disk number
        out.appendLE(UInt16(0)) // central directory disk
        out.appendLE(UInt16(entries.count))
        out.appendLE(UInt16(entries.count))
        out.appendLE(centralSize)
        out.appendLE(centralStart)
        out.appendLE(UInt16(0)) // comment length
        return out
    }

    // MARK: - CRC32

    private static let crcTable: [UInt32] = (0..<256).map { index in
        var value = UInt32(index)
        for _ in 0..<8 {
            value = (value & 1) != 0 ? 0xEDB8_8320 ^ (value >> 1) : value >> 1
        }
        return value
    }

    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFF_FFFF
    }
}

private extension Data {
    mutating func appendLE(_ value: UInt16) {
        append(UInt8(value & 0xFF))
        append(UInt8(value >> 8))
    }

    mutating func appendLE(_ value: UInt32) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8(value >> 24))
    }
}
