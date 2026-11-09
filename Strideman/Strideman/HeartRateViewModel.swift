import Foundation
import Observation

// Macro to track changes in the view model
@Observable
final class HeartRateViewModel {
    var currentBPM: Double = 0

    // Compile-time selection of the heart rate source.
    // The view model only knows the protocol, never the concrete type.
    // Only Debug builds running on the simulator use the mock.
    // Release builds never compile the fixture into the app.
    #if DEBUG && targetEnvironment(simulator)
    private let service: any HeartRateProviding = MockHeartRateService()
    #else
    private let service: any HeartRateProviding = HealthKitHeartRateService()
    #endif

    private var streamTask: Task<Void, Never>?

    func start() async {
        let authorized = await service.requestAuthorization()
        guard authorized else { return }

        let stream = service.heartRateStream()

        streamTask = Task {
            for await bpm in stream {
                currentBPM = bpm
            }
        }
    }

    func stop() {
        streamTask?.cancel()
    }
}
