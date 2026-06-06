import Foundation

/// Opinionated defaults and knobs used to resolve Headroom scores.
public struct HeadroomPolicy: Codable, Equatable, Sendable {
    /// Default scoring policy.
    public static let `default` = HeadroomPolicy()

    /// Score penalty applied when Low Power Mode is enabled.
    ///
    /// Low Power Mode can reduce CPU benchmark scores significantly, but it also
    /// caps ProMotion displays at 60 Hz. Headroom therefore uses a modest default
    /// penalty and lets CPU/GPU-heavy features opt out with `allowsLowPowerMode`.
    public var lowPowerModePenalty: Int

    /// Score penalty applied when thermal state is `.fair`.
    public var fairThermalPenalty: Int

    /// Score penalty applied when thermal state is `.serious`.
    public var seriousThermalPenalty: Int

    /// Score forced when thermal state is `.critical`.
    public var criticalThermalScore: HeadroomScore

    /// Score penalty applied when thermal state is unknown.
    public var unknownThermalPenalty: Int

    /// Thresholds used to classify current memory pressure.
    public var memoryPressurePolicy: HeadroomMemoryPressurePolicy

    /// Score penalty applied when memory pressure is `.constrained`.
    public var constrainedMemoryPenalty: Int

    /// Score penalty applied when memory pressure is `.critical`.
    public var criticalMemoryPenalty: Int

    /// Baseline memory thresholds used as a fallback hardware signal.
    public var memoryScoreThresholds: HeadroomMemoryScoreThresholds

    /// Effective score is capped at physical-memory-derived score plus this headroom.
    public var physicalMemoryScoreHeadroom: Int

    /// Explicit per-device overrides. Prefer `Headroom.configure { $0.overrideDevice(.iPhone13, as: 71) }`.
    var deviceOverrides: [String: HeadroomScore]

    /// Explicit per-Metal Apple GPU family overrides. Example: `9: 88`.
    var metalFamilyOverrides: [Int: HeadroomScore]

    /// Creates a scoring policy.
    public init(
        lowPowerModePenalty: Int = 8,
        fairThermalPenalty: Int = 0,
        seriousThermalPenalty: Int = 10,
        criticalThermalScore: HeadroomScore = 25,
        unknownThermalPenalty: Int = 8,
        memoryPressurePolicy: HeadroomMemoryPressurePolicy = .default,
        constrainedMemoryPenalty: Int = 8,
        criticalMemoryPenalty: Int = 18,
        memoryScoreThresholds: HeadroomMemoryScoreThresholds = .default,
        physicalMemoryScoreHeadroom: Int = 12
    ) {
        self.lowPowerModePenalty = lowPowerModePenalty
        self.fairThermalPenalty = fairThermalPenalty
        self.seriousThermalPenalty = seriousThermalPenalty
        self.criticalThermalScore = criticalThermalScore
        self.unknownThermalPenalty = unknownThermalPenalty
        self.memoryPressurePolicy = memoryPressurePolicy
        self.constrainedMemoryPenalty = constrainedMemoryPenalty
        self.criticalMemoryPenalty = criticalMemoryPenalty
        self.memoryScoreThresholds = memoryScoreThresholds
        self.physicalMemoryScoreHeadroom = physicalMemoryScoreHeadroom
        deviceOverrides = [:]
        metalFamilyOverrides = [:]
    }
}

/// Thresholds used to classify available memory pressure.
public struct HeadroomMemoryPressurePolicy: Codable, Equatable, Sendable {
    /// Default memory-pressure thresholds.
    public static let `default` = HeadroomMemoryPressurePolicy()

    /// Available-memory ratio below which pressure is constrained.
    public var constrainedAvailableRatio: Double

    /// Available-memory ratio below which pressure is critical.
    public var criticalAvailableRatio: Double

    /// Available bytes below which pressure is constrained.
    public var constrainedAvailableBytes: UInt64

    /// Available bytes below which pressure is critical.
    public var criticalAvailableBytes: UInt64

    /// Creates a memory-pressure policy.
    public init(
        constrainedAvailableRatio: Double = 0.12,
        criticalAvailableRatio: Double = 0.05,
        constrainedAvailableBytes: UInt64 = 512 * 1_048_576,
        criticalAvailableBytes: UInt64 = 128 * 1_048_576
    ) {
        self.constrainedAvailableRatio = constrainedAvailableRatio
        self.criticalAvailableRatio = criticalAvailableRatio
        self.constrainedAvailableBytes = constrainedAvailableBytes
        self.criticalAvailableBytes = criticalAvailableBytes
    }

    /// Classifies available memory using both absolute bytes and physical-memory ratio.
    public func pressure(availableBytes: UInt64?, physicalBytes: UInt64) -> HeadroomMemoryPressure {
        guard let availableBytes, physicalBytes > 0 else {
            return .unknown
        }

        let availableRatio = Double(availableBytes) / Double(physicalBytes)

        if availableBytes < criticalAvailableBytes || availableRatio < criticalAvailableRatio {
            return .critical
        }

        if availableBytes < constrainedAvailableBytes || availableRatio < constrainedAvailableRatio {
            return .constrained
        }

        return .nominal
    }
}

/// Physical-memory thresholds used as a fallback hardware signal.
public struct HeadroomMemoryScoreThresholds: Codable, Equatable, Sendable {
    /// Default physical-memory-to-score thresholds.
    public static let `default` = HeadroomMemoryScoreThresholds()

    /// Physical memory required for the medium score.
    public var mediumBytes: UInt64

    /// Physical memory required for the high score.
    public var highBytes: UInt64

    /// Physical memory required for the ultra score.
    public var ultraBytes: UInt64

    /// Score returned below `mediumBytes`.
    public var lowScore: HeadroomScore

    /// Score returned at or above `mediumBytes`.
    public var mediumScore: HeadroomScore

    /// Score returned at or above `highBytes`.
    public var highScore: HeadroomScore

    /// Score returned at or above `ultraBytes`.
    public var ultraScore: HeadroomScore

    /// Creates physical-memory score thresholds.
    public init(
        mediumBytes: UInt64 = 2 * 1_073_741_824,
        highBytes: UInt64 = 4 * 1_073_741_824,
        ultraBytes: UInt64 = 8 * 1_073_741_824,
        lowScore: HeadroomScore = 35,
        mediumScore: HeadroomScore = 55,
        highScore: HeadroomScore = 72,
        ultraScore: HeadroomScore = 88
    ) {
        self.mediumBytes = mediumBytes
        self.highBytes = highBytes
        self.ultraBytes = ultraBytes
        self.lowScore = lowScore
        self.mediumScore = mediumScore
        self.highScore = highScore
        self.ultraScore = ultraScore
    }
}

/// Deprecated compatibility alias for older Headroom versions.
public typealias HeadroomMemoryTierThresholds = HeadroomMemoryScoreThresholds
