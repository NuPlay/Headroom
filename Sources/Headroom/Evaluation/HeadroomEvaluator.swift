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

        let hardwareTier = configuration.forcedHardwareTier
            ?? HardwareTierResolver.resolve(signals: signals, policy: configuration.policy)

        let effectiveTier = configuration.forcedEffectiveTier
            ?? EffectiveTierResolver.resolve(
                hardwareTier: hardwareTier,
                signals: signals,
                policy: configuration.policy
            )

        return HeadroomSnapshot(
            hardwareTier: hardwareTier,
            effectiveTier: effectiveTier,
            signals: signals
        )
    }
}
