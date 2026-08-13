import SwiftUI

struct RootView: View {

    @Environment(AppContainer.self) private var container
    @State private var router = Router()

    /// Survives the app being killed in the background, so returning to a restaurant
    /// list lands where the user left rather than at the city picker.
    @SceneStorage("navigationPath") private var storedPath: Data?

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            CitiesView(repository: container.cityRepository)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .restaurants(let city):
                        RestaurantsView(
                            repository: container.restaurantRepository,
                            city: city
                        )
                    }
                }
        }
        .environment(router)
        .task {
            router.restore(from: storedPath)
        }
        .onChange(of: router.path) {
            storedPath = router.encoded
        }
    }
}
