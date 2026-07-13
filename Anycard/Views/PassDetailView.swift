import PassKit
import SwiftUI

/// Pass detail / Scan — the pass presented full-screen for scanning,
/// with the screen brightness raised while visible.
struct PassDetailView: View {
    @Environment(WalletViewModel.self) private var model
    let card: Card

    @State private var previousBrightness: CGFloat?

    private var background: Color {
        card.template.usesFullBleedPhoto ? Palette.photoCanvas : card.theme.solid
    }

    private var foreground: Color {
        card.template.usesFullBleedPhoto ? .white : card.theme.foreground
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    circleButton(systemName: "chevron.left") {
                        model.closeDetail()
                    }
                    Spacer()
                    Text("Scan pass")
                        .font(AppFont.serif(20))
                    Spacer()
                    Menu {
                        Button {
                            model.beginEdit(card)
                        } label: {
                            Label("Edit pass", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            model.removeDetailCard()
                        } label: {
                            Label("Remove from Wallet", systemImage: "trash")
                        }
                    } label: {
                        circleLabel(systemName: "ellipsis")
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                PassCardView(card: card)
                    .frame(maxWidth: 342)
                    .padding(.horizontal, 24)

                HStack(spacing: 8) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Brightness increased for scanning")
                        .font(AppFont.sans(13))
                }
                .opacity(0.8)
                .padding(.top, 24)

                if PKAddPassesViewController.canAddPasses() {
                    AddToWalletButton(card: card)
                        .padding(.top, 22)
                }

                Spacer()
            }
            .foregroundStyle(foreground)
        }
        .onAppear(perform: raiseBrightness)
        .onDisappear(perform: restoreBrightness)
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            circleLabel(systemName: systemName)
        }
        .buttonStyle(PressableStyle(scale: 0.9))
    }

    private func circleLabel(systemName: String) -> some View {
        Circle()
            .fill(.white.opacity(0.16))
            .frame(width: 42, height: 42)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(foreground)
            }
    }

    // MARK: - Brightness

    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen
    }

    private func raiseBrightness() {
        guard let screen else { return }
        previousBrightness = screen.brightness
        screen.brightness = 1
    }

    private func restoreBrightness() {
        guard let screen, let previousBrightness else { return }
        screen.brightness = previousBrightness
    }
}
