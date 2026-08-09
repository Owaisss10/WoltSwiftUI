import Foundation

/// Composition root: the one place concrete implementations are chosen.
///
/// Swift needs no DI framework for this — constructor injection plus a container
/// handed down through the environment covers what Hilt does on the Android side,
/// with the wiring visible in one readable file.
@Observable
@MainActor
final class AppContainer {

    let cityRepository: any CityRepository
    let restaurantRepository: any RestaurantRepository

    init(
        cityRepository: (any CityRepository)? = nil,
        restaurantRepository: (any RestaurantRepository)? = nil
    ) {
        let client = LiveAPIClient()
        self.cityRepository = cityRepository ?? LiveCityRepository(client: client)
        self.restaurantRepository = restaurantRepository ?? LiveRestaurantRepository(client: client)
    }
}
