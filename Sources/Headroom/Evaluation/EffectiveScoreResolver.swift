import Foundation

enum EffectiveScoreResolver {
    static func resolve(
        hardwareScore: HeadroomScore,
        signals: HeadroomSignals,
        policy: HeadroomPolicy = .default
    ) -> HeadroomScore {
        var score = hardwareScore

        if signals.lowPowerModeEnabled {
            score = score.penalized(by: policy.lowPowerModePenalty)
        }

        switch signals.thermalState {
        case .nominal:
            break
        case .fair:
            score = score.penalized(by: policy.fairThermalPenalty)
        case .serious:
            score = score.penalized(by: policy.seriousThermalPenalty)
        case .critical:
            score = min(score, policy.criticalThermalScore)
        case .unknown:
            score = score.penalized(by: policy.unknownThermalPenalty)
        }

        if signals.physicalMemoryBytes > 0 {
            let memoryScore = HardwareScoreResolver.scoreForMemory(
                signals.physicalMemoryBytes,
                thresholds: policy.memoryScoreThresholds
            )
            score = min(score, memoryScore.adjusted(by: policy.physicalMemoryScoreHeadroom))
        }

        switch signals.memoryPressure {
        case .nominal:
            break
        case .constrained:
            score = score.penalized(by: policy.constrainedMemoryPenalty)
        case .critical:
            score = score.penalized(by: policy.criticalMemoryPenalty)
        case .unknown:
            break
        }

        return score
    }
}
