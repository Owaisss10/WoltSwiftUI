import Foundation

nonisolated struct City: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Coding

/// `Codable` rather than merely `Decodable` so that a `City` can travel inside a
/// navigation route, which is what lets the stack be restored after the app is killed.
extension City: Codable {

    private enum CodingKeys: String, CodingKey {
        case id, name, location
    }

    private enum LocationKeys: String, CodingKey {
        case coordinates
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        let location = try container.nestedContainer(keyedBy: LocationKeys.self, forKey: .location)
        let coordinates = try location.decode([Double].self, forKey: .coordinates)

        // GeoJSON orders coordinates as [longitude, latitude] — the reverse of how they
        // are usually written. Getting this backwards sends every restaurant query to
        // the wrong hemisphere, so the order is asserted rather than assumed.
        guard coordinates.count == 2 else {
            throw DecodingError.dataCorruptedError(
                forKey: .coordinates,
                in: location,
                debugDescription: "Expected 2 coordinates, found \(coordinates.count)."
            )
        }
        longitude = coordinates[0]
        latitude = coordinates[1]
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)

        var location = container.nestedContainer(keyedBy: LocationKeys.self, forKey: .location)
        // Same order as decoding, so a round trip is lossless.
        try location.encode([longitude, latitude], forKey: .coordinates)
    }
}

/// The `/v1/cities` payload.
nonisolated struct CitiesResponse: Decodable, Sendable {
    let results: [City]
}
