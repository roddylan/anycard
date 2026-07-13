import PhotosUI
import SwiftUI

/// Customize — design the pass and fill member details before saving.
/// Every control live-updates the pass preview.
struct CustomizeView: View {
    @Environment(WalletViewModel.self) private var model
    @State private var photoItem: PhotosPickerItem?
    @State private var codePhotoItem: PhotosPickerItem?

    /// Non-optional binding into the model's draft.
    private var draft: Binding<Card> {
        Binding(
            get: { model.draft ?? Card.newDraft() },
            set: { model.draft = $0 }
        )
    }

    private var card: Card { draft.wrappedValue }

    /// Screenshot-verification hook (see RootView's ANYCARD_SCREEN).
    private var scrollToBottomForDebug: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["ANYCARD_SCROLL"] == "bottom"
        #else
        false
        #endif
    }

    var body: some View {
        ZStack {
            Palette.screen.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        templateSection
                        preview
                        nameSection
                        if card.template.showsColorControls {
                            backgroundSection
                        }
                        if card.template.usesPhoto {
                            photoHint
                        }
                        iconSection
                        detailsSection
                        codeTypeSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .defaultScrollAnchor(scrollToBottomForDebug ? .bottom : .top)
            }
        }
        .overlay(alignment: .bottom) { addToWalletBar }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: photoItem) { _, item in
            loadPhoto(item) { draft.wrappedValue.photoFileName = $0 }
        }
        .onChange(of: codePhotoItem) { _, item in
            loadPhoto(item) { draft.wrappedValue.codePhotoFileName = $0 }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            BackButton(background: Color(hex: 0x221E17, opacity: 0.06)) {
                if model.isEditing {
                    model.cancelEdit()
                } else if model.path.last == .customize {
                    model.path.removeLast()
                }
            }
            Text(model.isEditing ? "Edit pass" : "Customize")
                .font(AppFont.serif(26))
                .foregroundStyle(Palette.ink)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Template

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionLabel(text: "Template")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                ForEach(PassTemplate.allCases) { template in
                    let active = card.template == template
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            draft.wrappedValue.template = template
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: template.systemImage)
                                .font(.system(size: 20, weight: .bold))
                            Text(template.label)
                                .font(AppFont.sans(13, .semiBold))
                            Text(template.hint)
                                .font(AppFont.sans(10))
                                .opacity(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 10)
                        .foregroundStyle(active ? Palette.screen : Palette.ink)
                        .background(
                            active ? Palette.ink : .white,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(active ? Palette.ink : Palette.inputBorder, lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(PressableStyle(scale: 0.97))
                }
            }
        }
    }

    // MARK: - Live preview

    private var preview: some View {
        let card = self.card
        return PhotosPicker(selection: $photoItem, matching: .images) {
            PassCardView(card: card)
        }
        .buttonStyle(PressableStyle(scale: 0.99))
        .disabled(!card.template.usesPhoto)
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionLabel(text: "Member name")
            TextField("", text: draft.name, prompt: promptText("e.g. Ryan Notch"))
                .font(AppFont.sans(16))
                .foregroundStyle(Palette.ink)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Palette.inputBorder, lineWidth: 1)
                }
        }
    }

    // MARK: - Background

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Background")

            HStack(spacing: 4) {
                ForEach(BackgroundFill.allCases, id: \.self) { fill in
                    let active = card.fill == fill
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            draft.wrappedValue.fill = fill
                        }
                    } label: {
                        Text(fill.label)
                            .font(AppFont.sans(14, .semiBold))
                            .foregroundStyle(active ? Palette.ink : Palette.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background {
                                if active {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.12), radius: 1.5, y: 1)
                                }
                            }
                    }
                }
            }
            .padding(4)
            .background(Palette.segmentTrack, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 13) {
                ForEach(PassTheme.allCases) { theme in
                    let active = card.theme == theme
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            draft.wrappedValue.theme = theme
                        }
                    } label: {
                        Circle()
                            .fill(theme.solid)
                            .frame(width: 44, height: 44)
                            .overlay {
                                Circle()
                                    .inset(by: active ? -4.5 : -1.5)
                                    .strokeBorder(
                                        active ? Palette.accent : Palette.inputBorder,
                                        lineWidth: active ? 3 : 1.5
                                    )
                            }
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .opacity(active ? 0.95 : 0)
                            }
                    }
                    .buttonStyle(PressableStyle(scale: 0.9))
                }
            }
            .padding(.horizontal, 3)

            Toggle(isOn: draft.showsIconBackground) {
                Text("Show icon in background")
                    .font(AppFont.sans(15))
                    .foregroundStyle(Palette.ink)
            }
            .tint(Palette.accent)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Palette.inputBorder, lineWidth: 1)
            }
        }
    }

    // MARK: - Hints

    private var photoHint: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            HintPanel(
                systemImage: "photo",
                text: "Tap here or the preview above to choose a photo. The pass text auto-adjusts for contrast."
            )
        }
    }

    private var imageCodeHint: some View {
        PhotosPicker(selection: $codePhotoItem, matching: .images) {
            HintPanel(
                systemImage: "barcode.viewfinder",
                text: "This code is stored as a picture. Tap here to add a clear, flattened photo of it — it'll be shown full-screen to scan."
            )
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Icon")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 46), spacing: 11)], spacing: 11) {
                ForEach(PassIcon.allCases) { icon in
                    let active = card.icon == icon
                    Button {
                        draft.wrappedValue.icon = icon
                    } label: {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(active ? Palette.ink : .white)
                            .frame(width: 46, height: 46)
                            .overlay {
                                Image(systemName: icon.systemName)
                                    .font(.system(size: 19, weight: .bold))
                                    .foregroundStyle(active ? Palette.screen : Palette.ink)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(active ? Palette.ink : Palette.inputBorder, lineWidth: 1)
                            }
                    }
                    .buttonStyle(PressableStyle(scale: 0.9))
                }
            }
        }
    }

    // MARK: - Details (adaptive per template)

    /// Detail fields per template; `fullWidth` fields span both columns.
    private var detailFields: [DetailField] {
        switch card.template {
        case .minimal: [
            DetailField(key: \.org, label: "Organization", placeholder: "Rewards", fullWidth: true),
            DetailField(key: \.tier, label: "Subtitle", placeholder: "Gold member", fullWidth: true),
        ]
        case .membership: [
            DetailField(key: \.org, label: "Organization", placeholder: "Iron & Oak"),
            DetailField(key: \.tier, label: "Tier", placeholder: "Premier"),
            DetailField(key: \.memberId, label: "Member ID", placeholder: "123 456 789", fullWidth: true),
            DetailField(key: \.since, label: "Member since", placeholder: "06/2024"),
            DetailField(key: \.expires, label: "Expires", placeholder: "06/2026"),
            DetailField(key: \.guestPass, label: "Guest pass", placeholder: "Available", fullWidth: true),
        ]
        case .feature: [
            DetailField(key: \.org, label: "Organization", placeholder: "City Museum"),
            DetailField(key: \.guestNo, label: "Guest no.", placeholder: "102035"),
            DetailField(key: \.passType, label: "Pass type", placeholder: "Family Pass"),
            DetailField(key: \.expires, label: "Expires", placeholder: "01/2027"),
        ]
        case .poster: [
            DetailField(key: \.org, label: "Organization", placeholder: "City Museum"),
            DetailField(key: \.passType, label: "Pass type", placeholder: "Season Pass"),
            DetailField(key: \.expires, label: "Expires", placeholder: "01/2027", fullWidth: true),
        ]
        case .photo: [
            DetailField(key: \.org, label: "Organization", placeholder: "City Museum"),
            DetailField(key: \.guestNo, label: "Guest no.", placeholder: "102035"),
            DetailField(key: \.passType, label: "Pass type", placeholder: "Season Pass"),
            DetailField(key: \.expires, label: "Expires", placeholder: "01/2027"),
        ]
        }
    }

    /// Groups fields into rows: full-width fields alone, others paired.
    private var detailRows: [[DetailField]] {
        var rows: [[DetailField]] = []
        var pending: DetailField?
        for field in detailFields {
            if field.fullWidth {
                if let p = pending { rows.append([p]); pending = nil }
                rows.append([field])
            } else if let p = pending {
                rows.append([p, field])
                pending = nil
            } else {
                pending = field
            }
        }
        if let p = pending { rows.append([p]) }
        return rows
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Details")
            VStack(spacing: 12) {
                ForEach(detailRows, id: \.self) { row in
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(row) { field in
                            detailInput(field)
                        }
                    }
                }
            }
        }
    }

    private func detailInput(_ field: DetailField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(field.label.uppercased())
                .font(AppFont.sans(11, .semiBold))
                .tracking(0.8)
                .foregroundStyle(Palette.faintLabel)
            TextField("", text: draft[dynamicMember: field.key], prompt: promptText(field.placeholder))
                .font(AppFont.sans(15))
                .foregroundStyle(Palette.ink)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Palette.inputBorder, lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Code type

    @ViewBuilder
    private var codeTypeSection: some View {
        HStack {
            Text("Code type")
                .font(AppFont.sans(15))
                .foregroundStyle(Palette.ink)
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                Text(card.codeType?.label ?? "Not set")
                    .font(AppFont.sans(15))
            }
            .foregroundStyle(Palette.muted)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Palette.inputBorder, lineWidth: 1)
        }

        if card.codeType == .image {
            imageCodeHint
                .padding(.top, -10)
        }
    }

    // MARK: - Bottom bar

    private var addToWalletBar: some View {
        Button {
            if model.isEditing {
                model.saveEdits()
            } else {
                model.addToWallet()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: model.isEditing ? "checkmark" : "wallet.pass.fill")
                    .font(.system(size: 17, weight: .bold))
                Text(model.isEditing ? "Save changes" : "Add to Wallet")
                    .font(AppFont.sans(17, .semiBold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Palette.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(hex: 0xC6512F, opacity: 0.36), radius: 13, y: 10)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background {
            LinearGradient(
                colors: [Palette.screen.opacity(0), Palette.screen],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.34)
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Helpers

    private func promptText(_ text: String) -> Text {
        Text(text).font(AppFont.sans(15)).foregroundStyle(Palette.muted.opacity(0.7))
    }

    private func loadPhoto(_ item: PhotosPickerItem?, assign: @escaping (String?) -> Void) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let name = ImageStore.save(data) {
                assign(name)
            }
        }
    }
}

/// One adaptive detail input's definition.
struct DetailField: Identifiable, Hashable {
    let key: WritableKeyPath<Card, String>
    let label: String
    let placeholder: String
    var fullWidth = false

    var id: String { label }
}

/// Dashed info/hint panel.
struct HintPanel: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Palette.hintIcon)
                .padding(.top, 1)
            Text(text)
                .font(AppFont.sans(13))
                .foregroundStyle(Palette.hintText)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Palette.hintBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Palette.hintBorder, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        }
    }
}
