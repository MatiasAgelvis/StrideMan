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
    @State private var autoPlayByZone: Bool = true
    @State private var selectedZoneForAdd: HeartRateZone?

    // `var body: some View`: An opaque return type.
    // Swift figures out the concrete return type at compile-time, so we don't have to write
    // complex nested types like `VStack<TupleView<(Text, Button, ...)>>`.
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Heart Rate Section
                VStack(spacing: 8) {
                    HStack {
                        Label("Heart Rate", systemImage: "heart.fill")
                            .font(.headline)
                            .foregroundStyle(.red)

                        Spacer()

                        if heartRateViewModel.isMonitoring {
                            Text("LIVE")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.85))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        } else {
                            Text("STOPPED")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.3))
                                .foregroundStyle(.secondary)
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(Int(heartRateViewModel.currentBPM)) BPM")
                        .font(.system(size: 44, weight: .bold, design: .rounded))

                    Text("Zone \(heartRateViewModel.currentZone.rawValue) · \(heartRateViewModel.currentZone.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Control Buttons: Stop/Resume reading HR + Stop Music
                    HStack(spacing: 12) {
                        if heartRateViewModel.isMonitoring {
                            Button(role: .destructive) {
                                heartRateViewModel.stop()
                                audioViewModel.stop()
                            } label: {
                                Label("Stop HR & Music", systemImage: "stop.circle.fill")
                                    .font(.subheadline.bold())
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        } else {
                            Button {
                                Task {
                                    await heartRateViewModel.start()
                                }
                            } label: {
                                Label("Start HR Reading", systemImage: "play.circle.fill")
                                    .font(.subheadline.bold())
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.top, 4)
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
                .onChange(of: heartRateViewModel.currentZone) { oldZone, newZone in
                    if autoPlayByZone {
                        audioViewModel.playSong(for: newZone)
                    }
                }

                // MARK: - Audio Player Section
                VStack(spacing: 14) {
                    HStack {
                        Text("Music Player")
                            .font(.title2.bold())
                        Spacer()
                        Toggle("Auto-sync", isOn: $autoPlayByZone)
                            .labelsHidden()
                    }

                    if let currentTrack = audioViewModel.currentTrack {
                        Text(audioViewModel.isPlaying ? "Playing: \(currentTrack.title)" : "Paused: \(currentTrack.title)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Select a song or zone to play")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Direct Track Buttons
                    HStack(spacing: 12) {
                        trackButton(for: .forest)
                        trackButton(for: .running)
                    }

                    // Stop Button
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

                // MARK: - Heart Rate Zone Playlists Section
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Zone Song Playlists", systemImage: "music.note.list")
                            .font(.headline)
                        Spacer()
                    }

                    ForEach(HeartRateZone.allCases) { zone in
                        zonePlaylistCard(for: zone)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .confirmationDialog(
            "Add Song to Zone \(selectedZoneForAdd?.rawValue ?? 1) (\(selectedZoneForAdd?.name ?? ""))",
            isPresented: Binding(
                get: { selectedZoneForAdd != nil },
                set: { if !$0 { selectedZoneForAdd = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let zone = selectedZoneForAdd {
                ForEach(AudioTrack.allCases) { track in
                    Button(track.title) {
                        audioViewModel.addTrack(track, to: zone)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    // MARK: - Zone Playlist Row Card
    @ViewBuilder
    private func zonePlaylistCard(for zone: HeartRateZone) -> some View {
        let isCurrentZone = heartRateViewModel.currentZone == zone
        let tracks = audioViewModel.zonePlaylists[zone] ?? []

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Zone \(zone.rawValue): \(zone.name)")
                            .font(.subheadline.bold())
                        if isCurrentZone {
                            Text("ACTIVE")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.85))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(tracks.count) song\(tracks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Button to play this zone right now
                Button {
                    audioViewModel.playSong(for: zone)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)

                // Button to add a song to this zone
                Button {
                    selectedZoneForAdd = zone
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
            }

            if tracks.isEmpty {
                Text("No songs assigned")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                        zoneTrackRow(track: track, index: index, zone: zone)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentZone ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentZone ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }

    @ViewBuilder
    private func zoneTrackRow(track: AudioTrack, index: Int, zone: HeartRateZone) -> some View {
        let isTrackActive = audioViewModel.currentTrack == track && audioViewModel.isPlaying

        HStack {
            Image(systemName: track.iconName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(track.title)
                .font(.caption)

            Spacer()

            if isTrackActive {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }

            Button(role: .destructive) {
                audioViewModel.removeTrack(at: index, from: zone)
            } label: {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
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
