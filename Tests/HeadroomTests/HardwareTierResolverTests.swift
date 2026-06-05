import Testing
import DeviceKit
@testable import Headroom

@Test
func hardwareTierResolverIPhoneIdentifierMapping() {
    #expect(HardwareTierResolver.tierForMachineIdentifier("iPhone10,6") == .low)
    #expect(HardwareTierResolver.tierForMachineIdentifier("iPhone11,2") == .medium)
    #expect(HardwareTierResolver.tierForMachineIdentifier("iPhone14,3") == .high)
    #expect(HardwareTierResolver.tierForMachineIdentifier("iPhone17,1") == .ultra)
}

@Test
func hardwareTierResolverMetalFamilyMapping() {
    #expect(HardwareTierResolver.tierForMetalAppleGPUFamily(5) == .medium)
    #expect(HardwareTierResolver.tierForMetalAppleGPUFamily(7) == .high)
    #expect(HardwareTierResolver.tierForMetalAppleGPUFamily(9) == .ultra)
}

@Test
func hardwareTierResolverMetalFamilyCanUpgradeIdentifierMapping() {
    let signals = makeSignals(
        machineIdentifier: "iPhone16,1",
        physicalMemoryBytes: 8 * 1_073_741_824,
        metalAppleGPUFamily: 9
    )

    #expect(HardwareTierResolver.resolve(signals: signals) == .ultra)
}

@Test
func hardwareTierResolverDeviceOverrideWins() {
    var configuration = HeadroomConfiguration()
    configuration.overrideDevice(Device.unknown("iPhone10,6"), as: .ultra)

    let signals = makeSignals(machineIdentifier: "iPhone10,6")
    let policy = configuration.policy

    #expect(HardwareTierResolver.resolve(signals: signals, policy: policy) == .ultra)
}

@Test
func hardwareTierResolverCustomMemoryThresholds() {
    let thresholds = HeadroomMemoryTierThresholds(
        mediumBytes: 512 * 1_048_576,
        highBytes: 1 * 1_073_741_824,
        ultraBytes: 2 * 1_073_741_824
    )

    #expect(HardwareTierResolver.tierForMemory(2 * 1_073_741_824, thresholds: thresholds) == .ultra)
}

@Test
func hardwareTierResolverMemoryMapping() {
    #expect(HardwareTierResolver.tierForMemory(1 * 1_073_741_824) == .low)
    #expect(HardwareTierResolver.tierForMemory(3 * 1_073_741_824) == .medium)
    #expect(HardwareTierResolver.tierForMemory(6 * 1_073_741_824) == .high)
    #expect(HardwareTierResolver.tierForMemory(8 * 1_073_741_824) == .ultra)
}

private func makeSignals(
    machineIdentifier: String? = "iPhone17,1",
    physicalMemoryBytes: UInt64 = 8 * 1_073_741_824,
    metalAppleGPUFamily: Int? = 9
) -> HeadroomSignals {
    HeadroomSignals(
        deviceDescription: "Test Device",
        deviceOverrideKey: machineIdentifier,
        machineIdentifier: machineIdentifier,
        isSimulator: false,
        physicalMemoryBytes: physicalMemoryBytes,
        availableMemoryBytes: 2 * 1_073_741_824,
        memoryPressure: .nominal,
        lowPowerModeEnabled: false,
        thermalState: .nominal,
        metalAppleGPUFamily: metalAppleGPUFamily
    )
}
