import Foundation

enum EffectiveTierResolver {
    static func resolve(
        hardwareTier: HeadroomTier,
        signals: HeadroomSignals,
        policy: HeadroomPolicy = .default
    ) -> HeadroomTier {
        EffectiveScoreResolver.resolve(
            hardwareScore: hardwareTier.representativeScore,
            signals: signals,
            policy: policy
        ).tier
    }
}
