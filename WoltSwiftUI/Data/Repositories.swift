import Foundation

// MARK: - Interfaces

nonisolated protocol CityRepository: Sendable {
    func cities() async throws(AppError) -> [City]
}

nonisolated protocol RestaurantRepository: Sendable {
    func restaurants(latitude: Double, longitude: Double) async throws(AppError) -> [Restaurant]
}

// MARK: - Live implementations

nonisolated struct LiveCityRepository: CityRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func cities() async throws(AppError) -> [City] {
        let response: CitiesResponse = try await client.get(.cities)
        return response.results
    }
}

nonisolated struct LiveRestaurantRepository: RestaurantRepository {

    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func restaurants(latitude: Double, longitude: Double) async throws(AppError) -> [Restaurant] {
        let response: RestaurantsResponse = try await client.get(
            .restaurants(latitude: latitude, longitude: longitude)
        )

        // A missing venue section means the page was not shaped as expected, which is
        // reported rather than being silently rendered as "no restaurants here".
        guard let restaurants = response.venueListRestaurants else {
            throw AppError.unexpectedResponse
        }
        return restaurants
    }
}
