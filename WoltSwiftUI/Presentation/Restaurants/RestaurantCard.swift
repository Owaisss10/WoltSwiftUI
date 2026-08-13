import SwiftUI

struct RestaurantCard: View {

    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(spacing: 16) {
                deliveryEstimate
                priceRange
            }

            if !restaurant.tags.isEmpty {
                Text(restaurant.tags.prefix(3).joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundStyle(.tint)
            }

            if let address = restaurant.address {
                Text(address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: .rect(cornerRadius: 20))
        // One element per restaurant, rather than making VoiceOver step through
        // every label individually.
        .accessibilityElement(children: .combine)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            thumbnail

            VStack(alignment: .leading, spacing: 8) {
                Text(restaurant.name)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)

                if !restaurant.description.isEmpty {
                    Text(restaurant.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        }
    }

    private var thumbnail: some View {
        AsyncImage(url: restaurant.imageURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.secondary)
                }
        }
        .frame(width: 90, height: 90)
        .clipShape(.rect(cornerRadius: 16))
        // The name already conveys the restaurant; the image adds nothing for VoiceOver.
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var deliveryEstimate: some View {
        if !restaurant.deliveryEstimate.isEmpty {
            Label(restaurant.deliveryEstimate, systemImage: "bicycle")
                .font(.subheadline)
                .accessibilityLabel(
                    "Delivery \(restaurant.deliveryEstimate) minutes"
                )
        }
    }

    @ViewBuilder
    private var priceRange: some View {
        if let priceRange = restaurant.priceRange {
            Text(String(repeating: "€", count: priceRange))
                .font(.subheadline)
                // Repeated currency symbols are meaningless read aloud.
                .accessibilityLabel("Price level \(priceRange) out of 4")
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(Restaurant.samples) { RestaurantCard(restaurant: $0) }
        }
        .padding()
    }
}
