import Foundation

/// Sample data and stub repositories backing `#Preview`.
///
/// Kept in the app target so previews stay self-contained; the test target uses its
/// own fakes rather than sharing these.
#if DEBUG

nonisolated extension City {

    static let helsinki = City(
        id: "1", name: "Helsinki", slug: "helsinki",
        latitude: 60.1699, longitude: 24.9384
    )

    static let samples: [City] = [
        .helsinki,
        City(id: "2", name: "Helsingborg", slug: "helsingborg",
             latitude: 56.0465, longitude: 12.6945),
        City(id: "3", name: "Aachen", slug: "aachen",
             latitude: 50.7753, longitude: 6.0839),
        City(id: "4", name: "Berlin", slug: "berlin",
             latitude: 52.52, longitude: 13.405),
    ]
}

nonisolated extension Restaurant {

    static let samples: [Restaurant] = [
        Restaurant(
            id: "1", name: "Hesburger Kamppi",
            description: "Herkulliset hampurilaiset & tortillat",
            imageURL: nil, deliveryEstimate: "20-30", priceRange: 1,
            tags: ["burger", "dessert", "hamburger"],
            address: "Urho Kekkosen katu 1"
        ),
        Restaurant(
            id: "2", name: "Noodle Story Kamppi",
            description: "Fresh homemade noodles",
            imageURL: nil, deliveryEstimate: "20-30", priceRange: 2,
            tags: ["asian", "bowl", "chinese"],
            address: "Urho Kekkosen katu 1"
        ),
    ]
}

nonisolated struct PreviewCityRepository: CityRepository {
    var stubbed: [City] = []
    var error: AppError?

    func cities() async throws(AppError) -> [City] {
        if let error { throw error }
        return stubbed
    }
}

nonisolated struct PreviewRestaurantRepository: RestaurantRepository {
    var stubbed: [Restaurant] = []
    var error: AppError?

    func restaurants(latitude: Double, longitude: Double) async throws(AppError) -> [Restaurant] {
        if let error { throw error }
        return stubbed
    }
}

#endif
