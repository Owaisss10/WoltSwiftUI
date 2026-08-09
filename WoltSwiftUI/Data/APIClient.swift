import Foundation

/// Performs requests and translates every failure into an ``AppError``.
///
/// Nothing above this type ever sees a `URLError`, a `DecodingError`, or an HTTP
/// status code.
nonisolated protocol APIClient: Sendable {
    func get<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws(AppError) -> T
}

nonisolated extension APIClient {
    func get<T: Decodable>(_ endpoint: Endpoint) async throws(AppError) -> T {
        try await get(endpoint, as: T.self)
    }
}

nonisolated struct LiveAPIClient: APIClient {

    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL = URL(string: "https://restaurant-api.wolt.com/")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws(AppError) -> T {
        let request = try makeRequest(for: endpoint)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw AppError(error)
        } catch {
            throw AppError.unknown
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.unexpectedResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AppError.server(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AppError.unexpectedResponse
        }
    }

    private func makeRequest(for endpoint: Endpoint) throws(AppError) -> URLRequest {
        guard
            var components = URLComponents(
                url: baseURL.appending(path: endpoint.path),
                resolvingAgainstBaseURL: false
            )
        else {
            throw AppError.unexpectedResponse
        }

        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw AppError.unexpectedResponse
        }

        var request = URLRequest(url: url)
        // The API rejects URLSession's default agent.
        request.setValue("WoltSwiftUI/1.0", forHTTPHeaderField: "User-Agent")
        return request
    }
}

nonisolated private extension AppError {

    init(_ error: URLError) {
        self = switch error.code {
        case .notConnectedToInternet, .dataNotAllowed, .networkConnectionLost: .offline
        case .timedOut: .timedOut
        default: .unknown
        }
    }
}
