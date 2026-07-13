import SwiftUI

/// Top-level container: the home navigation stack, the detail overlay
/// (opacity cross-fade per the design), the confirm cover, and the toast.
struct RootView: View {
    @State private var model: WalletViewModel

    init(store: CardStore) {
        let model = WalletViewModel(store: store)
        #if DEBUG
        // Launch straight into a screen (screenshot verification / debugging):
        // SIMCTL_CHILD_ANYCARD_SCREEN=add|customize|confirm|detail simctl launch …
        switch ProcessInfo.processInfo.environment["ANYCARD_SCREEN"] {
        case "add":
            model.openAdd()
        case "customize":
            model.openAdd()
            model.handleScan(type: .qr, value: "QR-482017")
        case "confirm":
            model.openAdd()
            model.handleScan(type: .qr, value: "QR-482017")
            model.addToWallet()
        case "edit":
            if let card = store.cards.first { model.beginEdit(card) }
        case "detail":
            let index = Int(ProcessInfo.processInfo.environment["ANYCARD_INDEX"] ?? "0") ?? 0
            model.detailCardID = store.cards.indices.contains(index) ? store.cards[index].id : store.cards.first?.id
        default:
            break
        }
        #endif
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model
        ZStack {
            NavigationStack(path: $model.path) {
                HomeView()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .add: ScannerView()
                        case .customize: CustomizeView()
                        }
                    }
            }

            if let card = model.detailCard {
                PassDetailView(card: card)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: model.detailCardID)
        .overlay(alignment: .top) {
            if let toast = model.toast {
                ToastView(text: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .animation(.easeOut(duration: 0.3), value: model.toast)
        .fullScreenCover(isPresented: $model.showConfirm) {
            ConfirmView()
        }
        .preferredColorScheme(model.prefersDarkScheme ? .dark : .light)
        .environment(model)
    }
}

/// "Added to your wallet" pill.
struct ToastView: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 17))
                .foregroundStyle(Palette.toastCheck)
            Text(text)
                .font(AppFont.sans(14, .medium))
                .foregroundStyle(Palette.screen)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 20)
        .background(Palette.ink, in: Capsule())
        .shadow(color: .black.opacity(0.32), radius: 15, y: 12)
        .padding(.top, 12)
    }
}
