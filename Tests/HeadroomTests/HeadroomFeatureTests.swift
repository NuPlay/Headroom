import DeviceKit
@testable import Headroom
import Testing

@Test
func featureAvailabilityPassesWhenRequirementsAreMet() {
    let feature = HeadroomFeature(
        requiredTier: .high,
        minimumAvailableMemoryBytes: 256 * 1_048_576,
        minimumAvailableStorageBytes: 500,
        maximumThermalState: .fair
    )

    let result = HeadroomFeatureEvaluator.availability(
        of: feature,
        snapshot: featureSnapshot(effectiveTier: .high, thermalState: .nominal),
        resources: featureResources(availableMemoryBytes: 512 * 1_048_576, availableStorageBytes: 1000)
    )

    #expect(result.isAvailable)
}

@Test
func featureAvailabilityReportsFailures() {
    let feature = HeadroomFeature(
        requiredTier: .ultra,
        minimumAvailableMemoryBytes: 1000,
        minimumAvailableStorageBytes: 1000,
        allowsLowPowerMode: false,
        maximumThermalState: .fair
    )

    let result = HeadroomFeatureEvaluator.availability(
        of: feature,
        snapshot: featureSnapshot(effectiveTier: .medium, lowPowerModeEnabled: true, thermalState: .serious),
        resources: featureResources(availableMemoryBytes: 100, availableStorageBytes: 100)
    )

    #expect(!result.isAvailable)
    #expect(result.failures.count == 5)
}

@Test
func referenceDeviceMapsToExpectedScoreAndTier() {
    #expect(Device.unknown("iPhone12,1").headroomScore == 60)
    #expect(Device.unknown("iPhone14,5").headroomScore == 71)
    #expect(Device.unknown("iPhone16,1").headroomScore == 84)

    #expect(Device.unknown("iPhone12,1").headroomTier == .medium)
    #expect(Device.unknown("iPhone14,5").headroomTier == .high)
    #expect(Device.unknown("iPhone16,1").headroomTier == .ultra)
}

#if os(iOS)
    @Test
    func iPhoneCaseMapsToExpectedTier() {
        #expect(Device.iPhone13.headroomTier == .high)
        #expect(Device.iPhone15Pro.headroomTier == .ultra)
    }
#endif

@Test
func featureCanUseReferenceDeviceBaseline() {
    let feature = HeadroomFeature(Device.unknown("iPhone14,5"))

    let result = HeadroomFeatureEvaluator.availability(
        of: feature,
        snapshot: featureSnapshot(effectiveTier: .high),
        resources: featureResources(availableMemoryBytes: 512 * 1_048_576, availableStorageBytes: 1000)
    )

    #expect(result.isAvailable)
}

@Test
func globalConfigurationCanForceEffectiveTier() {
    HeadroomTestSupport.withIsolatedConfiguration {
        Headroom.configure {
            $0.forcedEffectiveTier = .low
        }

        #expect(Headroom.effectiveTier == .low)
    }
}

private func featureSnapshot(
    hardwareTier: HeadroomTier = .ultra,
    effectiveTier: HeadroomTier = .high,
    lowPowerModeEnabled: Bool = false,
    thermalState: HeadroomThermalState = .nominal
) -> HeadroomSnapshot {
    HeadroomSnapshot(
        hardwareTier: hardwareTier,
        effectiveTier: effectiveTier,
        signals: HeadroomSignals(
            deviceDescription: "Test Device",
            deviceOverrideKey: "Test Device",
            machineIdentifier: "iPhone17,1",
            isSimulator: false,
            physicalMemoryBytes: 8 * 1_073_741_824,
            availableMemoryBytes: 2 * 1_073_741_824,
            memoryPressure: .nominal,
            lowPowerModeEnabled: lowPowerModeEnabled,
            thermalState: thermalState,
            metalAppleGPUFamily: 9
        )
    )
}

private func featureResources(
    availableMemoryBytes: UInt64,
    availableStorageBytes: Int64
) -> HeadroomResources {
    HeadroomResources(
        memory: HeadroomMemoryInfo(
            physicalBytes: 8 * 1_073_741_824,
            availableBytes: availableMemoryBytes
        ),
        storage: HeadroomStorageInfo(
            totalCapacityBytes: 10000,
            availableCapacityBytes: availableStorageBytes,
            importantAvailableCapacityBytes: availableStorageBytes,
            opportunisticAvailableCapacityBytes: availableStorageBytes
        ),
        thermalState: .nominal,
        memoryPressure: .nominal
    )
}
