import DeviceKit
@testable import Headroom
import Testing

@Test
func hardwareTierResolverIPhoneIdentifierMapping() {
    #expect(HardwareTierResolver.tierForMachineIdentifier("iPhone10,6") == .low)
    #expect(HardwareTierResolver.tierForMachineIdentifier("iPhone11,2") == .medium)
    #expect(HardwareTierResolver.tierForMachineIdentifier("iPhone14,3") == .high)
    #expect(HardwareTierResolver.tierForMachineIdentifier("iPhone17,1") == .ultra)
}

@Test
func hardwareScoreResolverReferenceScores() {
    #expect(HardwareScoreResolver.scoreForMachineIdentifier("iPhone14,5") == 71)
    #expect(HardwareScoreResolver.scoreForMachineIdentifier("iPhone16,1") == 84)
    #expect(HardwareScoreResolver.scoreForMachineIdentifier("iPhone17,1") == 92)
}

#if os(iOS)
@Test
func iPhoneScoresUseGeekbench6BenchmarkAnchors() {
    for benchmark in geekbench6IPhoneBenchmarks {
        #expect(benchmark.device.headroomScore == benchmark.headroomScore)
    }
}

@Test
func iPhoneScoresPreserveGeekbench6CPUOrdering() {
    let orderedBenchmarks = geekbench6IPhoneBenchmarks.sorted {
        $0.cpuCompositeScore < $1.cpuCompositeScore
    }

    for (lower, higher) in zip(orderedBenchmarks, orderedBenchmarks.dropFirst()) {
        #expect(lower.device.headroomScore <= higher.device.headroomScore)
    }
}

@Test
func iPhoneScoresKeepImportantGeekbench6VariantDeltas() {
    #expect(score("iPhone SE (2nd generation)") < score("iPhone 11"))
    #expect(score("iPhone 11") < score("iPhone 11 Pro"))
    #expect(score("iPhone 11 Pro") < score("iPhone 11 Pro Max"))

    #expect(score("iPhone 12") < score("iPhone 12 Pro"))
    #expect(score("iPhone 12 Pro") < score("iPhone 12 Pro Max"))

    #expect(score("iPhone 13 mini") < score("iPhone 13 Pro"))
    #expect(score("iPhone 17") < score("iPhone Air"))
    #expect(score("iPhone Air") < score("iPhone 17 Pro"))
}
#endif

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

#if os(iOS)
private func score(_ model: String) -> HeadroomScore {
    let benchmark = geekbench6IPhoneBenchmarks.first { $0.model == model }!
    return benchmark.device.headroomScore
}

private struct Geekbench6IPhoneBenchmark {
    let model: String
    let device: Device
    let singleCoreScore: Int
    let multiCoreScore: Int
    let headroomScore: HeadroomScore

    var cpuCompositeScore: Int {
        singleCoreScore + multiCoreScore
    }
}

private func benchmark(
    _ model: String,
    _ device: Device,
    _ singleCoreScore: Int,
    _ multiCoreScore: Int,
    _ headroomScore: HeadroomScore
) -> Geekbench6IPhoneBenchmark {
    Geekbench6IPhoneBenchmark(
        model: model,
        device: device,
        singleCoreScore: singleCoreScore,
        multiCoreScore: multiCoreScore,
        headroomScore: headroomScore
    )
}

// Snapshot from the Geekbench Browser iPhone benchmarks chart, checked 2026-06-07.
// iPhone 17e is anchored from an official Geekbench Browser result because it is
// not listed in the aggregate chart used for the other devices.
// Headroom scores are normalized buckets, not raw Geekbench scores.
private let geekbench6IPhoneBenchmarks: [Geekbench6IPhoneBenchmark] = [
    benchmark("iPhone 17 Pro Max", .iPhone17ProMax, 3789, 9843, 100),
    benchmark("iPhone 17 Pro", .iPhone17Pro, 3775, 9817, 100),
    benchmark("iPhone Air", .iPhoneAir, 3675, 9441, 96),
    benchmark("iPhone 17", .iPhone17, 3615, 9254, 95),
    benchmark("iPhone 17e", .iPhone17e, 3565, 8770, 95),
    benchmark("iPhone 16 Pro", .iPhone16Pro, 3445, 8640, 92),
    benchmark("iPhone 16 Pro Max", .iPhone16ProMax, 3426, 8541, 92),
    benchmark("iPhone 16", .iPhone16, 3318, 8301, 90),
    benchmark("iPhone 16 Plus", .iPhone16Plus, 3322, 8286, 90),
    benchmark("iPhone 16e", .iPhone16e, 3243, 8005, 90),
    benchmark("iPhone 15 Pro", .iPhone15Pro, 2883, 7203, 84),
    benchmark("iPhone 15 Pro Max", .iPhone15ProMax, 2876, 7163, 84),
    benchmark("iPhone 14 Pro", .iPhone14Pro, 2616, 6712, 79),
    benchmark("iPhone 14 Pro Max", .iPhone14ProMax, 2608, 6681, 79),
    benchmark("iPhone 15 Plus", .iPhone15Plus, 2553, 6355, 79),
    benchmark("iPhone 15", .iPhone15, 2552, 6339, 79),
    benchmark("iPhone 13 Pro Max", .iPhone13ProMax, 2350, 5759, 74),
    benchmark("iPhone 13 Pro", .iPhone13Pro, 2348, 5742, 74),
    benchmark("iPhone 14", .iPhone14, 2275, 5571, 74),
    benchmark("iPhone 14 Plus", .iPhone14Plus, 2272, 5570, 74),
    benchmark("iPhone SE (3rd generation)", .iPhoneSE3, 2269, 5451, 74),
    benchmark("iPhone 13 mini", .iPhone13Mini, 2224, 5234, 71),
    benchmark("iPhone 13", .iPhone13, 2215, 5236, 71),
    benchmark("iPhone 12 Pro Max", .iPhone12ProMax, 2128, 4974, 68),
    benchmark("iPhone 12 Pro", .iPhone12Pro, 2082, 4749, 67),
    benchmark("iPhone 12 mini", .iPhone12Mini, 2034, 4589, 66),
    benchmark("iPhone 12", .iPhone12, 2030, 4578, 66),
    benchmark("iPhone 11 Pro Max", .iPhone11ProMax, 1719, 3852, 62),
    benchmark("iPhone 11 Pro", .iPhone11Pro, 1705, 3781, 61),
    benchmark("iPhone 11", .iPhone11, 1703, 3648, 60),
    benchmark("iPhone SE (2nd generation)", .iPhoneSE2, 1671, 3025, 56),
    benchmark("iPhone XS Max", .iPhoneXSMax, 1287, 2664, 50),
    benchmark("iPhone XS", .iPhoneXS, 1286, 2654, 50),
    benchmark("iPhone XR", .iPhoneXR, 1249, 2260, 50),
    benchmark("iPhone 8 Plus", .iPhone8Plus, 1058, 2264, 39),
    benchmark("iPhone X", .iPhoneX, 1052, 2062, 39),
    benchmark("iPhone 8", .iPhone8, 1037, 1720, 39)
]
#endif
