import OSLog

/// Categories used across the app, so failures leave a trace without resorting to
/// `print` or logging response bodies the way the Android client does.
nonisolated extension Logger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "WoltSwiftUI"

    static let networking = Logger(subsystem: subsystem, category: "networking")
    static let decoding = Logger(subsystem: subsystem, category: "decoding")
}
