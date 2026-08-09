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
        .navigationTitle(String(localized: "Choose a city"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "Search city")
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
        // Shown only while filtering: "958 of 958" is noise otherwise. A fixed inset
        // rather than a section header, since plain-style headers pin while scrolling
        // and read as content floating over the rows.
        .safeAreaInset(edge: .top, spacing: 0) {
            if !viewModel.query.isEmpty {
                resultCount
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.2), value: viewModel.query.isEmpty)
        .overlay {
            if viewModel.visibleCities.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            }
        }
    }

    private var resultCount: some View {
        VStack(spacing: 0) {
            Text("\(viewModel.visibleCities.count) of \(viewModel.totalCityCount) cities")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
                .accessibilityLabel(
                    "Showing \(viewModel.visibleCities.count) of \(viewModel.totalCityCount) cities"
                )

            Divider()
        }
        .frame(maxWidth: .infinity)
        .background(.bar)
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
