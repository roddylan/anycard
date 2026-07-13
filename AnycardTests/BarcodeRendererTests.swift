import Testing
import UIKit
@testable import Anycard

@MainActor
struct BarcodeRendererTests {
    @Test(arguments: [CodeType.qr, .code128, .pdf417, .aztec])
    func rendersGeneratableTypes(type: CodeType) {
        let image = BarcodeRenderer.image(type: type, value: "GYM-880213")
        #expect(image != nil)
        #expect((image?.size.width ?? 0) > 0)
    }

    @Test func imageTypeReturnsNil() {
        #expect(BarcodeRenderer.image(type: .image, value: "anything") == nil)
    }

    @Test func emptyValueReturnsNil() {
        #expect(BarcodeRenderer.image(type: .qr, value: "") == nil)
    }

    @Test func squareTypesProduceSquareOutput() {
        for type in [CodeType.qr, .aztec] {
            let image = BarcodeRenderer.image(type: type, value: "490154203237518")
            #expect(image != nil)
            if let image {
                #expect(abs(image.size.width - image.size.height) < 1)
            }
        }
    }
}
