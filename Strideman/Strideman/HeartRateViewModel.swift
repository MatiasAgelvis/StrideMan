import Foundation
import Observation

// Macro to track changes in the view model
@Observable
final class HeartRateViewModel {
    var currentBPM: Double = 0

    private let service = HeartRateService()
    private var streamTask: Task<Void, Never>?

    func start() async {
        let authorized = await service.requestAuthorization()
        guard authorized else { return }

        // compile-time selection of stream source
        #if targetEnvironment(simulator)
        let stream = service.mockHeartRateStream()   // compiled for simulator
        #else
        let stream = service.heartRateStream()   // compiled for device
        #endif

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
