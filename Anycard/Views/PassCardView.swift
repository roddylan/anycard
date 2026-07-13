import SwiftUI

/// The pass card, rendered in one of five templates. Aspect ratio 320:442,
/// radius 24. Used in Customize (live preview), Confirm, and Detail.
struct PassCardView: View {
    let card: Card

    var body: some View {
        ZStack {
            background

            if card.showsWatermarkIcon {
                watermarkIcon
            }

            switch card.template {
            case .minimal: minimalLayout
            case .membership: membershipLayout
            case .feature: featureLayout
            case .poster: posterLayout
            case .photo: photoLayout
            }
        }
        .foregroundStyle(foreground)
        .aspectRatio(320 / 442, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: 0x14120C, opacity: 0.28), radius: 22, y: 18)
    }

    private var foreground: Color {
        card.template.usesFullBleedPhoto ? .white : card.theme.foreground
    }

    @ViewBuilder
    private var background: some View {
        switch card.template {
        case .feature:
            Palette.photoCanvas
        case .minimal, .membership, .poster, .photo:
            if card.fill == .solid {
                card.theme.solid
            } else {
                card.theme.gradient
            }
        }
    }

    private var watermarkIcon: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
            Image(systemName: card.icon.systemName)
                .font(.system(size: 190))
                .opacity(0.09)
                .offset(x: 30, y: 30)
        }
    }

    // MARK: - Minimal

    private var minimalLayout: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 10) {
                    iconTile(side: 38, radius: 11, iconSize: 20)
                    Text(card.displayOrg)
                        .font(AppFont.serif(20))
                }
                Spacer()
                Text(card.displayTier.uppercased())
                    .font(AppFont.sans(11))
                    .tracking(1.3)
                    .opacity(0.7)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("MEMBER")
                    .font(AppFont.sans(11))
                    .tracking(1.5)
                    .opacity(0.62)
                Text(card.displayName)
                    .font(AppFont.serif(34))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            codeBox(glyphGap: 9, valueSize: 12, padding: 14, radius: 16)
        }
        .padding(22)
    }

    // MARK: - Membership

    private var membershipLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    iconTile(side: 36, radius: 10, iconSize: 19)
                    Text(card.displayOrg)
                        .font(AppFont.sans(18, .bold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    fieldLabel("MEMBERSHIP", size: 10, opacity: 0.65)
                    Text(card.displayTier)
                        .font(AppFont.serif(18))
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                fieldLabel("MEMBER NAME", size: 10)
                Text(card.displayName)
                    .font(AppFont.sans(27, .semiBold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.top, 26)
            VStack(alignment: .leading, spacing: 2) {
                fieldLabel("MEMBER ID", size: 10)
                Text(card.displayMemberId)
                    .font(AppFont.mono(18))
            }
            .padding(.top, 18)
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    fieldLabel("SINCE", size: 9)
                    Text(card.displaySince)
                        .font(AppFont.mono(14))
                }
                VStack(alignment: .leading, spacing: 2) {
                    fieldLabel("EXPIRES", size: 9)
                    Text(card.displayExpires)
                        .font(AppFont.mono(14))
                }
                VStack(alignment: .leading, spacing: 2) {
                    fieldLabel("GUEST PASS", size: 9)
                    Text(card.displayGuestPass)
                        .font(AppFont.sans(14))
                }
            }
            .padding(.top, 16)
            Spacer(minLength: 12)
            codeBox(glyphGap: 7, valueSize: 11, padding: 12, radius: 14)
                .frame(maxWidth: .infinity)
        }
        .padding(22)
        .overlay(alignment: .topTrailing) {
            Image(systemName: card.icon.systemName)
                .font(.system(size: 80))
                .rotationEffect(.degrees(-12))
                .opacity(0.9)
                .padding(.trailing, 20)
                .padding(.top, 74)
        }
    }

    // MARK: - Feature (full-bleed photo, code centered)

    private var featureLayout: some View {
        ZStack {
            PassPhotoView(fileName: card.photoFileName, placeholder: "Add a background photo")
            scrim(height: 120, topOpacity: 0.55, alignment: .top)
            scrim(height: 190, topOpacity: 0.72, alignment: .bottom)

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Text(card.displayOrg)
                        .font(AppFont.serif(24))
                        .tracking(1)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        fieldLabel("GUEST NO.", size: 10, opacity: 0.85)
                        Text(card.displayGuestNo)
                            .font(AppFont.mono(17, semiBold: true))
                    }
                }
                Spacer()
                whiteBox(padding: 16, radius: 16) {
                    CodeGlyphView(card: card)
                }
                Spacer()
                photoFooter
            }
            .padding(22)
            .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
        }
    }

    // MARK: - Poster (photo top, panel below)

    private var posterLayout: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                PassPhotoView(fileName: card.photoFileName, placeholder: "Add a photo")
                scrim(height: 78, topOpacity: 0.5, alignment: .top)
                HStack(alignment: .top) {
                    Text(card.displayOrg)
                        .font(AppFont.serif(21))
                        .tracking(0.6)
                    Spacer()
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.22))
                        .frame(width: 34, height: 34)
                        .overlay {
                            Image(systemName: card.icon.systemName)
                                .font(.system(size: 16, weight: .bold))
                        }
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.55), radius: 3, y: 1)
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
            .frame(maxHeight: .infinity)
            .clipped()

            VStack(spacing: 12) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        fieldLabel("MEMBER", size: 10)
                        Text(card.displayName)
                            .font(AppFont.serif(23))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(card.displayPassType)
                            .font(AppFont.sans(12))
                            .opacity(0.8)
                            .padding(.top, 1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        fieldLabel("EXPIRES", size: 10)
                        Text(card.displayExpires)
                            .font(AppFont.mono(14, semiBold: true))
                    }
                }
                codeBox(glyphGap: 7, valueSize: 11, padding: 12, radius: 14)
            }
            .padding(EdgeInsets(top: 15, leading: 18, bottom: 16, trailing: 18))
        }
    }

    // MARK: - Full photo (full-bleed, code high)

    private var photoLayout: some View {
        ZStack {
            PassPhotoView(fileName: card.photoFileName, placeholder: "Add a background photo")
            scrim(height: 120, topOpacity: 0.5, alignment: .top)
            scrim(height: 184, topOpacity: 0.68, alignment: .bottom)

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Text(card.displayOrg)
                        .font(AppFont.serif(24))
                        .tracking(0.7)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        fieldLabel("GUEST NO.", size: 10, opacity: 0.85)
                        Text(card.displayGuestNo)
                            .font(AppFont.mono(17, semiBold: true))
                    }
                }
                whiteBox(padding: 16, radius: 16) {
                    CodeGlyphView(card: card)
                }
                .shadow(color: .black.opacity(0.32), radius: 12, y: 4)
                .padding(.top, 30)
                Spacer()
                photoFooter
            }
            .padding(22)
            .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
        }
    }

    /// Name / pass type / expires footer shared by the feature and photo templates.
    private var photoFooter: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                fieldLabel("MEMBER NAME", size: 10, opacity: 0.8)
                Text(card.displayName)
                    .font(AppFont.serif(22))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(card.displayPassType)
                    .font(AppFont.sans(12))
                    .opacity(0.85)
                    .padding(.top, 4)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                fieldLabel("EXPIRES", size: 10, opacity: 0.8)
                Text(card.displayExpires)
                    .font(AppFont.mono(16, semiBold: true))
            }
        }
    }

    // MARK: - Shared pieces

    private func iconTile(side: CGFloat, radius: CGFloat, iconSize: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(.white.opacity(0.16))
            .frame(width: side, height: side)
            .overlay {
                Image(systemName: card.icon.systemName)
                    .font(.system(size: iconSize, weight: .bold))
            }
    }

    private func fieldLabel(_ text: String, size: CGFloat, opacity: Double = 0.62) -> some View {
        Text(text)
            .font(AppFont.sans(size, .semiBold))
            .tracking(size * 0.13)
            .opacity(opacity)
    }

    /// White code box with glyph + value text.
    private func codeBox(glyphGap: CGFloat, valueSize: CGFloat, padding: CGFloat, radius: CGFloat) -> some View {
        whiteBox(padding: padding, radius: radius) {
            VStack(spacing: glyphGap) {
                CodeGlyphView(card: card)
                if card.codeType != .image, !card.codeValue.isEmpty {
                    Text(card.codeValue)
                        .font(AppFont.mono(valueSize))
                        .tracking(valueSize * 0.1)
                        .foregroundStyle(Palette.codeInk)
                        .lineLimit(1)
                }
            }
        }
    }

    private func whiteBox(padding: CGFloat, radius: CGFloat, @ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(padding)
            .background(.white, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    private func scrim(height: CGFloat, topOpacity: Double, alignment: Alignment) -> some View {
        ZStack(alignment: alignment) {
            Color.clear
            LinearGradient(
                colors: [.black.opacity(topOpacity), .black.opacity(0)],
                startPoint: alignment == .top ? .top : .bottom,
                endPoint: alignment == .top ? .bottom : .top
            )
            .frame(height: height)
        }
        .allowsHitTesting(false)
    }
}

/// User photo (from the image store) or a tappable-looking placeholder.
struct PassPhotoView: View {
    let fileName: String?
    let placeholder: String

    var body: some View {
        GeometryReader { geo in
            if let image = ImageStore.image(named: fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                ZStack {
                    Color(hex: 0x1E1C18)
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 26, weight: .bold))
                        Text(placeholder)
                            .font(AppFont.sans(13, .medium))
                    }
                    .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
    }
}
