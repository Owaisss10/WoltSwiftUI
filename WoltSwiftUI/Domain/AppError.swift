import Foundation

/// The only error type the presentation layer ever sees.
///
/// Transport and decoding failures are translated at the repository boundary, so a
/// `URLError` or `DecodingError` never reaches a view — which keeps messages
/// user-facing and localizable.
nonisolated enum AppError: Error, Equatable, Sendable {
    case offline
    case timedOut
    case server(statusCode: Int)
    case unexpectedResponse
    case unknown
}

nonisolated extension AppError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .offline:
            String(localized: "No internet connection.")
        case .timedOut:
            String(localized: "The request took too long.")
        case .server:
            String(localized: "Wolt’s service is unavailable right now.")
        case .unexpectedResponse:
            String(localized: "We couldn’t read the response.")
        case .unknown:
            String(localized: "Something went wrong.")
        }
    }

    /// Retrying a malformed response will not help; retrying a dropped connection might.
    var isRetryable: Bool {
        switch self {
        case .offline, .timedOut, .server, .unknown: true
        case .unexpectedResponse: false
        }
    }
}
