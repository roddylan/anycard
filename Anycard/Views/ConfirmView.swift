import SwiftUI

/// Add-to-Wallet confirmation: dark scrim, pass preview popping in, Cancel/Add.
struct ConfirmView: View {
    @Environment(WalletViewModel.self) private var model
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Add to Wallet")
                    .font(AppFont.serif(28))
                    .foregroundStyle(Palette.screen)
                Text("This pass will be available in your wallet for offline scanning.")
                    .font(AppFont.sans(14))
                    .foregroundStyle(Palette.screen.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            Spacer()

            if let draft = model.draft {
                PassCardView(card: draft)
                    .frame(maxWidth: 320)
                    .scaleEffect(appeared ? 1 : 0.92)
                    .opacity(appeared ? 1 : 0)
                    .padding(.horizontal, 34)
            }

            Spacer()

            // Cancel : Add at the design's 1 : 2 width ratio.
            GeometryReader { geo in
                let spacing: CGFloat = 12
                let unit = (geo.size.width - spacing) / 3
                HStack(spacing: spacing) {
                    Button {
                        model.cancelConfirm()
                    } label: {
                        Text("Cancel")
                            .font(AppFont.sans(17, .semiBold))
                            .foregroundStyle(Palette.screen)
                            .frame(width: unit, height: 56)
                            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(PressableStyle(scale: 0.98))

                    Button {
                        model.confirmAdd()
                    } label: {
                        Text("Add")
                            .font(AppFont.sans(17, .semiBold))
                            .foregroundStyle(.white)
                            .frame(width: unit * 2, height: 56)
                            .background(Palette.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(PressableStyle(scale: 0.98))
                }
            }
            .frame(height: 56)
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationBackground(Color(hex: 0x0C0B09, opacity: 0.96))
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5)) {
                appeared = true
            }
        }
    }
}
