#if DEBUG

import Foundation

/// A fake heart rate source for the simulator.
///
/// Every 10 seconds it picks a base BPM from `levels` and emits it, with a small
/// random error, once per second.
struct MockHeartRateService: HeartRateProviding {
    private let levels: [Double] = [100, 120, 140, 160, 180]
    private let samplesPerLevel = 10
    private let error: ClosedRange<Double> = -5...5

    func requestAuthorization() async -> Bool {
        // Nothing to authorize: this is what lets it run in the simulator.
        true
    }

    func heartRateStream() -> AsyncStream<Double> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    let level = levels.randomElement() ?? 0

                    for _ in 0..<samplesPerLevel {
                        continuation.yield(level + Double.random(in: error))
                        try? await Task.sleep(for: .seconds(1))
                    }
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

#endif
