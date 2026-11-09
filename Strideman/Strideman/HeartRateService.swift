import Foundation
import HealthKit

final class HeartRateService {
    private let healthStore = HKHealthStore()
    // .heartRate is a defined constant in HKQuantityTypeIdentifier
    // quantityType(forIdentifier:) returns HKQuantityType? (optional).
    // The ! unwraps it to a non-optional HKQuantityType.
    // Safe because .heartRate always exists as a defined constant.
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!

    func requestAuthorization() async -> Bool {
        // guard prevents execution if HealthKit is not available
        // similar to nesting the rest of the code in an if statement.
        // Static method of HKHealthStore to check if health data is available
        // on the device
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        // Sets of authorization types to request
        let read: Set<HKObjectType> = [heartRateType]
        // empty set, we only read HR, never save health data
        let write: Set<HKSampleType> = []

        do{
            // if authorization succeeds, return true
            // instance method of HKHealthStore to request authorization
            // NOTE: A successful return here does NOT mean the user granted access.
            // HealthKit intentionally hides read permission status for privacy.
            // We'll only know for sure when queries return data (or don't).
            try await healthStore.requestAuthorization(toShare: write, read: read)

            return true
        }
        catch{
            return false
        }
    }

    func heartRateStream() -> AsyncStream<Double>{
        let hkCourt: HKUnit = HKUnit.count().unitDivided(by: .minute())

        func handleSamples(_ samples: [HKSample]?, _ continuation: AsyncStream<Double>.Continuation) {
            guard let samples = samples as? [HKQuantitySample] else { return }
            guard let latest = samples.last else { return }

            let heartRate = latest.quantity.doubleValue(for: hkCourt)
            continuation.yield(heartRate)
        }

        return AsyncStream { continuation in
            let query = HKAnchoredObjectQuery(
                type: heartRateType,
                predicate: nil,
                anchor: nil,
                limit: HKObjectQueryNoLimit,
                resultsHandler: { query, samples, deleted, anchor, error in
                    handleSamples(samples, continuation)
                }
            )


            // update handler keeps the stream alive
            query.updateHandler = { query, samples, deleted, anchor, error in
                handleSamples(samples, continuation)
            }

            continuation.onTermination = { @Sendable _ in
                self.healthStore.stop(query)
            }


            healthStore.execute(query)
        }
    }

    func mockHeartRateStream() -> AsyncStream<Double> {
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
