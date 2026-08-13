import SwiftUI

struct RestaurantsView: View {

    @State private var viewModel: RestaurantsViewModel

    init(repository: any RestaurantRepository, city: City) {
        _viewModel = State(
            initialValue: RestaurantsViewModel(repository: repository, city: city)
        )
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed(let error):
                ErrorStateView(error: error) { await viewModel.load() }

            case .loaded(let restaurants):
                if restaurants.isEmpty {
                    ContentUnavailableView(
                        String(localized: "No restaurants"),
                        systemImage: "fork.knife",
                        description: Text("Nothing is delivering in \(viewModel.cityName) right now.")
                    )
                } else {
                    restaurantList
                }
            }
        }
        .navigationTitle(viewModel.cityName)
        .searchableResults(
            query: $viewModel.query,
            prompt: String(localized: "Search restaurants"),
            visible: viewModel.visibleRestaurants.count,
            total: viewModel.totalRestaurantCount,
            noun: String(localized: "restaurants")
        )
        .task {
            guard viewModel.state.value == nil else { return }
            await viewModel.load()
        }
    }

    private var restaurantList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.visibleRestaurants) { restaurant in
                    RestaurantCard(restaurant: restaurant)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .overlay {
            if viewModel.visibleRestaurants.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            }
        }
    }
}

// MARK: - Previews

#Preview("Loaded") {
    NavigationStack {
        RestaurantsView(
            repository: PreviewRestaurantRepository(stubbed: Restaurant.samples),
            city: .helsinki
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        RestaurantsView(
            repository: PreviewRestaurantRepository(),
            city: .helsinki
        )
    }
}

#Preview("Failed") {
    NavigationStack {
        RestaurantsView(
            repository: PreviewRestaurantRepository(error: .offline),
            city: .helsinki
        )
    }
}
