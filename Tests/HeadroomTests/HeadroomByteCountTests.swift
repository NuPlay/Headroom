@testable import Headroom
import Testing

@Test
func byteCountFactoriesUseExpectedUnitsAndClampStorageBytes() {
    #expect(HeadroomByteCount.zero.bytes == 0)
    #expect(HeadroomByteCount.bytes(42).bytes == 42)
    #expect(HeadroomByteCount.kilobytes(3).bytes == 3000)
    #expect(HeadroomByteCount.megabytes(3).bytes == 3_000_000)
    #expect(HeadroomByteCount.gigabytes(3).bytes == 3_000_000_000)
    #expect(HeadroomByteCount.kibibytes(3).bytes == 3 * 1024)
    #expect(HeadroomByteCount.mebibytes(3).bytes == 3 * 1_048_576)
    #expect(HeadroomByteCount.gibibytes(3).bytes == 3 * 1_073_741_824)
    #expect(HeadroomByteCount.tebibytes(1).description == "1 TiB")
    #expect(HeadroomByteCount(bytes: UInt64.max).storageBytes == Int64.max)
}

@Test
func featureResourceRequirementsBridgeTypedByteCounts() {
    let resources = HeadroomFeatureResourceRequirements(
        memory: .mebibytes(300),
        storage: .gibibytes(2),
        storageUsage: .opportunistic
    )

    #expect(!resources.isEmpty)
    #expect(resources.minimumAvailableMemoryBytes == UInt64(300 * 1_048_576))
    #expect(resources.minimumAvailableStorageBytes == Int64(2 * 1_073_741_824))
    #expect(resources.storageUsage == .opportunistic)

    let feature = HeadroomFeature(
        requiredScore: 71,
        resources: resources,
        allowsLowPowerMode: false,
        maximumThermalState: .fair
    )

    #expect(feature.minimumAvailableMemoryBytes == resources.minimumAvailableMemoryBytes)
    #expect(feature.minimumAvailableStorageBytes == resources.minimumAvailableStorageBytes)
    #expect(feature.storageUsage == .opportunistic)
    #expect(!feature.allowsLowPowerMode)
    #expect(feature.maximumThermalState == .fair)
}

@Test
func emptyFeatureResourceRequirementsNormalizeToNoRequirement() {
    let resources = HeadroomFeatureResourceRequirements(
        minimumAvailableMemoryBytes: 0,
        minimumAvailableStorageBytes: -100
    )

    #expect(resources.isEmpty)
    #expect(resources.minimumAvailableMemoryBytes == nil)
    #expect(resources.minimumAvailableStorageBytes == nil)
    #expect(HeadroomFeatureResourceRequirements.none == resources)
}
