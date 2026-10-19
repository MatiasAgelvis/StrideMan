import SwiftUI

struct ContentView: View {
    @State private var viewModel = HeartRateViewModel()

    var body: some View {
        Text("Hello, world!")
            .padding()
            Text("\(Int(viewModel.currentBPM)) BPM")
                .font(.largeTitle)
                .task { await viewModel.start() }
    }
}

#Preview {
    ContentView()
}
