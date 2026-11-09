import Foundation

/// Anything that can provide heart rate samples.
///
/// The view model depends on this capability instead of a concrete class, so the
/// real HealthKit service can be swapped for the mock (or a test double) without
/// changing the view model.
protocol HeartRateProviding {
    /// Asks the underlying source for permission to read heart rate.
    /// Returns `true` when the request completed without an error.
    /// Note: that does NOT mean the user granted access.
    func requestAuthorization() async -> Bool

    /// A stream of heart rate values in beats per minute.
    func heartRateStream() -> AsyncStream<Double>
}
