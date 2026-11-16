import AVFoundation
import Foundation

// MARK: - Swift vs Python: Class vs Struct & Reference Types

// In Python, everything is an object passed by reference.
// In Swift, we have two distinct categories:
//   1. Value Types (`struct`, `enum`): copied when passed around.
//   2. Reference Types (`class`): shared via reference count, like Python classes.
//
// `final`: Prevents subclassing. In Python, classes are open by default (and can be monkey-patched).
// In Swift, `final` allows the compiler to optimize method calls via direct dispatch (faster).
//
// `NSObject, AVAudioPlayerDelegate`: Inherits from Apple's Objective-C root class and conforms
// to the AVAudioPlayer delegate protocol. In Python, you'd use duck-typing or pass a callback.
// In Swift, Apple frameworks use the "Delegate Pattern" (a formal protocol contract).
//
// `@MainActor`: Ensures all code in this class runs on the main thread (UI thread).
// Unlike Python's Global Interpreter Lock (GIL), Swift is truly multithreaded;
// `@MainActor` acts as a compiler-enforced thread-safety guarantee for UI-bound code.
@MainActor
final class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
    // `private`: Unlike Python's convention of prefixing with `_` (e.g. `_player`),
    // Swift enforces access control at compile-time. Outside code cannot access this.
    private var player: AVAudioPlayer?

    // MARK: - Closures vs Python Lambdas / Callbacks

    /// In Python, lambdas are restricted to a single expression: `lambda: ...`
    /// In Swift, closures are full-featured anonymous functions.
    /// `(@MainActor () -> Void)?` is an optional closure taking no arguments and returning nothing (`Void`).
    var onPlaybackFinished: (@MainActor () -> Void)?

    override init() {
        super.init()
        configureAudioSession()
    }

    // MARK: - Compile-Time Directives vs Python Runtime Checks

    /// In Python, checking platforms happens at runtime: `if sys.platform != "darwin":`
    /// In Swift, `#if !os(macOS)` is a COMPILE-TIME directive.
    /// The compiler completely ignores this block when building for macOS.
    /// This is crucial because `AVAudioSession` does not exist on macOS (it is iOS/watchOS/tvOS/visionOS only).
    private func configureAudioSession() {
        #if !os(macOS)
            // Swift error handling: `do-catch` is similar to Python's `try-except`.
            // Notice `try` is placed explicitly before the throwing call, not at the block level.
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)
            } catch {
                // Swift automatically provides the `error` constant inside `catch` blocks,
                // similar to `except Exception as error:` in Python.
                print("Failed to configure AVAudioSession: \(error.localizedDescription)")
            }
        #endif
    }

    // MARK: - @discardableResult & Bundle Resources

    // `@discardableResult`: In Python, if a function returns a value, you can ignore it silently.
    // In Swift, ignoring a return value triggers a compiler warning! This attribute tells Swift
    // it's acceptable for callers not to use the returned Bool.
    //
    @discardableResult
    func play(resourceName: String, fileExtension: String = "mp3") -> Bool {
        // MARK: - `guard let` (The Bouncer Pattern)

        // Swift uses `guard let`: it safely unwraps the optional URL. If it's nil,
        // the `else` branch MUST exit the scope (`return`).
        // The unwrapped `url` is now a non-optional constant available in the rest of this function!
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            print("Audio file not found: \(resourceName).\(fileExtension)")
            return false
        }

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            let started = newPlayer.play()
            // In Swift, we keep a strong reference (`self.player = newPlayer`).
            // If we didn't, ARC (Automatic Reference Counting) would deallocate the player immediately
            // when this method ends, and no sound would play!
            player = newPlayer
            return started
        } catch {
            print("Failed to create AVAudioPlayer: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Optional Chaining (`?.`)

    // `player?.pause()`: In Python, if `self.player is None`, calling `self.player.pause()`
    // raises an `AttributeError: 'NoneType' object has no attribute 'pause'`.
    // In Swift, `?.` checks if `player` is not nil before calling `pause()`. If nil, it simply does nothing safely.
    func pause() {
        player?.pause()
    }

    // MARK: - Nil-Coalescing Operator (`??`)

    /// `player?.play() ?? false`: Similar to Python's `player.play() if player else False`.
    /// If `player` is nil, or if `play()` returns nil, fall back to the default `false`.
    @discardableResult
    func resume() -> Bool {
        return player?.play() ?? false
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
    }

    // MARK: - Computed Properties vs Python `@property`

    /// In Python:
    ///   @property
    ///   def is_playing(self): return self.player.isPlaying if self.player else False
    /// In Swift, `var isPlaying: Bool { ... }` is a computed property with the exact same purpose.
    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    // MARK: - AVAudioPlayerDelegate & Concurrency

    // This delegate method is called by the OS audio engine when a song completes.
    // `nonisolated`: Tells the compiler this method can be called from outside the `@MainActor`
    // (since AVFoundation's audio thread is a background thread).
    // `Task { @MainActor in ... }`: Dispatches back to the main thread (like `asyncio.run_coroutine_threadsafe`),
    // ensuring the UI callback runs safely on the UI thread.
    nonisolated func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        Task { @MainActor in
            self.onPlaybackFinished?()
        }
    }
}
