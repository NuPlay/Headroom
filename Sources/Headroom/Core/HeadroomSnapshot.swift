import Foundation

/// A point-in-time capability decision and the signals used to make it.
public struct HeadroomSnapshot: Equatable, Sendable {
    public let hardwareScore: HeadroomScore
    public let effectiveScore: HeadroomScore
    public let hardwareTier: HeadroomTier
    public let effectiveTier: HeadroomTier
    public let signals: HeadroomSignals

    public init(
        hardwareScore: HeadroomScore,
        effectiveScore: HeadroomScore,
        signals: HeadroomSignals
    ) {
        self.hardwareScore = hardwareScore
        self.effectiveScore = effectiveScore
        self.hardwareTier = hardwareScore.tier
        self.effectiveTier = effectiveScore.tier
        self.signals = signals
    }

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
public struct HeadroomSignals: Equatable, Sendable {
    public let deviceDescription: String
    public let deviceOverrideKey: String?
    public let machineIdentifier: String?
    public let isSimulator: Bool
    public let physicalMemoryBytes: UInt64
    public let deviceKitScore: HeadroomScore?
    public let deviceKitTier: HeadroomTier?
    public let availableMemoryBytes: UInt64?
    public let memoryPressure: HeadroomMemoryPressure
    public let lowPowerModeEnabled: Bool
    public let thermalState: HeadroomThermalState
    public let metalAppleGPUFamily: Int?

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
    case nominal
    case fair
    case serious
    case critical
    case unknown
}

extension HeadroomThermalState: Comparable {
    public static func < (lhs: HeadroomThermalState, rhs: HeadroomThermalState) -> Bool {
        lhs.severity < rhs.severity
    }
}

public extension HeadroomThermalState {
    var isPerformanceConstrained: Bool {
        switch self {
        case .nominal:
            return false
        case .fair, .serious, .critical, .unknown:
            return true
        }
    }

    var severity: Int {
        switch self {
        case .nominal:
            return 0
        case .fair:
            return 1
        case .serious:
            return 2
        case .critical:
            return 3
        case .unknown:
            return 2
        }
    }
}
