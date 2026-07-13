import PassKit
import SwiftUI

/// The standard "Add to Apple Wallet" badge. Builds the `.pkpass` for the card
/// and presents PassKit's add sheet.
struct AddToWalletButton: View {
    @Environment(WalletViewModel.self) private var model
    let card: Card

    @State private var pendingPass: PendingPass?

    var body: some View {
        AddPassButton(action: exportPass)
            .fixedSize()
            .sheet(item: $pendingPass) { pending in
                AddPassesSheet(pass: pending.pass) {
                    pendingPass = nil
                }
                .ignoresSafeArea()
            }
    }

    private func exportPass() {
        do {
            pendingPass = PendingPass(pass: try WalletPassExporter.pass(for: card))
        } catch {
            model.showToast(error.localizedDescription)
        }
    }
}

private struct PendingPass: Identifiable {
    let id = UUID()
    let pass: PKPass
}

/// PKAddPassButton wrapper (PassKit has no SwiftUI equivalent).
private struct AddPassButton: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> PKAddPassButton {
        let button = PKAddPassButton(addPassButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKAddPassButton, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    final class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tapped() {
            action()
        }
    }
}

/// PKAddPassesViewController wrapper; `onFinish` dismisses the sheet.
private struct AddPassesSheet: UIViewControllerRepresentable {
    let pass: PKPass
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> PKAddPassesViewController {
        let controller = PKAddPassesViewController(pass: pass) ?? PKAddPassesViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PKAddPassesViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, PKAddPassesViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
            onFinish()
        }
    }
}
