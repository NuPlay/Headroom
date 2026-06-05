import Foundation

/// Opinionated defaults and knobs used to resolve Headroom tiers.
public struct HeadroomPolicy: Equatable, Sendable {
    public static let `default` = HeadroomPolicy()

    /// If Low Power Mode is enabled, cap the effective tier to this value. Set to `nil` to ignore Low Power Mode.
    public var lowPowerModeCap: HeadroomTier?

    /// If thermal state is `.fair`, cap the effective tier to this value. Set to `nil` to ignore fair thermal state.
    public var fairThermalCap: HeadroomTier?

    /// If thermal state is `.serious`, downgrade the effective tier by this many steps.
    public var seriousThermalDowngrade: Int

    /// If thermal state is `.critical`, force the effective tier to this value.
    public var criticalThermalTier: HeadroomTier

    /// If thermal state is unknown, cap the effective tier to this value. Set to `nil` to ignore unknown thermal state.
    public var unknownThermalCap: HeadroomTier?

    /// Thresholds used to classify current memory pressure.
    public var memoryPressurePolicy: HeadroomMemoryPressurePolicy

    /// Downgrade applied when memory pressure is `.constrained`.
    public var constrainedMemoryDowngrade: Int

    /// Downgrade applied when memory pressure is `.critical`.
    public var criticalMemoryDowngrade: Int

    /// Baseline memory thresholds used as a fallback hardware signal.
    public var memoryTierThresholds: HeadroomMemoryTierThresholds

    /// Effective tier is capped at physical-memory-derived tier upgraded by this many steps.
    public var physicalMemoryCapHeadroom: Int

    /// Explicit per-device overrides. Prefer `Headroom.configure { $0.overrideDevice(.iPhone13, as: .high) }`.
    var deviceOverrides: [String: HeadroomTier]

    /// Explicit per-Metal Apple GPU family overrides. Example: `9: .ultra`.
    var metalFamilyOverrides: [Int: HeadroomTier]

    public init(
        lowPowerModeCap: HeadroomTier? = .medium,
        fairThermalCap: HeadroomTier? = .high,
        seriousThermalDowngrade: Int = 1,
        criticalThermalTier: HeadroomTier = .low,
        unknownThermalCap: HeadroomTier? = .medium,
        memoryPressurePolicy: HeadroomMemoryPressurePolicy = .default,
        constrainedMemoryDowngrade: Int = 1,
        criticalMemoryDowngrade: Int = 2,
        memoryTierThresholds: HeadroomMemoryTierThresholds = .default,
        physicalMemoryCapHeadroom: Int = 1
    ) {
        self.lowPowerModeCap = lowPowerModeCap
        self.fairThermalCap = fairThermalCap
        self.seriousThermalDowngrade = seriousThermalDowngrade
        self.criticalThermalTier = criticalThermalTier
        self.unknownThermalCap = unknownThermalCap
        self.memoryPressurePolicy = memoryPressurePolicy
        self.constrainedMemoryDowngrade = constrainedMemoryDowngrade
        self.criticalMemoryDowngrade = criticalMemoryDowngrade
        self.memoryTierThresholds = memoryTierThresholds
        self.physicalMemoryCapHeadroom = physicalMemoryCapHeadroom
        self.deviceOverrides = [:]
        self.metalFamilyOverrides = [:]
    }
}

/// Thresholds used to classify available memory pressure.
public struct HeadroomMemoryPressurePolicy: Equatable, Sendable {
    public static let `default` = HeadroomMemoryPressurePolicy()

    public var constrainedAvailableRatio: Double
    public var criticalAvailableRatio: Double
    public var constrainedAvailableBytes: UInt64
    public var criticalAvailableBytes: UInt64

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
public struct HeadroomMemoryTierThresholds: Equatable, Sendable {
    public static let `default` = HeadroomMemoryTierThresholds()

    public var mediumBytes: UInt64
    public var highBytes: UInt64
    public var ultraBytes: UInt64

    public init(
        mediumBytes: UInt64 = 2 * 1_073_741_824,
        highBytes: UInt64 = 4 * 1_073_741_824,
        ultraBytes: UInt64 = 8 * 1_073_741_824
    ) {
        self.mediumBytes = mediumBytes
        self.highBytes = highBytes
        self.ultraBytes = ultraBytes
    }
}
