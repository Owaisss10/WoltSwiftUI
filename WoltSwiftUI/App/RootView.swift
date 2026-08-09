import SwiftUI

struct RootView: View {

    @Environment(AppContainer.self) private var container
    @State private var router = Router()

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            CitiesView(repository: container.cityRepository)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .restaurants(let city):
                        // Replaced in the restaurants phase.
                        Text(city.name)
                            .navigationTitle(city.name)
                    }
                }
        }
        .environment(router)
    }
}
