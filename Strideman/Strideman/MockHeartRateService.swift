#if DEBUG

import Foundation

/// A fake heart rate source for the simulator.
///
/// Every 10 seconds it picks a new base BPM from `baseLevels`. Each second it
/// emits that base value with a small random error, so the number moves around
/// without pretending to be a physiological curve.
final class MockHeartRateService: HeartRateProviding {
    private let baseLevels: [Double] = [100, 120, 140, 160, 180]
    private let ticksPerLevel = 10            // 10 seconds at one tick per second
    private let secondsPerTick: TimeInterval = 1
    private let error: ClosedRange<Double> = -5...5

    func requestAuthorization() async -> Bool {
        // Nothing to authorize. This is what lets the mock run in the simulator,
        // where HealthKit is unavailable.
        true
    }

    func heartRateStream() -> AsyncStream<Double> {
        // Copy the settings out of `self` so the producer task does not capture it.
        let baseLevels = self.baseLevels
        let ticksPerLevel = self.ticksPerLevel
        let secondsPerTick = self.secondsPerTick
        let error = self.error

        return AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    // One base value for the next `ticksPerLevel` samples.
                    let base = baseLevels.randomElement() ?? 70

                    for _ in 0..<ticksPerLevel {
                        continuation.yield(base + Double.random(in: error))
                        try? await Task.sleep(for: .seconds(secondsPerTick))
                    }
                }
            }

            // When the consumer stops reading, cancel the producer loop too.
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

#endif
