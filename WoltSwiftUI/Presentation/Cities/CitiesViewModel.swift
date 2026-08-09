import Foundation

@Observable
@MainActor
final class CitiesViewModel {

    private let repository: any CityRepository

    private(set) var state: ViewState<[City]> = .loading
    var query = ""

    init(repository: any CityRepository) {
        self.repository = repository
    }

    /// Cities matching the current query.
    ///
    /// Sorting happens once, when the data arrives — not here, where it would rerun on
    /// every keystroke. Filtering a loaded array is cheap enough to stay derived, which
    /// keeps `state` the single source of truth.
    var visibleCities: [City] {
        guard let cities = state.value else { return [] }
        guard !query.isEmpty else { return cities }
        return cities.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var totalCityCount: Int {
        state.value?.count ?? 0
    }

    func load() async {
        state = .loading
        do {
            let cities = try await repository.cities()
            state = .loaded(cities.sorted { $0.name < $1.name })
        } catch {
            state = .failed(error)
        }
    }
}
