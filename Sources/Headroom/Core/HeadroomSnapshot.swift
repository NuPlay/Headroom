import Foundation

/// A point-in-time capability decision and the signals used to make it.
public struct HeadroomSnapshot: Codable, Equatable, Sendable {
    /// Baseline hardware capability score before runtime penalties.
    public let hardwareScore: HeadroomScore

    /// Runtime-adjusted score after Low Power Mode, thermal, and memory pressure.
    public let effectiveScore: HeadroomScore

    /// Tier derived from `hardwareScore`.
    public let hardwareTier: HeadroomTier

    /// Tier derived from `effectiveScore`.
    public let effectiveTier: HeadroomTier

    /// Signals used to resolve the scores.
    public let signals: HeadroomSignals

    /// Creates a snapshot from explicit scores and signals.
    public init(
        hardwareScore: HeadroomScore,
        effectiveScore: HeadroomScore,
        signals: HeadroomSignals
    ) {
        self.hardwareScore = hardwareScore
        self.effectiveScore = effectiveScore
        hardwareTier = hardwareScore.tier
        effectiveTier = effectiveScore.tier
        self.signals = signals
    }

    /// Creates a compatibility snapshot from coarse tiers.
    public init(
        hardwareTier: HeadroomTier,
        effectiveTier: HeadroomTier,
        signals: HeadroomSignals
    ) {
        self.init(
            hardwareScore: hardwareTier.representativeScore,
            effectiveScore: effectiveTier.representativeScore,
            signals: signals
        )
    }
}

/// Runtime and hardware signals Headroom considered while choosing a score.
public struct HeadroomSignals: Codable, Equatable, Sendable {
    /// Human-readable device description.
    public let deviceDescription: String

    /// Stable key used for device-level overrides, when available.
    public let deviceOverrideKey: String?

    /// Machine identifier such as `iPhone16,1`, when available.
    public let machineIdentifier: String?

    /// Whether the current process is running in a simulator.
    public let isSimulator: Bool

    /// Physical memory, in bytes.
    public let physicalMemoryBytes: UInt64

    /// DeviceKit-derived score, when available.
    public let deviceKitScore: HeadroomScore?

    /// DeviceKit-derived tier, when available.
    public let deviceKitTier: HeadroomTier?

    /// Estimated currently available memory, in bytes.
    public let availableMemoryBytes: UInt64?

    /// Classified memory pressure.
    public let memoryPressure: HeadroomMemoryPressure

    /// Whether Low Power Mode is enabled.
    public let lowPowerModeEnabled: Bool

    /// Current thermal state.
    public let thermalState: HeadroomThermalState

    /// Highest supported Metal Apple GPU family number, when available.
    public let metalAppleGPUFamily: Int?

    /// Creates a signal bundle for scoring.
    public init(
        deviceDescription: String,
        deviceOverrideKey: String? = nil,
        machineIdentifier: String?,
        isSimulator: Bool,
        physicalMemoryBytes: UInt64,
        deviceKitScore: HeadroomScore? = nil,
        deviceKitTier: HeadroomTier? = nil,
        availableMemoryBytes: UInt64? = nil,
        memoryPressure: HeadroomMemoryPressure = .unknown,
        lowPowerModeEnabled: Bool,
        thermalState: HeadroomThermalState,
        metalAppleGPUFamily: Int?
    ) {
        self.deviceDescription = deviceDescription
        self.deviceOverrideKey = deviceOverrideKey
        self.machineIdentifier = machineIdentifier
        self.isSimulator = isSimulator
        self.physicalMemoryBytes = physicalMemoryBytes
        self.deviceKitScore = deviceKitScore
        self.deviceKitTier = deviceKitTier ?? deviceKitScore?.tier
        self.availableMemoryBytes = availableMemoryBytes
        self.memoryPressure = memoryPressure
        self.lowPowerModeEnabled = lowPowerModeEnabled
        self.thermalState = thermalState
        self.metalAppleGPUFamily = metalAppleGPUFamily
    }
}

/// Platform-neutral representation of `ProcessInfo.ThermalState`.
public enum HeadroomThermalState: String, Codable, Sendable {
    /// The system reports normal thermal conditions.
    case nominal

    /// The system is warm but generally still suitable for most work.
    case fair

    /// The system is under serious thermal pressure.
    case serious

    /// The system is under critical thermal pressure.
    case critical

    /// Thermal state could not be mapped or is unavailable.
    case unknown
}

extension HeadroomThermalState: Comparable {
    /// Compares thermal states by increasing performance constraint severity.
    public static func < (lhs: HeadroomThermalState, rhs: HeadroomThermalState) -> Bool {
        lhs.severity < rhs.severity
    }
}

extension HeadroomThermalState {
    /// Whether this state should be treated as constraining performance-sensitive work.
    public var isPerformanceConstrained: Bool {
        switch self {
        case .nominal:
            false
        case .fair, .serious, .critical, .unknown:
            true
        }
    }

    /// Numeric severity used for ordering thermal states.
    public var severity: Int {
        switch self {
        case .nominal:
            0
        case .fair:
            1
        case .serious:
            2
        case .critical:
            3
        case .unknown:
            2
        }
    }
}
