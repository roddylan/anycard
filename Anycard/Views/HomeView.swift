import SwiftUI

/// Home — the wallet list. Header, scrollable card rows, and the "Add a card" FAB.
struct HomeView: View {
    @Environment(WalletViewModel.self) private var model
    @State private var cardToDelete: Card?
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Palette.screen.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Cards")
                        .font(AppFont.serif(42))
                        .foregroundStyle(Palette.ink)
                    Text("\(model.store.cards.count) passes in your wallet")
                        .font(AppFont.sans(14))
                        .foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)

                List {
                    ForEach(model.store.cards) { card in
                        Button {
                            model.openDetail(card)
                        } label: {
                            CardRowView(card: card)
                        }
                        .buttonStyle(PressableStyle())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                cardToDelete = card
                                showDeleteConfirm = true
                            } label: {
                                Label("Remove", systemImage: "trash.fill")
                            }
                            .tint(Palette.accent)
                        }
                    }
                }
                .listStyle(.plain)
                .listRowSpacing(14)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .contentMargins(.top, 12, for: .scrollContent)
                .contentMargins(.bottom, 132, for: .scrollContent)
                .confirmationDialog(
                    "Remove from wallet?",
                    isPresented: $showDeleteConfirm,
                    titleVisibility: .visible,
                    presenting: cardToDelete
                ) { card in
                    Button("Remove \"\(card.displayName)\"", role: .destructive) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            model.delete(card)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: { _ in
                    Text("This pass and its code will be deleted from this device.")
                }
            }
        }
        .overlay(alignment: .bottom) {
            Button {
                model.openAdd()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("Add a card")
                        .font(AppFont.sans(16, .semiBold))
                }
                .foregroundStyle(.white)
                .frame(height: 56)
                .padding(.horizontal, 26)
                .background(Palette.accent, in: Capsule())
                .shadow(color: Color(hex: 0xC6512F, opacity: 0.42), radius: 13, y: 10)
            }
            .buttonStyle(PressableStyle(scale: 0.95))
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// One wallet row: theme background, faint oversized icon, header row, white code strip.
struct CardRowView: View {
    let card: Card

    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(.white.opacity(0.16))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: card.icon.systemName)
                            .font(.system(size: 20, weight: .bold))
                    }
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.displayName)
                        .font(AppFont.serif(22))
                        .lineLimit(1)
                    Text(card.codeLabel.uppercased())
                        .font(AppFont.sans(11))
                        .tracking(1)
                        .opacity(0.72)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .opacity(0.55)
            }

            HStack(spacing: 14) {
                CodeGlyphView(card: card, context: .chip)
                Text(card.codeType == .image ? "Stored as image" : card.codeValue)
                    .font(AppFont.mono(13))
                    .tracking(1.3)
                    .foregroundStyle(Palette.codeInk)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 15)
            .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .padding(18)
        .foregroundStyle(card.theme.foreground)
        .background {
            ZStack(alignment: .topTrailing) {
                if card.fill == .solid {
                    card.theme.solid
                } else {
                    card.theme.gradient
                }
                Image(systemName: card.icon.systemName)
                    .font(.system(size: 100))
                    .foregroundStyle(card.theme.foreground)
                    .opacity(0.08)
                    .offset(x: 14, y: -22)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: 0x1E1A12, opacity: 0.13), radius: 11, y: 8)
    }
}
