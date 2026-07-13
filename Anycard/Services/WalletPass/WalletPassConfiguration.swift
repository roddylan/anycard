import Foundation

/// Identifiers and signing settings for exported Apple Wallet passes.
///
/// To make exported passes installable on a real device:
/// 1. Create a Pass Type ID + certificate in the Apple Developer portal.
/// 2. Export the certificate + private key as `PassSigning.p12` and add it to
///    the app bundle, along with Apple's WWDR intermediate as `PassSigningWWDR.cer`.
/// 3. Set `passTypeIdentifier`/`teamIdentifier` below to match the certificate.
/// See docs/apple-wallet.md. Without a certificate, export still works in the
/// Simulator (which doesn't enforce pass signatures).
struct WalletPassConfiguration: Sendable {
    var passTypeIdentifier: String
    var teamIdentifier: String
    var p12Password: String

    // teamIdentifier matches the bundled Simulator dev certificate (OU=ANYCARDDEV);
    // replace it with your real team ID when configuring PassSigning.p12.
    static let `default` = WalletPassConfiguration(
        passTypeIdentifier: "pass.com.rodericklan.Anycard",
        teamIdentifier: "ANYCARDDEV",
        p12Password: ""
    )
}
