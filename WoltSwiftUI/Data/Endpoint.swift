import Foundation

/// A request expressed as data, so callers never build URLs by hand.
nonisolated struct Endpoint: Sendable {
    let path: String
    var queryItems: [URLQueryItem] = []
}

nonisolated extension Endpoint {

    static let cities = Endpoint(path: "v1/cities")

    static func restaurants(latitude: Double, longitude: Double) -> Endpoint {
        Endpoint(
            path: "v1/pages/restaurants",
            queryItems: [
                URLQueryItem(name: "lat", value: String(latitude)),
                URLQueryItem(name: "lon", value: String(longitude)),
            ]
        )
    }
}
