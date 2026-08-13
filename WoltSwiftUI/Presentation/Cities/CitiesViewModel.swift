import Foundation

@Observable
@MainActor
final class CitiesViewModel {

    private let repository: any CityRepository

    private(set) var state: ViewState<[City]> = .loading {
        didSet { refreshVisibleCities() }
    }

    var query = "" {
        didSet { refreshVisibleCities() }
    }

    /// Cities matching the current query.
    ///
    /// Recomputed when the query or the loaded data changes, rather than on every
    /// read: SwiftUI reads this several times per render — for the list, the result
    /// count, and the empty check — and a computed property would filter each time.
    private(set) var visibleCities: [City] = []

    var totalCityCount: Int {
        state.value?.count ?? 0
    }

    init(repository: any CityRepository) {
        self.repository = repository
    }

    func load() async {
        state = .loading
        do {
            // Sorted once here, so filtering never has to re-sort.
            state = .loaded(try await repository.cities().sorted { $0.name < $1.name })
        } catch .cancelled {
            // The screen went away mid-request; leaving the state untouched avoids
            // showing an error for something the user did not do.
        } catch {
            state = .failed(error)
        }
    }

    private func refreshVisibleCities() {
        guard let cities = state.value else {
            visibleCities = []
            return
        }
        guard !query.isEmpty else {
            visibleCities = cities
            return
        }
        visibleCities = cities.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
