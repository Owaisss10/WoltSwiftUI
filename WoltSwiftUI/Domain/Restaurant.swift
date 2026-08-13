import Foundation
import OSLog

nonisolated struct Restaurant: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let imageURL: URL?
    let deliveryEstimate: String
    let priceRange: Int?
    let tags: [String]
    let address: String?
}

// MARK: - Decoding

nonisolated extension Restaurant: Decodable {

    /// A restaurant is assembled from one list *item*, whose fields sit at two levels:
    /// the artwork on the item itself, everything else on the nested venue. Flattening
    /// here keeps the optionality at the boundary instead of in every view.
    private enum CodingKeys: String, CodingKey {
        case image, venue
    }

    private enum ImageKeys: String, CodingKey {
        case url
    }

    private enum VenueKeys: String, CodingKey {
        case id, name, address, tags
        case description = "short_description"
        case deliveryEstimate = "estimate_range"
        case priceRange = "price_range"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let venue = try container.nestedContainer(keyedBy: VenueKeys.self, forKey: .venue)

        // Required: an item without these is not renderable and is dropped by `Lossy`.
        id = try venue.decode(String.self, forKey: .id)
        name = try venue.decode(String.self, forKey: .name)

        // Optional presentation detail — absence is normal, not a failure.
        description = try venue.decodeIfPresent(String.self, forKey: .description) ?? ""
        deliveryEstimate = try venue.decodeIfPresent(String.self, forKey: .deliveryEstimate) ?? ""
        priceRange = try venue.decodeIfPresent(Int.self, forKey: .priceRange)
        tags = try venue.decodeIfPresent([String].self, forKey: .tags) ?? []

        let address = try venue.decodeIfPresent(String.self, forKey: .address)
        self.address = address?.isEmpty == false ? address : nil

        let image = try? container.nestedContainer(keyedBy: ImageKeys.self, forKey: .image)
        imageURL = try image?.decodeIfPresent(URL.self, forKey: .url) ?? nil
    }
}

// MARK: - Response envelope

/// The `/v1/pages/restaurants` payload.
///
/// The page is a list of heterogeneous sections — banners, carousels, and the vertical
/// venue list. Only the last of those is of interest, and it is identified by its
/// template rather than its position, which is not guaranteed.
nonisolated struct RestaurantsResponse: Decodable, Sendable {

    static let venueListTemplate = "venue-vertical-list"

    let sections: [Section]

    struct Section: Decodable, Sendable {

        let template: String
        /// Populated only for the venue list. Banners and carousels appear in the same
        /// array but are not venues, so decoding their items as restaurants would fail
        /// on every element — burying genuine decoding failures in the noise.
        let restaurants: [Restaurant]?

        private enum CodingKeys: String, CodingKey {
            case template, items
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            template = try container.decode(String.self, forKey: .template)

            guard template == RestaurantsResponse.venueListTemplate else {
                restaurants = nil
                return
            }

            // Items that fail to decode are dropped rather than failing the whole page:
            // one malformed venue should not empty the screen.
            restaurants = try container
                .decode([Lossy<Restaurant>].self, forKey: .items)
                .compactMap(\.value)
        }
    }

    /// `nil` when the venue section is absent entirely, which is a different condition
    /// from a city that genuinely has no restaurants and is reported as such.
    var venueListRestaurants: [Restaurant]? {
        sections.first { $0.template == Self.venueListTemplate }?.restaurants
    }
}

/// Decodes `T`, substituting `nil` for anything that fails, so one bad element in an
/// array does not discard the rest.
nonisolated struct Lossy<T: Decodable & Sendable>: Decodable, Sendable {
    let value: T?

    init(from decoder: any Decoder) throws {
        do {
            value = try T(from: decoder)
        } catch {
            // Dropping items silently would let a renamed field empty the screen with
            // no signal at all, so the reason is at least recorded.
            Logger.decoding.warning(
                "Dropped a \(String(describing: T.self)): \(error.localizedDescription)"
            )
            value = nil
        }
    }
}
