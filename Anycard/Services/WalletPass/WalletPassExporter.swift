import CryptoKit
import PassKit
import Security
import UIKit

enum WalletPassError: LocalizedError {
    case signingNotConfigured
    case signingAssetsUnreadable(message: String)
    case invalidPass(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .signingNotConfigured:
            return "Wallet export needs a pass signing certificate. See docs/apple-wallet.md."
        case .signingAssetsUnreadable(let message):
            return "The pass signing certificate could not be loaded: \(message)"
        case .invalidPass(let error):
            return error.localizedDescription
        }
    }
}

/// Assembles a card into a `.pkpass` and hands it to PassKit.
@MainActor
enum WalletPassExporter {
    /// Builds the PKPass shown by `PKAddPassesViewController`.
    static func pass(for card: Card, configuration: WalletPassConfiguration = .default) throws -> PKPass {
        let signing = try SigningAssets.load(configuration: configuration)
        let data = try passData(for: card, configuration: configuration, signing: signing)
        do {
            return try PKPass(data: data)
        } catch {
            // Without a certificate the pass is unsigned, which the Simulator
            // accepts but a real device rejects — point at setup, not PassKit.
            if signing == nil { throw WalletPassError.signingNotConfigured }
            throw WalletPassError.invalidPass(underlying: error)
        }
    }

    /// The raw `.pkpass` archive (exposed for tests).
    static func passData(
        for card: Card,
        configuration: WalletPassConfiguration,
        signing: SigningAssets?
    ) throws -> Data {
        var files = PassImageRenderer.images(for: card)
        files["pass.json"] = try WalletPassBuilder.encodedPassJSON(for: card, configuration: configuration)

        let manifest = try manifestJSON(for: files)
        files["manifest.json"] = manifest
        if let signing {
            files["signature"] = try CMSSigner.sign(
                manifest: manifest,
                identity: signing.identity,
                intermediates: signing.intermediates
            )
        }

        var archive = ZipArchive()
        for name in files.keys.sorted() {
            guard let data = files[name] else { continue }
            archive.addFile(named: name, data: data)
        }
        return archive.finalized()
    }

    /// manifest.json: SHA-1 of every file in the pass, keyed by filename.
    static func manifestJSON(for files: [String: Data]) throws -> Data {
        let hashes = files.mapValues { data in
            Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(hashes)
    }
}

/// The signing identity (Pass Type ID certificate) bundled with the app, plus
/// Apple's WWDR intermediate certificate.
struct SigningAssets {
    var identity: SecIdentity
    var intermediates: [Data]

    /// Returns nil when no certificate is bundled; throws when a certificate
    /// exists but can't be read. In the Simulator — which doesn't enforce the
    /// pass trust chain — a bundled self-signed dev certificate is used as a
    /// fallback so the Wallet flow works without a paid developer account.
    static func load(configuration: WalletPassConfiguration) throws -> SigningAssets? {
        if let p12URL = Bundle.main.url(forResource: "PassSigning", withExtension: "p12") {
            return try load(p12URL: p12URL, password: configuration.p12Password)
        }
        #if targetEnvironment(simulator)
        if let devURL = Bundle.main.url(forResource: "PassSigningDev", withExtension: "p12") {
            return try? load(p12URL: devURL, password: "anycard")
        }
        #endif
        return nil
    }

    private static func load(p12URL: URL, password: String) throws -> SigningAssets {
        let p12Data: Data
        do {
            p12Data = try Data(contentsOf: p12URL)
        } catch {
            throw WalletPassError.signingAssetsUnreadable(message: error.localizedDescription)
        }

        var items: CFArray?
        let options = [kSecImportExportPassphrase as String: password] as CFDictionary
        let status = SecPKCS12Import(p12Data as CFData, options, &items)
        guard status == errSecSuccess,
              let first = (items as? [[String: Any]])?.first,
              let identityValue = first[kSecImportItemIdentity as String],
              CFGetTypeID(identityValue as CFTypeRef) == SecIdentityGetTypeID() else {
            throw WalletPassError.signingAssetsUnreadable(message: "PKCS#12 import failed (status \(status)).")
        }
        // Type verified via CFGetTypeID above; CF types can't be downcast conditionally.
        let identity = identityValue as! SecIdentity

        var intermediates: [Data] = []
        if let wwdrURL = Bundle.main.url(forResource: "PassSigningWWDR", withExtension: "cer"),
           let wwdr = try? Data(contentsOf: wwdrURL) {
            intermediates.append(wwdr)
        }
        return SigningAssets(identity: identity, intermediates: intermediates)
    }
}
