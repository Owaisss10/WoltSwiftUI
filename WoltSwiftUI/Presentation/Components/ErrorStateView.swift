import SwiftUI

/// Shared failure state, with a retry affordance that the Android app is still missing.
struct ErrorStateView: View {

    let error: AppError
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "Something went wrong"), systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            if error.isRetryable {
                Button(String(localized: "Try again")) {
                    Task { await retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview("Offline") {
    ErrorStateView(error: .offline, retry: {})
}

#Preview("Not retryable") {
    ErrorStateView(error: .unexpectedResponse, retry: {})
}
