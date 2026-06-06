import Foundation

struct HeadroomEvaluator: Sendable {
    private let signalProvider: HeadroomSignalProviding
    private let configuration: HeadroomConfiguration

    init(
        signalProvider: HeadroomSignalProviding = SystemHeadroomSignalProvider(),
        configuration: HeadroomConfiguration = HeadroomConfiguration()
    ) {
        self.signalProvider = signalProvider
        self.configuration = configuration
    }

    func snapshot() -> HeadroomSnapshot {
        let signals = signalProvider.signals(memoryPressurePolicy: configuration.policy.memoryPressurePolicy)

        let hardwareScore = configuration.forcedHardwareScore
            ?? HardwareScoreResolver.resolve(signals: signals, policy: configuration.policy)

        let effectiveScore = configuration.forcedEffectiveScore
            ?? EffectiveScoreResolver.resolve(
                hardwareScore: hardwareScore,
                signals: signals,
                policy: configuration.policy
            )

        return HeadroomSnapshot(
            hardwareScore: hardwareScore,
            effectiveScore: effectiveScore,
            signals: signals
        )
    }
}
