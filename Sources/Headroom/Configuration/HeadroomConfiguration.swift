import Foundation
import DeviceKit

/// Global configuration for Headroom.
public struct HeadroomConfiguration: Equatable, Sendable {
    public var policy: HeadroomPolicy

    /// Overrides the resolved hardware score. Useful for debugging, previews, and QA.
    public var forcedHardwareScore: HeadroomScore?

    /// Overrides the resolved effective score. Useful for debugging, previews, and QA.
    public var forcedEffectiveScore: HeadroomScore?

    public init(
        policy: HeadroomPolicy = .default,
        forcedHardwareScore: HeadroomScore? = nil,
        forcedEffectiveScore: HeadroomScore? = nil
    ) {
        self.policy = policy
        self.forcedHardwareScore = forcedHardwareScore
        self.forcedEffectiveScore = forcedEffectiveScore
    }
}

public extension HeadroomConfiguration {
    /// Compatibility convenience for code that still thinks in tiers.
    var forcedHardwareTier: HeadroomTier? {
        get { forcedHardwareScore?.tier }
        set { forcedHardwareScore = newValue?.representativeScore }
    }

    /// Compatibility convenience for code that still thinks in tiers.
    var forcedEffectiveTier: HeadroomTier? {
        get { forcedEffectiveScore?.tier }
        set { forcedEffectiveScore = newValue?.representativeScore }
    }

    var lowPowerModePenalty: Int {
        get { policy.lowPowerModePenalty }
        set { policy.lowPowerModePenalty = newValue }
    }

    var fairThermalPenalty: Int {
        get { policy.fairThermalPenalty }
        set { policy.fairThermalPenalty = newValue }
    }

    var seriousThermalPenalty: Int {
        get { policy.seriousThermalPenalty }
        set { policy.seriousThermalPenalty = newValue }
    }

    var criticalThermalScore: HeadroomScore {
        get { policy.criticalThermalScore }
        set { policy.criticalThermalScore = newValue }
    }

    var unknownThermalPenalty: Int {
        get { policy.unknownThermalPenalty }
        set { policy.unknownThermalPenalty = newValue }
    }

    var memoryPressurePolicy: HeadroomMemoryPressurePolicy {
        get { policy.memoryPressurePolicy }
        set { policy.memoryPressurePolicy = newValue }
    }

    var memoryScoreThresholds: HeadroomMemoryScoreThresholds {
        get { policy.memoryScoreThresholds }
        set { policy.memoryScoreThresholds = newValue }
    }

    var memoryTierThresholds: HeadroomMemoryTierThresholds {
        get { policy.memoryScoreThresholds }
        set { policy.memoryScoreThresholds = newValue }
    }

    mutating func overrideDevice(_ device: Device, as score: HeadroomScore) {
        policy.deviceOverrides[device.headroomOverrideKey] = score
    }

    mutating func overrideDevice(_ device: Device, as tier: HeadroomTier) {
        overrideDevice(device, as: tier.representativeScore)
    }

    mutating func removeDeviceOverride(_ device: Device) {
        policy.deviceOverrides.removeValue(forKey: device.headroomOverrideKey)
    }

    mutating func overrideMetalAppleGPUFamily(_ family: Int, as score: HeadroomScore) {
        policy.metalFamilyOverrides[family] = score
    }

    mutating func overrideMetalAppleGPUFamily(_ family: Int, as tier: HeadroomTier) {
        overrideMetalAppleGPUFamily(family, as: tier.representativeScore)
    }

    mutating func removeMetalAppleGPUFamilyOverride(_ family: Int) {
        policy.metalFamilyOverrides.removeValue(forKey: family)
    }
}
