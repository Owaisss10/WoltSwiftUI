import Foundation

@Observable
@MainActor
final class RestaurantsViewModel {

    private let repository: any RestaurantRepository
    private let city: City

    private(set) var state: ViewState<[Restaurant]> = .loading {
        didSet { refreshVisibleRestaurants() }
    }

    var query = "" {
        didSet { refreshVisibleRestaurants() }
    }

    /// Restaurants matching the current query, by name or by tag.
    ///
    /// Cached for the same reason as `CitiesViewModel.visibleCities`, and shaped the
    /// same way deliberately, so both screens read alike.
    private(set) var visibleRestaurants: [Restaurant] = []

    var cityName: String { city.name }

    var totalRestaurantCount: Int {
        state.value?.count ?? 0
    }

    init(repository: any RestaurantRepository, city: City) {
        self.repository = repository
        self.city = city
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(
                try await repository.restaurants(
                    latitude: city.latitude,
                    longitude: city.longitude
                )
            )
        } catch .cancelled {
            // See `CitiesViewModel.load()`.
        } catch {
            state = .failed(error)
        }
    }

    private func refreshVisibleRestaurants() {
        guard let restaurants = state.value else {
            visibleRestaurants = []
            return
        }
        guard !query.isEmpty else {
            visibleRestaurants = restaurants
            return
        }
        visibleRestaurants = restaurants.filter { restaurant in
            restaurant.name.localizedCaseInsensitiveContains(query)
                || restaurant.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}
