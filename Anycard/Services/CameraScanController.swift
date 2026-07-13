@preconcurrency import AVFoundation
import UIKit

/// Owns the capture session for live barcode scanning. Configuration and
/// start/stop run on a private queue; detections are delivered on the main actor.
/// Falls back gracefully (see `isCameraAvailable`) on Simulator.
final class CameraScanController: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    let session = AVCaptureSession()

    private let queue = DispatchQueue(label: "com.anycard.camera-scan")
    private var configured = false
    private var didFire = false
    private let onCode: @MainActor @Sendable (CodeType, String) -> Void

    init(onCode: @escaping @MainActor @Sendable (CodeType, String) -> Void) {
        self.onCode = onCode
    }

    static var isCameraAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: true
        case .notDetermined: await AVCaptureDevice.requestAccess(for: .video)
        default: false
        }
    }

    func start() {
        queue.async {
            self.configureIfNeeded()
            self.didFire = false
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: queue)
        output.metadataObjectTypes = output.availableMetadataObjectTypes.filter {
            Self.supportedTypes.contains($0)
        }
    }

    private static let supportedTypes: Set<AVMetadataObject.ObjectType> = [
        .qr, .code128, .pdf417, .aztec, .ean13, .ean8, .upce, .code39, .code93, .interleaved2of5,
    ]

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didFire,
              let object = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
              let value = object.stringValue, !value.isEmpty
        else { return }
        didFire = true

        let type: CodeType = switch object.type {
        case .qr: .qr
        case .pdf417: .pdf417
        case .aztec: .aztec
        default: .code128
        }
        let onCode = onCode
        Task { @MainActor in
            onCode(type, value)
        }
    }
}
