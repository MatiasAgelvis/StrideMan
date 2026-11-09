import Foundation
import Observation

// Macro to track changes in the view model
@Observable
final class HeartRateViewModel {
    private(set) var currentBPM: Double = 0

    // The view model only knows the protocol, never the concrete type.
    private let service: any HeartRateProviding
    private var streamTask: Task<Void, Never>?

    init(service: any HeartRateProviding) {
        self.service = service
    }

    func start() async {
        // Starting twice would create two streams. Bail out early, and check
        // again after the await in case another start() interleaved there.
        guard streamTask == nil else { return }

        let authorized = await service.requestAuthorization()
        guard authorized, !Task.isCancelled else { return }
        guard streamTask == nil else { return }

        streamTask = Task {
            for await bpm in service.heartRateStream() {
                currentBPM = bpm
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
    }
}
