import Foundation
import OSLog

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

    static let woltBaseURL = URL(string: "https://restaurant-api.wolt.com/")!

    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(baseURL: URL = woltBaseURL, session: URLSession = .shared) {
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
            Logger.networking.error("\(endpoint.path) failed: \(error.localizedDescription)")
            throw AppError(error)
        } catch is CancellationError {
            // Cancellation is not a failure; it is the caller going away.
            throw AppError.cancelled
        } catch {
            Logger.networking.error("\(endpoint.path) failed: \(error.localizedDescription)")
            throw AppError.unknown
        }

        guard let http = response as? HTTPURLResponse else {
            Logger.networking.error("\(endpoint.path) returned a non-HTTP response")
            throw AppError.unexpectedResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            Logger.networking.error("\(endpoint.path) returned \(http.statusCode)")
            throw AppError.server(statusCode: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            // The full error, not just its description — DecodingError says exactly
            // which key failed, which is the whole value of catching it here.
            Logger.decoding.error("\(endpoint.path) did not decode: \(error)")
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
