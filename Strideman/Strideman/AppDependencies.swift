import Foundation

/// Single place where the app decides which concrete implementations to use.
/// Build-time environment checks live here, not in views or view models.
enum AppDependencies {
    static var heartRateService: any HeartRateProviding {
        #if DEBUG && targetEnvironment(simulator)
        MockHeartRateService()
        #else
        HealthKitHeartRateService()
        #endif
    }
}
