import CoreText
import Foundation

/// Registers the bundled design fonts (Newsreader, Hanken Grotesk,
/// JetBrains Mono) at launch, avoiding the need for UIAppFonts in Info.plist.
enum FontRegistrar {
    static func registerAll() {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [])
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
