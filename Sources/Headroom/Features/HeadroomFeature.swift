import Foundation
import DeviceKit

/// A feature-level gate for expensive code paths.
public struct HeadroomFeature: Equatable, Sendable {
    public let requiredTier: HeadroomTier
    public let tierSource: HeadroomFeatureTierSource
    public let minimumAvailableMemoryBytes: UInt64?
    public let minimumAvailableStorageBytes: Int64?
    public let storageUsage: HeadroomStorageUsage
    public let allowsLowPowerMode: Bool
    public let maximumThermalState: HeadroomThermalState?

    public init(
        requiredTier: HeadroomTier,
        tierSource: HeadroomFeatureTierSource = .effective,
        minimumAvailableMemoryBytes: UInt64? = nil,
        minimumAvailableStorageBytes: Int64? = nil,
        storageUsage: HeadroomStorageUsage = .important,
        allowsLowPowerMode: Bool = true,
        maximumThermalState: HeadroomThermalState? = nil
    ) {
        self.requiredTier = requiredTier
        self.tierSource = tierSource
        self.minimumAvailableMemoryBytes = minimumAvailableMemoryBytes
        self.minimumAvailableStorageBytes = minimumAvailableStorageBytes
        self.storageUsage = storageUsage
        self.allowsLowPowerMode = allowsLowPowerMode
        self.maximumThermalState = maximumThermalState
    }

    public init(
        _ device: Device,
        mode: HeadroomAvailabilityMode = .adaptive,
        minimumAvailableMemoryBytes: UInt64? = nil,
        minimumAvailableStorageBytes: Int64? = nil,
        storageUsage: HeadroomStorageUsage = .important,
        allowsLowPowerMode: Bool = true,
        maximumThermalState: HeadroomThermalState? = nil
    ) {
        self.init(
            requiredTier: device.headroomTier,
            tierSource: HeadroomFeatureTierSource(mode),
            minimumAvailableMemoryBytes: minimumAvailableMemoryBytes,
            minimumAvailableStorageBytes: minimumAvailableStorageBytes,
            storageUsage: storageUsage,
            allowsLowPowerMode: allowsLowPowerMode,
            maximumThermalState: maximumThermalState
        )
    }
}

public enum HeadroomFeatureTierSource: String, Codable, Sendable {
    /// Gate using `effectiveTier`, including runtime pressure.
    case effective
    /// Gate using `hardwareTier`, ignoring current runtime pressure.
    case hardware

    init(_ mode: HeadroomAvailabilityMode) {
        switch mode {
        case .adaptive:
            self = .effective
        case .hardwareOnly:
            self = .hardware
        }
    }
}

public struct HeadroomFeatureAvailability: Equatable, Sendable {
    public let failures: [HeadroomAvailabilityFailure]

    public init(failures: [HeadroomAvailabilityFailure]) {
        self.failures = failures
    }

    public var isAvailable: Bool {
        failures.isEmpty
    }
}

public enum HeadroomAvailabilityFailure: Equatable, Sendable {
    case tier(required: HeadroomTier, current: HeadroomTier, source: HeadroomFeatureTierSource)
    case lowPowerMode
    case thermalState(current: HeadroomThermalState, maximum: HeadroomThermalState)
    case memory(requiredBytes: UInt64, availableBytes: UInt64?)
    case storage(requiredBytes: Int64, availableBytes: Int64?, usage: HeadroomStorageUsage)
}

enum HeadroomFeatureEvaluator {
    static func availability(
        of feature: HeadroomFeature,
        snapshot: HeadroomSnapshot,
        resources: HeadroomResources
    ) -> HeadroomFeatureAvailability {
        var failures: [HeadroomAvailabilityFailure] = []

        let currentTier: HeadroomTier
        switch feature.tierSource {
        case .effective:
            currentTier = snapshot.effectiveTier
        case .hardware:
            currentTier = snapshot.hardwareTier
        }

        if currentTier < feature.requiredTier {
            failures.append(.tier(required: feature.requiredTier, current: currentTier, source: feature.tierSource))
        }

        if !feature.allowsLowPowerMode, snapshot.signals.lowPowerModeEnabled {
            failures.append(.lowPowerMode)
        }

        if let maximumThermalState = feature.maximumThermalState,
           snapshot.signals.thermalState > maximumThermalState {
            failures.append(.thermalState(current: snapshot.signals.thermalState, maximum: maximumThermalState))
        }

        if let requiredMemory = feature.minimumAvailableMemoryBytes {
            let available = resources.memory.availableBytes
            if available.map({ $0 < requiredMemory }) ?? true {
                failures.append(.memory(requiredBytes: requiredMemory, availableBytes: available))
            }
        }

        if let requiredStorage = feature.minimumAvailableStorageBytes {
            let available = resources.storage.availableBytes(for: feature.storageUsage)
            if available.map({ $0 < requiredStorage }) ?? true {
                failures.append(.storage(
                    requiredBytes: requiredStorage,
                    availableBytes: available,
                    usage: feature.storageUsage
                ))
            }
        }

        return HeadroomFeatureAvailability(failures: failures)
    }
}
