import SwiftUI

enum Route: Hashable {
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
}
