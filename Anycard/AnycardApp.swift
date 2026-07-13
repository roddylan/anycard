import SwiftUI

@main
struct AnycardApp: App {
    @State private var store = CardStore()

    init() {
        FontRegistrar.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}
