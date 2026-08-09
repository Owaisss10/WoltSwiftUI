import Foundation

/// Screen state as a closed set of cases.
///
/// The Android counterpart models this as a struct of independent flags, where
/// `isLoading && error != nil && !items.isEmpty` is representable and meaningless.
/// Here the impossible combinations do not compile.
nonisolated enum ViewState<Value: Sendable>: Sendable {
    case loading
    case loaded(Value)
    case failed(AppError)
}

nonisolated extension ViewState {

    var value: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }

    var isLoading: Bool {
        if case .loading = self { true } else { false }
    }
}

nonisolated extension ViewState: Equatable where Value: Equatable {}
