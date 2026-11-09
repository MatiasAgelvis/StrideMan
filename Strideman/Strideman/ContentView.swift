import SwiftUI

// MARK: - Views as Structs (Value Types) vs Python/Qt Widgets (Reference Types)
// In Python frameworks (e.g., PyQt/Tkinter), UI elements are heavyweight objects that you
// instantiate once and mutate imperatively (e.g. `label.setText("foo")`).
// In SwiftUI, Views are lightweight immutable `struct`s (value types).
// SwiftUI re-creates these structs rapidly whenever state changes, compares the diff,
// and efficiently updates the underlying render tree.
struct ContentView: View {
    // MARK: - @State vs Python Instance Variables
    // In Python classes, you write `self.view_model = ...`.
    // In SwiftUI structs, the struct itself is immutable (`self` cannot be mutated inside `var body`).
    // `@State` tells SwiftUI to allocate and manage this variable in external persistent memory
    // outside the struct lifecycle, so it survives view re-creations!
    @State private var heartRateViewModel = HeartRateViewModel(
        service: AppDependencies.heartRateService
    )
    @State private var audioViewModel = AudioPlayerViewModel()

    // `var body: some View`: An opaque return type.
    // Swift figures out the concrete return type at compile-time, so we don't have to write
    // complex nested types like `VStack<TupleView<(Text, Button, ...)>>`.
    var body: some View {
        VStack(spacing: 24) {
            // MARK: - Heart Rate Section
            VStack(spacing: 8) {
                Label("Heart Rate", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(.red)

                Text("\(Int(heartRateViewModel.currentBPM)) BPM")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .task {
                await heartRateViewModel.start()
            }
            .onDisappear {
                heartRateViewModel.stop()
            }

            Divider()

            // MARK: - Audio Player Section
            VStack(spacing: 16) {
                Text("Music Player")
                    .font(.title2.bold())

                // Optional Binding (`if let`): Safely unwraps `audioViewModel.currentTrack`.
                // In Python: `if audioViewModel.currentTrack is not None:`
                if let currentTrack = audioViewModel.currentTrack {
                    Text(audioViewModel.isPlaying ? "Playing: \(currentTrack.title)" : "Paused: \(currentTrack.title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Select a song to play")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Two buttons for the songs requested
                VStack(spacing: 12) {
                    // Button 1: Forest track (kulakovka-forest-295910.mp3)
                    trackButton(for: .forest)

                    // Button 2: Running track (alexrockbeat-alexrockbeat-running-560959.mp3)
                    trackButton(for: .running)
                }

                // Optional Stop Button when a track is active
                if audioViewModel.currentTrack != nil {
                    Button(role: .destructive) {
                        audioViewModel.stop()
                    } label: {
                        Label("Stop Music", systemImage: "stop.fill")
                            .font(.subheadline)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
        .padding()
    }

    // MARK: - @ViewBuilder & Trailing Closures
    // `@ViewBuilder`: A Swift "result builder" attribute that allows child views to be listed sequentially.
    // Trailing closure syntax:
    // `Button { /* action */ } label: { /* view */ }`
    // In Swift, if the last parameters of a function/initializer are closures, they can be written
    // outside the parentheses, providing a clean, declarative DSL.
    @ViewBuilder
    private func trackButton(for track: AudioTrack) -> some View {
        let isCurrent = audioViewModel.currentTrack == track
        let isPlaying = audioViewModel.isTrackPlaying(track)

        Button {
            audioViewModel.togglePlay(track: track)
        } label: {
            HStack {
                Label(track.title, systemImage: track.iconName)
                    .font(.headline)

                Spacer()

                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundStyle(isCurrent ? .white : .primary)
            .background(isCurrent ? Color.accentColor : Color.secondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ContentView()
}
