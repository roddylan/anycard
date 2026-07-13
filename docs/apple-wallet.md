# Apple Wallet export

Cards can be added to Apple Wallet as **generic passes**. The pass detail
screen shows the standard "Add to Apple Wallet" button, which packages the
card as a `.pkpass` (pass.json + icons + manifest + CMS signature) and presents
PassKit's add sheet.

## How signing works

Apple Wallet only accepts passes signed with a **Pass Type ID certificate**
(requires a paid Apple Developer Program membership). The app signs passes
on-device with a certificate bundled in the app:

| File (app bundle) | Purpose |
| --- | --- |
| `PassSigning.p12` | Your Pass Type ID certificate + private key |
| `PassSigningWWDR.cer` | Apple WWDR intermediate certificate (DER) |
| `PassSigningDev.p12` | Self-signed dev certificate, **Simulator only** |

Lookup order: `PassSigning.p12` if present; otherwise, in the Simulator only,
`PassSigningDev.p12` (checked in). On a real device with no `PassSigning.p12`,
the button shows a "signing not configured" message.

### Simulator demo without an Apple certificate

The Simulator's passd still validates the pass: the certificate's subject must
carry the pass type ID (`UID`) and team ID (`OU`), and the certificate chain
must be trusted. The checked-in dev certificate has a matching subject
(`UID=pass.com.rodericklan.Anycard`, `OU=ANYCARDDEV`), but you must trust it
in each simulator once:

```sh
xcrun simctl keychain booted add-root-cert docs/PassSigningDevRoot.cer
```

## Setting up real signing

1. In the Apple Developer portal, register a Pass Type ID (e.g.
   `pass.com.rodericklan.Anycard`) and create its certificate.
2. Import the certificate into Keychain Access and export the certificate +
   private key as `PassSigning.p12`.
3. Download Apple's WWDR intermediate (G4) certificate and save it as
   `PassSigningWWDR.cer`.
4. Drop both files into `Anycard/Resources/`.
5. Update `WalletPassConfiguration.default` in
   `Anycard/Services/WalletPass/WalletPassConfiguration.swift`:
   `passTypeIdentifier` and `teamIdentifier` must match the certificate, and
   `p12Password` must match the export password.

## Implementation notes

- `WalletPassBuilder` maps the card's template/theme/fields onto the generic
  pass layout; `PassImageRenderer` draws icon/logo/thumbnail PNGs.
- `CMSSigner` produces the detached PKCS#7 signature over `manifest.json`
  using the Security framework (verified against `openssl smime -verify`).
- `ZipArchive` is a minimal stored-entry zip writer (a `.pkpass` is a zip).
- Image-captured codes (`CodeType.image`) export without a Wallet barcode,
  since there is no encodable payload.
