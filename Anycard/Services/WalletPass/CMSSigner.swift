import CryptoKit
import Foundation
import Security

/// Produces the detached CMS/PKCS#7 signature over `manifest.json` that Wallet
/// requires as the `signature` file of a `.pkpass`.
enum CMSSigner {
    enum SignerError: LocalizedError {
        case identityUnreadable
        case unsupportedKey
        case signingFailed(message: String)

        var errorDescription: String? {
            switch self {
            case .identityUnreadable:
                return "The signing certificate could not be read."
            case .unsupportedKey:
                return "The signing key type is not supported (RSA or EC required)."
            case .signingFailed(let message):
                return "Signing failed: \(message)"
            }
        }
    }

    // OIDs used in the SignedData structure.
    private static let oidSignedData: [UInt] = [1, 2, 840, 113549, 1, 7, 2]
    private static let oidData: [UInt] = [1, 2, 840, 113549, 1, 7, 1]
    private static let oidSHA256: [UInt] = [2, 16, 840, 1, 101, 3, 4, 2, 1]
    private static let oidRSAEncryption: [UInt] = [1, 2, 840, 113549, 1, 1, 1]
    private static let oidECDSAWithSHA256: [UInt] = [1, 2, 840, 10045, 4, 3, 2]
    private static let oidAttrContentType: [UInt] = [1, 2, 840, 113549, 1, 9, 3]
    private static let oidAttrMessageDigest: [UInt] = [1, 2, 840, 113549, 1, 9, 4]
    private static let oidAttrSigningTime: [UInt] = [1, 2, 840, 113549, 1, 9, 5]

    /// Signs `manifest` (detached) with the given identity, embedding the
    /// signer certificate plus any intermediate certificates (Apple WWDR).
    static func sign(
        manifest: Data,
        identity: SecIdentity,
        intermediates: [Data],
        signingTime: Date = Date()
    ) throws -> Data {
        var certificateRef: SecCertificate?
        var keyRef: SecKey?
        SecIdentityCopyCertificate(identity, &certificateRef)
        SecIdentityCopyPrivateKey(identity, &keyRef)
        guard let certificateRef, let keyRef else { throw SignerError.identityUnreadable }

        let certificate = SecCertificateCopyData(certificateRef) as Data
        return try sign(
            manifest: manifest,
            certificate: certificate,
            privateKey: keyRef,
            intermediates: intermediates,
            signingTime: signingTime
        )
    }

    static func sign(
        manifest: Data,
        certificate: Data,
        privateKey: SecKey,
        intermediates: [Data],
        signingTime: Date
    ) throws -> Data {
        let digest = Data(SHA256.hash(data: manifest))
        let (issuer, serial) = try CertificateParser.issuerAndSerial(fromCertificate: certificate)

        // Signed attributes (contentType, signingTime, messageDigest).
        let attributes = [
            attribute(oidAttrContentType, value: DER.objectID(oidData)),
            attribute(oidAttrSigningTime, value: DER.utcTime(signingTime)),
            attribute(oidAttrMessageDigest, value: DER.octetString(digest)),
        ]
        // The signature is computed over the attributes with the SET OF tag;
        // inside SignerInfo they are re-tagged as [0] IMPLICIT.
        let signedAttrsSet = DER.setOf(attributes)
        let signedAttrsTagged = DER.contextTag(0, dropTag(signedAttrsSet))

        let (algorithm, signatureAlgorithmOID) = try signingAlgorithm(for: privateKey)
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey, algorithm, signedAttrsSet as CFData, &error
        ) as Data? else {
            let message = (error?.takeRetainedValue()).map(String.init(describing:)) ?? "unknown"
            throw SignerError.signingFailed(message: message)
        }

        let sha256Identifier = DER.sequence([DER.objectID(oidSHA256), DER.null])
        let signerInfo = DER.sequence([
            DER.integer(1),
            DER.sequence([issuer, serial]), // IssuerAndSerialNumber
            sha256Identifier,
            signedAttrsTagged,
            signatureAlgorithmOID,
            DER.octetString(signature),
        ])

        var certificatesContent = certificate
        for intermediate in intermediates {
            certificatesContent.append(intermediate)
        }

        let signedData = DER.sequence([
            DER.integer(1),
            DER.node(0x31, sha256Identifier), // digestAlgorithms SET
            DER.sequence([DER.objectID(oidData)]), // encapContentInfo, detached
            DER.contextTag(0, certificatesContent), // certificates [0] IMPLICIT
            DER.node(0x31, signerInfo), // signerInfos SET
        ])

        return DER.sequence([
            DER.objectID(oidSignedData),
            DER.contextTag(0, signedData),
        ])
    }

    // MARK: - Private

    private static func attribute(_ oid: [UInt], value: Data) -> Data {
        DER.sequence([DER.objectID(oid), DER.node(0x31, value)])
    }

    private static func signingAlgorithm(for key: SecKey) throws -> (SecKeyAlgorithm, Data) {
        if SecKeyIsAlgorithmSupported(key, .sign, .rsaSignatureMessagePKCS1v15SHA256) {
            return (
                .rsaSignatureMessagePKCS1v15SHA256,
                DER.sequence([DER.objectID(oidRSAEncryption), DER.null])
            )
        }
        if SecKeyIsAlgorithmSupported(key, .sign, .ecdsaSignatureMessageX962SHA256) {
            return (
                .ecdsaSignatureMessageX962SHA256,
                DER.sequence([DER.objectID(oidECDSAWithSHA256)])
            )
        }
        throw SignerError.unsupportedKey
    }

    /// Strips the tag + length prefix, returning just the value octets.
    private static func dropTag(_ encoded: Data) -> Data {
        var reader = DERReader(encoded)
        guard let tlv = try? reader.readTLV() else { return Data() }
        return Data(tlv.content)
    }
}
