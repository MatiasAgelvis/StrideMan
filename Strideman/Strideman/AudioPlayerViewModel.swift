import Foundation
import Observation

// MARK: - Swift Enums
//   - Protocol conformance (`CaseIterable`, `Identifiable`).
//
// `CaseIterable`: Automatically synthesizes `AudioTrack.allCases` (like Python's `list(AudioTrack)`).
// `Identifiable`: Requires an `id` property, letting SwiftUI uniquely identify each item in lists.
enum AudioTrack: String, CaseIterable, Identifiable {
    case forest = "kulakovka-forest-295910"
    case running = "alexrockbeat-alexrockbeat-running-560959"

    // Conformance to Identifiable: each track's ID is its raw string value.
    var id: String { rawValue }

    // Swift `switch` statements MUST be exhaustive (must cover every case).
    // If you add a new track case above, the compiler will refuse to build until you handle it here!
    var title: String {
        switch self {
        case .forest:
            return "Forest"
        case .running:
            return "Running"
        }
    }

    var fileName: String {
        switch self {
        case .forest:
            return "kulakovka-forest-295910.mp3"
        case .running:
            return "alexrockbeat-alexrockbeat-running-560959.mp3"
        }
    }

    // SF Symbols name used for the SwiftUI button icon
    var iconName: String {
        switch self {
        case .forest:
            return "tree.fill"
        case .running:
            return "figure.run"
        }
    }
}

// MARK: - The `@Observable` Macro & SwiftUI Reactivity
// The compiler automatically tracks property access on stored properties (`currentTrack`, `isPlaying`).
// When any SwiftUI view reads these properties, SwiftUI automatically records the dependency.
// Whenever `currentTrack` or `isPlaying` changes, SwiftUI re-renders ONLY the views that read them!
@Observable
final class AudioPlayerViewModel {
    private let service = AudioPlayerService()

    var currentTrack: AudioTrack?

    var isPlaying: Bool = false

    init() {
        // MARK: - ARC & `[weak self]` (Avoiding Retain Cycles / Memory Leaks)
        // In Swift, memory is managed by ARC (Automatic Reference Counting):
        //   - If `self` owns `service`, and `service` holds this closure, and the closure strongly
        //     captures `self`, neither can EVER be freed from memory (a "retain cycle")!
        // `[weak self]` tells the closure to keep a WEAK pointer to self. If the ViewModel is destroyed,
        // `self` becomes `nil` safely, preventing memory leaks.
        service.onPlaybackFinished = { [weak self] in
            self?.isPlaying = false
            self?.currentTrack = nil
        }
    }

    /// Plays the requested track. Tapping the currently playing track toggles pause/resume.
    func togglePlay(track: AudioTrack) {
        if currentTrack == track && isPlaying {
            service.pause()
            isPlaying = false
        } else if currentTrack == track && !isPlaying {
            service.resume()
            isPlaying = true
        } else {
            let started = service.play(resourceName: track.rawValue, fileExtension: "mp3")
            if started {
                currentTrack = track
                isPlaying = true
            }
        }
    }

    /// Stops playback and resets state.
    func stop() {
        service.stop()
        isPlaying = false
        currentTrack = nil
    }

    /// Convenience helper to check if a specific track is playing.
    func isTrackPlaying(_ track: AudioTrack) -> Bool {
        currentTrack == track && isPlaying
    }
}
