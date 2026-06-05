import Foundation

enum EffectiveTierResolver {
    static func resolve(
        hardwareTier: HeadroomTier,
        signals: HeadroomSignals,
        policy: HeadroomPolicy = .default
    ) -> HeadroomTier {
        var tier = hardwareTier

        if signals.lowPowerModeEnabled, let cap = policy.lowPowerModeCap {
            tier = min(tier, cap)
        }

        switch signals.thermalState {
        case .nominal:
            break
        case .fair:
            if let cap = policy.fairThermalCap {
                tier = min(tier, cap)
            }
        case .serious:
            tier = tier.downgraded(by: policy.seriousThermalDowngrade)
        case .critical:
            tier = policy.criticalThermalTier
        case .unknown:
            if let cap = policy.unknownThermalCap {
                tier = min(tier, cap)
            }
        }

        if signals.physicalMemoryBytes > 0 {
            let memoryTier = HardwareTierResolver.tierForMemory(
                signals.physicalMemoryBytes,
                thresholds: policy.memoryTierThresholds
            )
            tier = min(tier, memoryTier.upgraded(by: policy.physicalMemoryCapHeadroom))
        }

        switch signals.memoryPressure {
        case .nominal:
            break
        case .constrained:
            tier = tier.downgraded(by: policy.constrainedMemoryDowngrade)
        case .critical:
            tier = tier.downgraded(by: policy.criticalMemoryDowngrade)
        case .unknown:
            break
        }

        return tier
    }
}
