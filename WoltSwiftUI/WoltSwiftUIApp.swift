import SwiftUI

@main
struct WoltSwiftUIApp: App {

    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
        }
    }
}
