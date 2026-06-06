@testable import Headroom
import Testing

@Test
func effectiveScoreResolverLowPowerAppliesModestPenalty() {
    let signals = makeHeadroomSignals(lowPowerModeEnabled: true)

    #expect(EffectiveScoreResolver.resolve(hardwareScore: 84, signals: signals).rawValue == 76)
    #expect(EffectiveScoreResolver.resolve(hardwareScore: 71, signals: signals).rawValue == 63)
}

@Test
func effectiveScoreResolverCustomLowPowerPenalty() {
    var policy = HeadroomPolicy.default
    policy.lowPowerModePenalty = 20

    let signals = makeHeadroomSignals(lowPowerModeEnabled: true)

    #expect(EffectiveScoreResolver.resolve(hardwareScore: 84, signals: signals, policy: policy).rawValue == 64)
}

@Test
func effectiveScoreResolverCriticalThermalCapsScore() {
    let signals = makeHeadroomSignals(thermalState: .critical)
    #expect(EffectiveScoreResolver.resolve(hardwareScore: 84, signals: signals) == 25)
}

@Test
func effectiveScoreResolverSeriousThermalAppliesPenalty() {
    let signals = makeHeadroomSignals(thermalState: .serious)
    #expect(EffectiveScoreResolver.resolve(hardwareScore: 84, signals: signals).rawValue == 74)
}

@Test
func effectiveScoreResolverFairThermalDoesNotPenalizeByDefault() {
    let signals = makeHeadroomSignals(thermalState: .fair)
    #expect(EffectiveScoreResolver.resolve(hardwareScore: 84, signals: signals) == 84)
}

@Test
func effectiveScoreResolverModernProCanStillMeetIPhone13BaselineUnderSinglePressure() {
    let lowPower = makeHeadroomSignals(lowPowerModeEnabled: true)
    let seriousThermal = makeHeadroomSignals(thermalState: .serious)
    let constrainedMemory = makeHeadroomSignals(memoryPressure: .constrained)

    let iPhone15ProScore = HeadroomScore(84)
    let iPhone13Score = HeadroomScore(71)

    #expect(EffectiveScoreResolver.resolve(hardwareScore: iPhone15ProScore, signals: lowPower) >= iPhone13Score)
    #expect(EffectiveScoreResolver.resolve(hardwareScore: iPhone15ProScore, signals: seriousThermal) >= iPhone13Score)
    #expect(EffectiveScoreResolver.resolve(hardwareScore: iPhone15ProScore, signals: constrainedMemory) >= iPhone13Score)
}

@Test
func effectiveScoreResolverMultiplePressuresCanDropBelowIPhone13Baseline() {
    let signals = makeHeadroomSignals(
        lowPowerModeEnabled: true,
        thermalState: .serious,
        memoryPressure: .constrained
    )

    #expect(EffectiveScoreResolver.resolve(hardwareScore: 84, signals: signals).rawValue == 58)
    #expect(EffectiveScoreResolver.resolve(hardwareScore: 84, signals: signals) < 71)
}

@Test
func effectiveScoreResolverMemoryPressureAppliesPenalty() {
    let constrained = makeHeadroomSignals(memoryPressure: .constrained)
    let critical = makeHeadroomSignals(memoryPressure: .critical)

    #expect(EffectiveScoreResolver.resolve(hardwareScore: 84, signals: constrained).rawValue == 76)
    #expect(EffectiveScoreResolver.resolve(hardwareScore: 84, signals: critical).rawValue == 66)
}

@Test
func effectiveTierResolverCompatibilityUsesScoreThresholds() {
    let lowPower = makeHeadroomSignals(lowPowerModeEnabled: true)

    #expect(EffectiveTierResolver.resolve(hardwareTier: .ultra, signals: lowPower) == .high)
    #expect(EffectiveTierResolver.resolve(hardwareTier: .high, signals: lowPower) == .medium)
}

private func makeHeadroomSignals(
    lowPowerModeEnabled: Bool = false,
    thermalState: HeadroomThermalState = .nominal,
    memoryPressure: HeadroomMemoryPressure = .nominal,
    physicalMemoryBytes: UInt64 = 8 * 1_073_741_824
) -> HeadroomSignals {
    HeadroomSignals(
        deviceDescription: "Test Device",
        deviceOverrideKey: "Test Device",
        machineIdentifier: "iPhone16,1",
        isSimulator: false,
        physicalMemoryBytes: physicalMemoryBytes,
        deviceKitScore: 84,
        availableMemoryBytes: 2 * 1_073_741_824,
        memoryPressure: memoryPressure,
        lowPowerModeEnabled: lowPowerModeEnabled,
        thermalState: thermalState,
        metalAppleGPUFamily: 9
    )
}
