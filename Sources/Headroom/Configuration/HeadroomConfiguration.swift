import Foundation
import DeviceKit

/// Global configuration for Headroom.
public struct HeadroomConfiguration: Equatable, Sendable {
    public var policy: HeadroomPolicy

    /// Overrides the resolved hardware tier. Useful for debugging, previews, and QA.
    public var forcedHardwareTier: HeadroomTier?

    /// Overrides the resolved effective tier. Useful for debugging, previews, and QA.
    public var forcedEffectiveTier: HeadroomTier?

    public init(
        policy: HeadroomPolicy = .default,
        forcedHardwareTier: HeadroomTier? = nil,
        forcedEffectiveTier: HeadroomTier? = nil
    ) {
        self.policy = policy
        self.forcedHardwareTier = forcedHardwareTier
        self.forcedEffectiveTier = forcedEffectiveTier
    }
}

public extension HeadroomConfiguration {
    var lowPowerModeCap: HeadroomTier? {
        get { policy.lowPowerModeCap }
        set { policy.lowPowerModeCap = newValue }
    }

    var fairThermalCap: HeadroomTier? {
        get { policy.fairThermalCap }
        set { policy.fairThermalCap = newValue }
    }

    var seriousThermalDowngrade: Int {
        get { policy.seriousThermalDowngrade }
        set { policy.seriousThermalDowngrade = newValue }
    }

    var criticalThermalTier: HeadroomTier {
        get { policy.criticalThermalTier }
        set { policy.criticalThermalTier = newValue }
    }

    var unknownThermalCap: HeadroomTier? {
        get { policy.unknownThermalCap }
        set { policy.unknownThermalCap = newValue }
    }

    var memoryPressurePolicy: HeadroomMemoryPressurePolicy {
        get { policy.memoryPressurePolicy }
        set { policy.memoryPressurePolicy = newValue }
    }

    var memoryTierThresholds: HeadroomMemoryTierThresholds {
        get { policy.memoryTierThresholds }
        set { policy.memoryTierThresholds = newValue }
    }

    mutating func overrideDevice(_ device: Device, as tier: HeadroomTier) {
        policy.deviceOverrides[device.headroomOverrideKey] = tier
    }

    mutating func removeDeviceOverride(_ device: Device) {
        policy.deviceOverrides.removeValue(forKey: device.headroomOverrideKey)
    }

    mutating func overrideMetalAppleGPUFamily(_ family: Int, as tier: HeadroomTier) {
        policy.metalFamilyOverrides[family] = tier
    }

    mutating func removeMetalAppleGPUFamilyOverride(_ family: Int) {
        policy.metalFamilyOverrides.removeValue(forKey: family)
    }
}
