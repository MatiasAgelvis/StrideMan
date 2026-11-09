#if DEBUG

import Foundation

/// Development fixture: produces a smooth, physiologically plausible heart rate
/// without touching HealthKit.
///
/// Used on the simulator, where real HealthKit data is unavailable. Because it
/// conforms to `HeartRateProviding`, the view model cannot tell it apart from
/// the real service.
final class MockHeartRateService: HeartRateProviding {
    func requestAuthorization() async -> Bool {
        // There is nothing to authorize, so pretend it always succeeds.
        // This is what lets the mock run even where HealthKit is unavailable.
        true
    }

    func heartRateStream() -> AsyncStream<Double> {
        AsyncStream { continuation in
            let task = Task {
                // --- Mean-reverting random walk --------------------------------
                // Real heart rate never jumps 100 bpm between two readings.
                // Each value is built from the previous one instead of being
                // drawn independently:
                //
                //   next = current + pull * (baseline - current) + noise
                //
                // - "pull" closes a fraction of the gap to the baseline every
                //   tick, so the signal drifts back home instead of wandering.
                // - "noise" is a small random nudge, so it doesn't look like a
                //   perfect mathematical curve.
                // - the clamp keeps it inside a plausible human range.
                var bpm = 72.0            // where the signal starts
                let baseline = 72.0       // resting HR it tends back toward
                let pull = 0.05           // 5% of the gap closed per tick (~20s to settle)
                let noise = 1.5           // max bpm added or removed per tick
                let range = 50.0...190.0

                while !Task.isCancelled {
                    bpm += pull * (baseline - bpm) + Double.random(in: -noise...noise)
                    bpm = min(max(bpm, range.lowerBound), range.upperBound)

                    continuation.yield(bpm)
                    try? await Task.sleep(for: .seconds(1))
                }
            }

            // When the consumer stops reading, cancel the producer loop too.
            // Otherwise it keeps yielding into a dead continuation forever.
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

#endif
