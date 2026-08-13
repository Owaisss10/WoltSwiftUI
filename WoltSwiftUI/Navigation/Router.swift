import SwiftUI

/// `Codable` so the whole stack can be written out and restored — which is why
/// ``City`` carries an `Encodable` conformance it never needs for networking.
enum Route: Hashable, Codable {
    case restaurants(City)
}

/// Owns the navigation stack so that views signal intent rather than performing
/// navigation themselves.
///
/// `NavigationPath` is already the state SwiftUI navigates from, so this stays a thin
/// wrapper — deliberately not a coordinator hierarchy, which would add indirection
/// without removing a problem.
@Observable
@MainActor
final class Router {

    var path = NavigationPath()

    func navigate(to route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    // MARK: - Persistence

    /// The stack as data, or `nil` if it holds anything that cannot be encoded.
    var encoded: Data? {
        guard let representation = path.codable else { return nil }
        return try? JSONEncoder().encode(representation)
    }

    func restore(from data: Data?) {
        guard
            let data,
            let representation = try? JSONDecoder()
                .decode(NavigationPath.CodableRepresentation.self, from: data)
        else { return }

        path = NavigationPath(representation)
    }
}
