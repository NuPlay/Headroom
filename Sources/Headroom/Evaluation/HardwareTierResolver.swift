import Foundation

enum HardwareTierResolver {
    static func resolve(signals: HeadroomSignals, policy: HeadroomPolicy = .default) -> HeadroomTier {
        HardwareScoreResolver.resolve(signals: signals, policy: policy).tier
    }

    static func tierForMachineIdentifier(_ identifier: String) -> HeadroomTier? {
        HardwareScoreResolver.scoreForMachineIdentifier(identifier)?.tier
    }

    static func tierForMetalAppleGPUFamily(_ family: Int, policy: HeadroomPolicy = .default) -> HeadroomTier {
        HardwareScoreResolver.scoreForMetalAppleGPUFamily(family, policy: policy).tier
    }

    static func tierForMemory(
        _ bytes: UInt64,
        thresholds: HeadroomMemoryTierThresholds = .default
    ) -> HeadroomTier {
        HardwareScoreResolver.scoreForMemory(bytes, thresholds: thresholds).tier
    }
}
