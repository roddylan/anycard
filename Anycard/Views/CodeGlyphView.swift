import SwiftUI

/// A rendered code (or stored code photo) at a fixed design size.
struct CodeGlyphView: View {
    let card: Card
    /// Design sizes differ between the pass card and the home-row chip.
    enum Context { case pass, chip }
    var context: Context = .pass

    var body: some View {
        switch card.codeType {
        case .image, nil:
            imageCode
        case .some(let type):
            generated(type: type)
        }
    }

    @ViewBuilder
    private func generated(type: CodeType) -> some View {
        let size = glyphSize(for: type)
        if let uiImage = BarcodeRenderer.image(type: type, value: card.codeValue) {
            Image(uiImage: uiImage)
                .resizable()
                .interpolation(.none)
                .frame(width: size.width, height: size.height)
        } else {
            Color.clear.frame(width: size.width, height: size.height)
        }
    }

    private var imageCode: some View {
        let side: CGFloat = switch context {
        case .chip: 46
        case .pass: card.template == .membership ? 104 : 144
        }
        return Group {
            if let photo = ImageStore.image(named: card.codePhotoFileName) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(hex: 0xEFECE4)
                    if context == .pass {
                        VStack(spacing: 5) {
                            Image(systemName: "photo")
                                .font(.system(size: 18, weight: .bold))
                            Text("Add code photo")
                                .font(AppFont.sans(10, .semiBold))
                        }
                        .foregroundStyle(Palette.muted)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Palette.muted)
                    }
                }
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: context == .chip ? 6 : 8, style: .continuous))
    }

    private func glyphSize(for type: CodeType) -> CGSize {
        switch (context, type) {
        case (.pass, .qr), (.pass, .aztec): CGSize(width: 148, height: 148)
        case (.pass, .pdf417): CGSize(width: 248, height: 84)
        case (.pass, _): CGSize(width: 248, height: 66)
        case (.chip, .qr), (.chip, .aztec): CGSize(width: 52, height: 52)
        case (.chip, .pdf417): CGSize(width: 88, height: 40)
        case (.chip, _): CGSize(width: 88, height: 38)
        }
    }
}
