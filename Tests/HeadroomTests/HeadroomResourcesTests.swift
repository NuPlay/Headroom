import Testing
@testable import Headroom

@Test
func memoryInfoPressureThresholds() {
    let physical = UInt64(4 * 1_073_741_824)

    #expect(HeadroomMemoryInfo(physicalBytes: physical, availableBytes: 2 * 1_073_741_824).pressure == .nominal)
    #expect(HeadroomMemoryInfo(physicalBytes: physical, availableBytes: 300 * 1_048_576).pressure == .constrained)
    #expect(HeadroomMemoryInfo(physicalBytes: physical, availableBytes: 100 * 1_048_576).pressure == .critical)
    #expect(HeadroomMemoryInfo(physicalBytes: physical).pressure == .unknown)
}

@Test
func memoryInfoCustomPressurePolicy() {
    let policy = HeadroomMemoryPressurePolicy(
        constrainedAvailableRatio: 0.50,
        criticalAvailableRatio: 0.25,
        constrainedAvailableBytes: 2 * 1_073_741_824,
        criticalAvailableBytes: 1 * 1_073_741_824
    )

    let memory = HeadroomMemoryInfo(
        physicalBytes: 4 * 1_073_741_824,
        availableBytes: 1_500 * 1_048_576
    )

    #expect(memory.pressure(using: policy) == .constrained)
}

@Test
func storageInfoConvenience() {
    let storage = HeadroomStorageInfo(
        totalCapacityBytes: 1_000,
        availableCapacityBytes: 300,
        importantAvailableCapacityBytes: 250,
        opportunisticAvailableCapacityBytes: 100
    )

    #expect(storage.usedCapacityBytes == 700)
    #expect(storage.availableBytes(for: .regular) == 300)
    #expect(storage.availableBytes(for: .important) == 250)
    #expect(storage.availableBytes(for: .opportunistic) == 100)
    #expect(storage.canFit(bytes: 200, usage: .important))
    #expect(!storage.canFit(bytes: 200, usage: .opportunistic))
}

@Test
func thermalStateConvenience() {
    #expect(!HeadroomThermalState.nominal.isPerformanceConstrained)
    #expect(HeadroomThermalState.fair.isPerformanceConstrained)
    #expect(HeadroomThermalState.serious.isPerformanceConstrained)
    #expect(HeadroomThermalState.critical.isPerformanceConstrained)
}
