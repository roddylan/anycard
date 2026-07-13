import AVFoundation
import SwiftUI

/// Add — the dark scanner screen. Live camera scanning when available
/// (real device + permission), otherwise the simulated viewport. Also hosts
/// manual entry and the capture-as-image path.
struct ScannerView: View {
    @Environment(WalletViewModel.self) private var model
    @State private var cameraAuthorized = false
    @State private var scanController: CameraScanController?

    var body: some View {
        ZStack {
            Palette.scannerBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 0) {
                        viewport
                            .padding(.top, 6)

                        formatPills
                            .padding(.top, 18)

                        if model.manualEntry {
                            manualPanel
                                .padding(.top, 22)
                        }

                        captureCluster
                            .padding(.top, 36)
                            .padding(.bottom, 28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)
            }
        }
        .foregroundStyle(Palette.screen)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard CameraScanController.isCameraAvailable else { return }
            cameraAuthorized = await CameraScanController.requestAccess()
            if cameraAuthorized, scanController == nil {
                let controller = CameraScanController { type, value in
                    model.handleScan(type: type, value: value)
                }
                scanController = controller
                controller.start()
            }
        }
        .onDisappear {
            scanController?.stop()
            scanController = nil
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            BackButton(background: .white.opacity(0.1)) {
                model.path.removeAll()
            }
            Text("Add a card")
                .font(AppFont.serif(26))
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Viewport

    private var viewport: some View {
        ZStack {
            if let scanController, cameraAuthorized {
                CameraPreview(session: scanController.session)
            } else {
                RadialGradient(
                    colors: [Color(hex: 0x2C2C2C), Color(hex: 0x161616), Color(hex: 0x0A0A0A)],
                    center: UnitPoint(x: 0.5, y: 0.22),
                    startRadius: 0,
                    endRadius: 380
                )
            }

            cornerBrackets
                .padding(26)

            VStack {
                Spacer()
                Text("Point at any barcode or QR code")
                    .font(AppFont.sans(13))
                    .foregroundStyle(Palette.screen.opacity(0.62))
                    .padding(.bottom, 22)
            }
        }
        .aspectRatio(1 / 1.02, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.06), lineWidth: 1)
        }
    }

    private var cornerBrackets: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                CornerBracket()
                    .stroke(Palette.screen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 34, height: 34)
                    .rotationEffect(.degrees(Double(index) * 90))
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: [.topLeading, .topTrailing, .bottomTrailing, .bottomLeading][index]
                    )
            }
        }
    }

    private var formatPills: some View {
        HStack(spacing: 8) {
            ForEach(CodeType.scannable) { type in
                Text(type == .code128 ? "Barcode" : type.label.replacingOccurrences(of: " Code", with: ""))
                    .font(AppFont.sans(12))
                    .foregroundStyle(Palette.screen.opacity(0.8))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 13)
                    .background(.white.opacity(0.08), in: Capsule())
            }
        }
    }

    // MARK: - Manual entry

    private var manualPanel: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 14) {
            Text("CODE VALUE")
                .font(AppFont.sans(12))
                .tracking(1)
                .foregroundStyle(Palette.screen.opacity(0.55))

            TextField(
                "",
                text: Binding(
                    get: { model.draft?.codeValue ?? "" },
                    set: { model.draft?.codeValue = $0 }
                ),
                prompt: Text("e.g. 490154203237518").foregroundStyle(Palette.screen.opacity(0.3))
            )
            .font(AppFont.mono(16))
            .foregroundStyle(Palette.screen)
            .padding(.vertical, 13)
            .padding(.horizontal, 15)
            .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.characters)

            Text("CODE TYPE")
                .font(AppFont.sans(12))
                .tracking(1)
                .foregroundStyle(Palette.screen.opacity(0.55))
                .padding(.top, 2)

            HStack(spacing: 8) {
                ForEach(CodeType.scannable) { type in
                    let active = model.draft?.codeType == type
                    Button {
                        model.draft?.codeType = type
                    } label: {
                        Text(type.label)
                            .font(AppFont.sans(13, .semiBold))
                            .foregroundStyle(active ? Palette.scannerBackground : Palette.screen.opacity(0.85))
                            .padding(.vertical, 9)
                            .padding(.horizontal, 13)
                            .background(active ? Palette.accentOnDark : .white.opacity(0.06), in: Capsule())
                            .overlay {
                                Capsule().strokeBorder(
                                    active ? Palette.accentOnDark : .white.opacity(0.12),
                                    lineWidth: 1
                                )
                            }
                    }
                    .buttonStyle(PressableStyle(scale: 0.94))
                }
            }

            Button {
                model.continueManualEntry()
            } label: {
                Text("Continue")
                    .font(AppFont.sans(16, .semiBold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PressableStyle(scale: 0.98))
            .padding(.top, 6)
        }
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Capture cluster

    private var captureCluster: some View {
        VStack(spacing: 12) {
            Button {
                model.simulateScan()
            } label: {
                Circle()
                    .fill(Palette.screen)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Circle().strokeBorder(.white.opacity(0.25), lineWidth: 5).frame(width: 74, height: 74)
                    }
                    .overlay {
                        Circle().strokeBorder(.white.opacity(0.4), lineWidth: 2).frame(width: 80, height: 80)
                    }
                    .frame(width: 80, height: 80)
            }
            .buttonStyle(PressableStyle(scale: 0.92))

            Text("Tap to simulate a scan")
                .font(AppFont.sans(13))
                .foregroundStyle(Palette.screen.opacity(0.6))

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    model.manualEntry.toggle()
                }
            } label: {
                Text(model.manualEntry ? "Hide manual entry" : "Enter code manually")
                    .font(AppFont.sans(15, .semiBold))
                    .foregroundStyle(Palette.accentOnDark)
            }
            .padding(.top, 2)

            Button {
                model.captureImageCode()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 14, weight: .bold))
                    Text("Code won't scan? Capture it as an image")
                        .font(AppFont.sans(13))
                }
                .foregroundStyle(Palette.screen.opacity(0.72))
            }
            .padding(.top, 2)
        }
    }
}

/// One L-shaped viewfinder corner (drawn as the top-leading corner).
struct CornerBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = 10
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// Circular back button used on dark and light headers.
struct BackButton: View {
    var background: Color
    var foreground: Color?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(background)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(foreground ?? .primary)
                }
        }
        .buttonStyle(PressableStyle(scale: 0.9))
    }
}

/// AVCapture preview layer host.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
