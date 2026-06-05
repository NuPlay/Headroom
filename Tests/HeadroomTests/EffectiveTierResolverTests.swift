import Testing
@testable import Headroom

@Test
func effectiveTierResolverLowPowerCapsAtMedium() {
    let signals = makeHeadroomSignals(lowPowerModeEnabled: true)
    #expect(EffectiveTierResolver.resolve(hardwareTier: .ultra, signals: signals) == .medium)
}

@Test
func effectiveTierResolverCustomLowPowerCap() {
    var policy = HeadroomPolicy.default
    policy.lowPowerModeCap = .low

    let signals = makeHeadroomSignals(lowPowerModeEnabled: true)

    #expect(EffectiveTierResolver.resolve(hardwareTier: .ultra, signals: signals, policy: policy) == .low)
}

@Test
func effectiveTierResolverCriticalThermalCapsAtLow() {
    let signals = makeHeadroomSignals(thermalState: .critical)
    #expect(EffectiveTierResolver.resolve(hardwareTier: .ultra, signals: signals) == .low)
}

@Test
func effectiveTierResolverSeriousThermalDowngradesOneStep() {
    let signals = makeHeadroomSignals(thermalState: .serious)
    #expect(EffectiveTierResolver.resolve(hardwareTier: .ultra, signals: signals) == .high)
}

@Test
func effectiveTierResolverMemoryPressureDowngradesTier() {
    let constrained = makeHeadroomSignals(memoryPressure: .constrained)
    let critical = makeHeadroomSignals(memoryPressure: .critical)

    #expect(EffectiveTierResolver.resolve(hardwareTier: .ultra, signals: constrained) == .high)
    #expect(EffectiveTierResolver.resolve(hardwareTier: .ultra, signals: critical) == .medium)
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
        machineIdentifier: "iPhone17,1",
        isSimulator: false,
        physicalMemoryBytes: physicalMemoryBytes,
        availableMemoryBytes: 2 * 1_073_741_824,
        memoryPressure: memoryPressure,
        lowPowerModeEnabled: lowPowerModeEnabled,
        thermalState: thermalState,
        metalAppleGPUFamily: 9
    )
}
