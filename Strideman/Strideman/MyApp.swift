import SwiftUI

@main struct MyApp: App {
    // Owned by the app, so a scene rebuild does not restart the stream.
    @State private var heartRateViewModel = HeartRateViewModel(
        service: AppDependencies.heartRateService
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: heartRateViewModel)
        }
    }
}
