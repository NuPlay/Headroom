import DeviceKit
import Foundation

/// Global configuration for Headroom.
public struct HeadroomConfiguration: Codable, Equatable, Sendable {
    /// Score and pressure policy used by Headroom.
    public var policy: HeadroomPolicy

    /// Overrides the resolved hardware score. Useful for debugging, previews, and QA.
    public var forcedHardwareScore: HeadroomScore?

    /// Overrides the resolved effective score. Useful for debugging, previews, and QA.
    public var forcedEffectiveScore: HeadroomScore?

    /// Creates a configuration.
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

extension HeadroomConfiguration {
    /// Compatibility convenience for code that still thinks in tiers.
    public var forcedHardwareTier: HeadroomTier? {
        get { forcedHardwareScore?.tier }
        set { forcedHardwareScore = newValue?.representativeScore }
    }

    /// Compatibility convenience for code that still thinks in tiers.
    public var forcedEffectiveTier: HeadroomTier? {
        get { forcedEffectiveScore?.tier }
        set { forcedEffectiveScore = newValue?.representativeScore }
    }

    /// Convenience access to `policy.lowPowerModePenalty`.
    public var lowPowerModePenalty: Int {
        get { policy.lowPowerModePenalty }
        set { policy.lowPowerModePenalty = newValue }
    }

    /// Convenience access to `policy.fairThermalPenalty`.
    public var fairThermalPenalty: Int {
        get { policy.fairThermalPenalty }
        set { policy.fairThermalPenalty = newValue }
    }

    /// Convenience access to `policy.seriousThermalPenalty`.
    public var seriousThermalPenalty: Int {
        get { policy.seriousThermalPenalty }
        set { policy.seriousThermalPenalty = newValue }
    }

    /// Convenience access to `policy.criticalThermalScore`.
    public var criticalThermalScore: HeadroomScore {
        get { policy.criticalThermalScore }
        set { policy.criticalThermalScore = newValue }
    }

    /// Convenience access to `policy.unknownThermalPenalty`.
    public var unknownThermalPenalty: Int {
        get { policy.unknownThermalPenalty }
        set { policy.unknownThermalPenalty = newValue }
    }

    /// Convenience access to `policy.memoryPressurePolicy`.
    public var memoryPressurePolicy: HeadroomMemoryPressurePolicy {
        get { policy.memoryPressurePolicy }
        set { policy.memoryPressurePolicy = newValue }
    }

    /// Convenience access to `policy.memoryScoreThresholds`.
    public var memoryScoreThresholds: HeadroomMemoryScoreThresholds {
        get { policy.memoryScoreThresholds }
        set { policy.memoryScoreThresholds = newValue }
    }

    /// Deprecated compatibility convenience for older tier terminology.
    public var memoryTierThresholds: HeadroomMemoryTierThresholds {
        get { policy.memoryScoreThresholds }
        set { policy.memoryScoreThresholds = newValue }
    }

    /// Overrides the score for a DeviceKit device.
    public mutating func overrideDevice(_ device: Device, as score: HeadroomScore) {
        policy.deviceOverrides[device.headroomOverrideKey] = score
    }

    /// Overrides the score for a DeviceKit device using a tier's representative score.
    public mutating func overrideDevice(_ device: Device, as tier: HeadroomTier) {
        overrideDevice(device, as: tier.representativeScore)
    }

    /// Removes a DeviceKit device override.
    public mutating func removeDeviceOverride(_ device: Device) {
        policy.deviceOverrides.removeValue(forKey: device.headroomOverrideKey)
    }

    /// Overrides the score for a Metal Apple GPU family number.
    public mutating func overrideMetalAppleGPUFamily(_ family: Int, as score: HeadroomScore) {
        policy.metalFamilyOverrides[family] = score
    }

    /// Overrides the score for a Metal Apple GPU family number using a tier's representative score.
    public mutating func overrideMetalAppleGPUFamily(_ family: Int, as tier: HeadroomTier) {
        overrideMetalAppleGPUFamily(family, as: tier.representativeScore)
    }

    /// Removes a Metal Apple GPU family override.
    public mutating func removeMetalAppleGPUFamilyOverride(_ family: Int) {
        policy.metalFamilyOverrides.removeValue(forKey: family)
    }
}
