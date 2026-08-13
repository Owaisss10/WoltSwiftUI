import SwiftUI

// MARK: - Modifier

extension View {

    /// Adds a search field and the floating result count that goes with it.
    ///
    /// Both screens search the same way, so they apply one modifier rather than
    /// repeating `.searchable` and its styling — which is how the two had already
    /// drifted apart on placement.
    ///
    /// Placement is left to the system: under the large title at the root of a stack,
    /// in the bar on a pushed screen.
    func searchableResults(
        query: Binding<String>,
        prompt: String,
        visible: Int,
        total: Int,
        noun: String
    ) -> some View {
        searchable(text: query, prompt: prompt)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !query.wrappedValue.isEmpty {
                    ResultCountPill(visible: visible, total: total, noun: noun)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy(duration: 0.2), value: query.wrappedValue.isEmpty)
    }
}

// MARK: - Pill

/// Floating count of how many items survived the current search.
///
/// Anchored in the bottom safe area rather than as a list header: plain-style section
/// headers pin while scrolling and read as content floating over the rows.
struct ResultCountPill: View {

    let visible: Int
    let total: Int
    /// Plural noun for the items being counted, e.g. "cities".
    let noun: String

    var body: some View {
        Text("\(visible) of \(total) \(noun)")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            // Slightly more opaque than ultra-thin, so the label stays legible over
            // whichever rows happen to be underneath it.
            .background(.thinMaterial, in: .capsule)
            .overlay(
                Capsule().strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
            .padding(.bottom, 10)
            .accessibilityLabel("Showing \(visible) of \(total) \(noun)")
    }
}

#Preview {
    @Previewable @State var query = "Hels"

    NavigationStack {
        List(0..<20, id: \.self) { Text("Row \($0)") }
            .listStyle(.plain)
            .navigationTitle("Choose a city")
            .searchableResults(
                query: $query,
                prompt: "Search city",
                visible: 3,
                total: 958,
                noun: "cities"
            )
    }
}
