import DeviceKit
import Foundation

/// A feature-level gate for expensive code paths.
public struct HeadroomFeature: Codable, Equatable, Sendable {
    /// Minimum normalized score required for this feature.
    public let requiredScore: HeadroomScore

    /// Which score Headroom should compare with `requiredScore`.
    public let tierSource: HeadroomFeatureTierSource

    /// Optional minimum currently available memory, in bytes.
    public let minimumAvailableMemoryBytes: UInt64?

    /// Optional minimum currently available storage, in bytes.
    public let minimumAvailableStorageBytes: Int64?

    /// Which storage-capacity reading to use for `minimumAvailableStorageBytes`.
    public let storageUsage: HeadroomStorageUsage

    /// Whether the feature may run while Low Power Mode is enabled.
    public let allowsLowPowerMode: Bool

    /// Optional maximum thermal state allowed for this feature.
    public let maximumThermalState: HeadroomThermalState?

    /// The coarse tier that contains `requiredScore`.
    public var requiredTier: HeadroomTier {
        requiredScore.tier
    }

    /// Creates a score-based feature gate.
    public init(
        requiredScore: HeadroomScore,
        tierSource: HeadroomFeatureTierSource = .effective,
        minimumAvailableMemoryBytes: UInt64? = nil,
        minimumAvailableStorageBytes: Int64? = nil,
        storageUsage: HeadroomStorageUsage = .important,
        allowsLowPowerMode: Bool = true,
        maximumThermalState: HeadroomThermalState? = nil
    ) {
        self.requiredScore = requiredScore
        self.tierSource = tierSource
        self.minimumAvailableMemoryBytes = Self.normalizedMinimumAvailableMemoryBytes(minimumAvailableMemoryBytes)
        self.minimumAvailableStorageBytes = Self.normalizedMinimumAvailableStorageBytes(minimumAvailableStorageBytes)
        self.storageUsage = storageUsage
        self.allowsLowPowerMode = allowsLowPowerMode
        self.maximumThermalState = maximumThermalState
    }

    /// Creates a score-based feature gate with typed resource requirements.
    public init(
        requiredScore: HeadroomScore,
        tierSource: HeadroomFeatureTierSource = .effective,
        resources: HeadroomFeatureResourceRequirements,
        allowsLowPowerMode: Bool = true,
        maximumThermalState: HeadroomThermalState? = nil
    ) {
        self.init(
            requiredScore: requiredScore,
            tierSource: tierSource,
            minimumAvailableMemoryBytes: resources.minimumAvailableMemoryBytes,
            minimumAvailableStorageBytes: resources.minimumAvailableStorageBytes,
            storageUsage: resources.storageUsage,
            allowsLowPowerMode: allowsLowPowerMode,
            maximumThermalState: maximumThermalState
        )
    }

    /// Creates a tier-based feature gate.
    public init(
        requiredTier: HeadroomTier,
        tierSource: HeadroomFeatureTierSource = .effective,
        minimumAvailableMemoryBytes: UInt64? = nil,
        minimumAvailableStorageBytes: Int64? = nil,
        storageUsage: HeadroomStorageUsage = .important,
        allowsLowPowerMode: Bool = true,
        maximumThermalState: HeadroomThermalState? = nil
    ) {
        self.init(
            requiredScore: requiredTier.minimumScore,
            tierSource: tierSource,
            minimumAvailableMemoryBytes: minimumAvailableMemoryBytes,
            minimumAvailableStorageBytes: minimumAvailableStorageBytes,
            storageUsage: storageUsage,
            allowsLowPowerMode: allowsLowPowerMode,
            maximumThermalState: maximumThermalState
        )
    }

    /// Creates a tier-based feature gate with typed resource requirements.
    public init(
        requiredTier: HeadroomTier,
        tierSource: HeadroomFeatureTierSource = .effective,
        resources: HeadroomFeatureResourceRequirements,
        allowsLowPowerMode: Bool = true,
        maximumThermalState: HeadroomThermalState? = nil
    ) {
        self.init(
            requiredScore: requiredTier.minimumScore,
            tierSource: tierSource,
            resources: resources,
            allowsLowPowerMode: allowsLowPowerMode,
            maximumThermalState: maximumThermalState
        )
    }

    /// Creates a feature gate from a DeviceKit reference device.
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
            requiredScore: device.headroomScore,
            tierSource: HeadroomFeatureTierSource(mode),
            minimumAvailableMemoryBytes: minimumAvailableMemoryBytes,
            minimumAvailableStorageBytes: minimumAvailableStorageBytes,
            storageUsage: storageUsage,
            allowsLowPowerMode: allowsLowPowerMode,
            maximumThermalState: maximumThermalState
        )
    }

    /// Creates a feature gate from a DeviceKit reference device with typed resource requirements.
    public init(
        _ device: Device,
        mode: HeadroomAvailabilityMode = .adaptive,
        resources: HeadroomFeatureResourceRequirements,
        allowsLowPowerMode: Bool = true,
        maximumThermalState: HeadroomThermalState? = nil
    ) {
        self.init(
            requiredScore: device.headroomScore,
            tierSource: HeadroomFeatureTierSource(mode),
            resources: resources,
            allowsLowPowerMode: allowsLowPowerMode,
            maximumThermalState: maximumThermalState
        )
    }

    private static func normalizedMinimumAvailableMemoryBytes(_ bytes: UInt64?) -> UInt64? {
        guard let bytes, bytes > 0 else { return nil }
        return bytes
    }

    private static func normalizedMinimumAvailableStorageBytes(_ bytes: Int64?) -> Int64? {
        guard let bytes, bytes > 0 else { return nil }
        return bytes
    }
}

extension HeadroomFeature {
    private enum CodingKeys: String, CodingKey {
        case requiredScore
        case tierSource
        case minimumAvailableMemoryBytes
        case minimumAvailableStorageBytes
        case storageUsage
        case allowsLowPowerMode
        case maximumThermalState
    }

    /// Decodes a feature gate, defaulting omitted optional policy fields to the public initializer defaults.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(
            requiredScore: container.decode(HeadroomScore.self, forKey: .requiredScore),
            tierSource: container.decodeIfPresent(HeadroomFeatureTierSource.self, forKey: .tierSource) ?? .effective,
            minimumAvailableMemoryBytes: container.decodeIfPresent(UInt64.self, forKey: .minimumAvailableMemoryBytes),
            minimumAvailableStorageBytes: container.decodeIfPresent(Int64.self, forKey: .minimumAvailableStorageBytes),
            storageUsage: container.decodeIfPresent(HeadroomStorageUsage.self, forKey: .storageUsage) ?? .important,
            allowsLowPowerMode: container.decodeIfPresent(Bool.self, forKey: .allowsLowPowerMode) ?? true,
            maximumThermalState: container.decodeIfPresent(HeadroomThermalState.self, forKey: .maximumThermalState)
        )
    }

    /// Encodes the stored feature-gate inputs. `requiredTier` is derived from `requiredScore`.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(requiredScore, forKey: .requiredScore)
        try container.encode(tierSource, forKey: .tierSource)
        try container.encodeIfPresent(minimumAvailableMemoryBytes, forKey: .minimumAvailableMemoryBytes)
        try container.encodeIfPresent(minimumAvailableStorageBytes, forKey: .minimumAvailableStorageBytes)
        try container.encode(storageUsage, forKey: .storageUsage)
        try container.encode(allowsLowPowerMode, forKey: .allowsLowPowerMode)
        try container.encodeIfPresent(maximumThermalState, forKey: .maximumThermalState)
    }
}

/// Score source used when evaluating a feature gate.
public enum HeadroomFeatureTierSource: String, Codable, Sendable {
    /// Gate using `effectiveScore`, including runtime pressure.
    case effective
    /// Gate using `hardwareScore`, ignoring current runtime pressure.
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

/// Detailed result for a feature availability decision.
public struct HeadroomFeatureAvailability: Codable, Equatable, Sendable {
    /// Failed checks. Empty means the feature is available.
    public let failures: [HeadroomAvailabilityFailure]

    /// Creates an availability result from explicit failures.
    public init(failures: [HeadroomAvailabilityFailure]) {
        self.failures = failures
    }

    /// Whether all feature requirements passed.
    public var isAvailable: Bool {
        failures.isEmpty
    }

    /// Stable failure kinds in evaluation order.
    public var failureKinds: [HeadroomAvailabilityFailureKind] {
        failures.map(\.kind)
    }

    /// Stable failure codes in evaluation order, suitable for logs and QA tooling.
    public var failureCodes: [String] {
        failures.map(\.code)
    }

    /// Human-readable explanations for every failed gate.
    public var failureDescriptions: [String] {
        failures.map(\.description)
    }

    /// Human-readable suggestions that can be logged or shown in internal diagnostics.
    public var recoverySuggestions: [String] {
        failures.map(\.recoverySuggestion)
    }

    /// A compact one-line summary suitable for logs and debug overlays.
    public var diagnosticSummary: String {
        guard !isAvailable else { return "Available" }
        return "Unavailable: " + failureDescriptions.joined(separator: "; ")
    }

    /// Returns whether the result contains at least one failure of `kind`.
    public func contains(_ kind: HeadroomAvailabilityFailureKind) -> Bool {
        failures.contains { $0.kind == kind }
    }

    /// Returns failures matching `kind`, preserving evaluation order.
    public func failures(of kind: HeadroomAvailabilityFailureKind) -> [HeadroomAvailabilityFailure] {
        failures.filter { $0.kind == kind }
    }
}

extension HeadroomFeatureAvailability: CustomStringConvertible {
    /// A compact human-readable summary of the availability result.
    public var description: String {
        diagnosticSummary
    }
}

/// Stable machine-readable category for a feature availability failure.
public enum HeadroomAvailabilityFailureKind: String, CaseIterable, Codable, Sendable {
    /// Current score is below the required score.
    case score

    /// Low Power Mode is enabled when the feature disallows it.
    case lowPowerMode

    /// Current thermal state is above the feature's maximum.
    case thermalState

    /// Available memory is missing or below the feature's requirement.
    case memory

    /// Available storage is missing or below the feature's requirement.
    case storage
}

/// A specific reason a feature is unavailable.
public enum HeadroomAvailabilityFailure: Codable, Equatable, Sendable {
    /// The current score is below the required score.
    case score(required: HeadroomScore, current: HeadroomScore, source: HeadroomFeatureTierSource)

    /// Low Power Mode is enabled and the feature does not allow it.
    case lowPowerMode

    /// Current thermal state is above the feature's maximum.
    case thermalState(current: HeadroomThermalState, maximum: HeadroomThermalState)

    /// Available memory is missing or below the feature's requirement.
    case memory(requiredBytes: UInt64, availableBytes: UInt64?)

    /// Available storage is missing or below the feature's requirement.
    case storage(requiredBytes: Int64, availableBytes: Int64?, usage: HeadroomStorageUsage)
}

extension HeadroomAvailabilityFailure {
    private enum CodingKeys: String, CodingKey {
        case kind
        case requiredScore
        case currentScore
        case source
        case currentThermalState
        case maximumThermalState
        case requiredBytes
        case availableBytes
        case usage
    }

    /// Decodes a stable, tagged diagnostic representation.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(HeadroomAvailabilityFailureKind.self, forKey: .kind)

        switch kind {
        case .score:
            self = try .score(
                required: container.decode(HeadroomScore.self, forKey: .requiredScore),
                current: container.decode(HeadroomScore.self, forKey: .currentScore),
                source: container.decodeIfPresent(HeadroomFeatureTierSource.self, forKey: .source) ?? .effective
            )
        case .lowPowerMode:
            self = .lowPowerMode
        case .thermalState:
            self = try .thermalState(
                current: container.decode(HeadroomThermalState.self, forKey: .currentThermalState),
                maximum: container.decode(HeadroomThermalState.self, forKey: .maximumThermalState)
            )
        case .memory:
            self = try .memory(
                requiredBytes: container.decode(UInt64.self, forKey: .requiredBytes),
                availableBytes: container.decodeIfPresent(UInt64.self, forKey: .availableBytes)
            )
        case .storage:
            self = try .storage(
                requiredBytes: container.decode(Int64.self, forKey: .requiredBytes),
                availableBytes: container.decodeIfPresent(Int64.self, forKey: .availableBytes),
                usage: container.decodeIfPresent(HeadroomStorageUsage.self, forKey: .usage) ?? .important
            )
        }
    }

    /// Encodes a stable, tagged diagnostic representation suitable for logs and support tickets.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(kind, forKey: .kind)

        switch self {
        case let .score(required, current, source):
            try container.encode(required, forKey: .requiredScore)
            try container.encode(current, forKey: .currentScore)
            try container.encode(source, forKey: .source)
        case .lowPowerMode:
            break
        case let .thermalState(current, maximum):
            try container.encode(current, forKey: .currentThermalState)
            try container.encode(maximum, forKey: .maximumThermalState)
        case let .memory(requiredBytes, availableBytes):
            try container.encode(requiredBytes, forKey: .requiredBytes)
            try container.encodeIfPresent(availableBytes, forKey: .availableBytes)
        case let .storage(requiredBytes, availableBytes, usage):
            try container.encode(requiredBytes, forKey: .requiredBytes)
            try container.encodeIfPresent(availableBytes, forKey: .availableBytes)
            try container.encode(usage, forKey: .usage)
        }
    }
}

extension HeadroomAvailabilityFailure: CustomStringConvertible {
    /// Stable machine-readable category for this failure.
    public var kind: HeadroomAvailabilityFailureKind {
        switch self {
        case .score:
            .score
        case .lowPowerMode:
            .lowPowerMode
        case .thermalState:
            .thermalState
        case .memory:
            .memory
        case .storage:
            .storage
        }
    }

    /// Stable machine-readable code for this failure.
    public var code: String {
        kind.rawValue
    }

    /// Human-readable explanation for this failure.
    public var description: String {
        switch self {
        case let .score(required, current, source):
            "Requires \(source.displayName) score \(required), but current score is \(current)."
        case .lowPowerMode:
            "Low Power Mode is enabled."
        case let .thermalState(current, maximum):
            "Thermal state is \(current.rawValue), above the allowed maximum \(maximum.rawValue)."
        case let .memory(requiredBytes, availableBytes):
            if let availableBytes {
                "Requires \(headroomFormatBytes(requiredBytes)) available memory, but only \(headroomFormatBytes(availableBytes)) is available."
            } else {
                "Requires \(headroomFormatBytes(requiredBytes)) available memory, but available memory could not be read."
            }
        case let .storage(requiredBytes, availableBytes, usage):
            if let availableBytes {
                "Requires \(headroomFormatBytes(requiredBytes)) available \(usage.displayName) storage, but only \(headroomFormatBytes(availableBytes)) is available."
            } else {
                "Requires \(headroomFormatBytes(requiredBytes)) available \(usage.displayName) storage, but available storage could not be read."
            }
        }
    }

    /// A short remediation hint for diagnostics and QA tooling.
    public var recoverySuggestion: String {
        switch self {
        case let .score(_, _, source):
            switch source {
            case .effective:
                "Use a lighter fallback, lower the required score, or wait for runtime pressure to improve."
            case .hardware:
                "Use a lighter fallback or lower the hardware-only requirement for this device class."
            }
        case .lowPowerMode:
            "Allow Low Power Mode for this feature or keep the fallback while Low Power Mode is enabled."
        case .thermalState:
            "Keep the fallback until the device cools down or raise maximumThermalState if the workload is safe."
        case .memory:
            "Release caches, reduce memory use, or lower minimumAvailableMemoryBytes."
        case .storage:
            "Free disk space, choose a smaller download/cache, or lower minimumAvailableStorageBytes."
        }
    }
}

enum HeadroomFeatureEvaluator {
    static func availability(
        of feature: HeadroomFeature,
        snapshot: HeadroomSnapshot,
        resources: HeadroomResources
    ) -> HeadroomFeatureAvailability {
        var failures: [HeadroomAvailabilityFailure] = []

        let currentScore: HeadroomScore = switch feature.tierSource {
        case .effective:
            snapshot.effectiveScore
        case .hardware:
            snapshot.hardwareScore
        }

        if currentScore < feature.requiredScore {
            failures.append(.score(required: feature.requiredScore, current: currentScore, source: feature.tierSource))
        }

        if !feature.allowsLowPowerMode, snapshot.signals.lowPowerModeEnabled {
            failures.append(.lowPowerMode)
        }

        if let maximumThermalState = feature.maximumThermalState,
           snapshot.signals.thermalState > maximumThermalState
        {
            failures.append(.thermalState(current: snapshot.signals.thermalState, maximum: maximumThermalState))
        }

        if let requiredMemory = feature.minimumAvailableMemoryBytes, requiredMemory > 0 {
            let available = resources.memory.availableBytes
            if available.map({ $0 < requiredMemory }) ?? true {
                failures.append(.memory(requiredBytes: requiredMemory, availableBytes: available))
            }
        }

        if let requiredStorage = feature.minimumAvailableStorageBytes, requiredStorage > 0 {
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

extension HeadroomFeatureTierSource {
    fileprivate var displayName: String {
        switch self {
        case .effective:
            "effective"
        case .hardware:
            "hardware"
        }
    }
}

extension HeadroomStorageUsage {
    fileprivate var displayName: String {
        switch self {
        case .regular:
            "regular"
        case .important:
            "important"
        case .opportunistic:
            "opportunistic"
        }
    }
}

private func headroomFormatBytes(_ bytes: UInt64) -> String {
    headroomFormatBytes(Double(bytes))
}

private func headroomFormatBytes(_ bytes: Int64) -> String {
    headroomFormatBytes(Double(max(0, bytes)))
}

private func headroomFormatBytes(_ bytes: Double) -> String {
    let units = ["bytes", "KiB", "MiB", "GiB", "TiB"]
    var value = bytes
    var unitIndex = 0

    while value >= 1024, unitIndex < units.count - 1 {
        value /= 1024
        unitIndex += 1
    }

    if unitIndex == 0 {
        return "\(Int(value)) \(units[unitIndex])"
    }

    if value.rounded() == value {
        return "\(Int(value)) \(units[unitIndex])"
    }

    return "\(String(format: "%.1f", value)) \(units[unitIndex])"
}
