/// Five heart-rate zones.
///
/// Python equivalent:
///     class HeartRateZone(IntEnum):
///         ZONE1 = 1
///         ZONE2 = 2
///         ...
///
/// This is a *value type*: creating or copying a zone is like copying an int,
/// not allocating an object on the heap.
enum HeartRateZone: Int {
    // `: Int` declares the raw-value type, so each case carries an Int.
    // Read it back later with `zone.rawValue`.
    case zone1 = 1
    case zone2 = 2
    case zone3 = 3
    case zone4 = 4
    case zone5 = 5

    /// Human-readable zone label.
    /// `var name: String { ... }` is a computed property.
    /// Python: `@property def name(self) -> str: ...`
    var name: String {
        // `switch` must handle every case (exhaustive) or it won't compile.
        // Python: `match self: case HeartRateZone.ZONE1: return "Very light"`
        switch self {
        case .zone1: return "Very light"
        case .zone2: return "Light"
        case .zone3: return "Moderate"
        case .zone4: return "Hard"
        case .zone5: return "Maximum"
        }
    }

    /// Build a zone from a BPM reading.
    ///
    /// `init` is a constructor (Python: `__init__`), called without `new`:
    ///     let zone = HeartRateZone(bpm: 142)
    ///
    /// An enum initializer does not return a value — it decides which case
    /// `self` becomes. That is why you see `self = .zone3` instead of `return`.
    init(bpm: Double, maxHeartRate: Double = 190) {
        // `guard ... else { return }` is an early exit.
        // Python: `if not (...): self = Zone.ZONE1; return`
        // Bad data (NaN, infinity, or no max) falls back to zone 1.
        guard maxHeartRate > 0, bpm.isFinite else {
            self = .zone1
            return
        }

        // `..<0.60` is a range pattern meaning "less than 0.60".
        // Python: `if fraction < 0.60: ... elif fraction < 0.70: ...`
        switch bpm / maxHeartRate {
        case ..<0.60: self = .zone1
        case ..<0.70: self = .zone2
        case ..<0.80: self = .zone3
        case ..<0.90: self = .zone4
        default:      self = .zone5   // 90% and above
        }
    }
}
