import SwiftUI

struct CitiesView: View {

    @Environment(Router.self) private var router
    @State private var viewModel: CitiesViewModel

    init(repository: any CityRepository) {
        _viewModel = State(initialValue: CitiesViewModel(repository: repository))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.load() }

            case .loaded:
                cityList
            }
        }
        // Root of the stack, so the standard large title that collapses on scroll.
        .navigationTitle(String(localized: "Choose a city"))
        .searchableResults(
            query: $viewModel.query,
            prompt: String(localized: "Search city"),
            visible: viewModel.visibleCities.count,
            total: viewModel.totalCityCount,
            noun: String(localized: "cities")
        )
        .task {
            // `.task` is tied to the view's lifetime, so the request is cancelled
            // automatically if the screen goes away mid-flight.
            guard viewModel.state.value == nil else { return }
            await viewModel.load()
        }
    }

    private var cityList: some View {
        List {
            ForEach(viewModel.visibleCities) { city in
                Button {
                    router.navigate(to: .restaurants(city))
                } label: {
                    Text(city.name)
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.visibleCities.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            }
        }
    }

}

// MARK: - Previews

#Preview("Loaded") {
    NavigationStack {
        CitiesView(repository: PreviewCityRepository(stubbed: City.samples))
    }
    .environment(Router())
}

#Preview("Failed") {
    NavigationStack {
        CitiesView(repository: PreviewCityRepository(error: .offline))
    }
    .environment(Router())
}
