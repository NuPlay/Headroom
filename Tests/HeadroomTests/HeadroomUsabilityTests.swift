import Foundation
@testable import Headroom
import Testing

@Test
func modeBasedScoreAndAvailabilityAPIsUseForcedScores() {
    HeadroomTestSupport.withIsolatedConfiguration {
        Headroom.configure {
            $0.forcedHardwareScore = 84
            $0.forcedEffectiveScore = 60
        }

        #expect(Headroom.score() == 60)
        #expect(Headroom.score(for: .adaptive) == 60)
        #expect(Headroom.score(for: .hardwareOnly) == 84)
        #expect(Headroom.tier() == .medium)
        #expect(Headroom.tier(for: .hardwareOnly) == .ultra)

        #expect(!Headroom.isAvailable(70))
        #expect(Headroom.isAvailable(70, mode: .hardwareOnly))
        #expect(!Headroom.isAvailable(.high))
        #expect(Headroom.isAvailable(.high, mode: .hardwareOnly))
    }
}

@Test
func configurationCanBeReadInsideConfigureClosure() {
    HeadroomTestSupport.withIsolatedConfiguration {
        Headroom.configure {
            _ = Headroom.configuration
            $0.forcedEffectiveScore = 42
        }

        #expect(Headroom.effectiveScore == 42)
    }
}

@Test
func featureAvailabilityProvidesReadableDiagnostics() {
    let availability = HeadroomFeatureAvailability(failures: [
        .score(required: 84, current: 60, source: .effective),
        .lowPowerMode,
        .memory(requiredBytes: 512 * 1_048_576, availableBytes: 128 * 1_048_576),
        .storage(requiredBytes: 2 * 1_073_741_824, availableBytes: nil, usage: .important),
    ])

    #expect(!availability.isAvailable)
    #expect(availability.failureKinds == [.score, .lowPowerMode, .memory, .storage])
    #expect(availability.failureCodes == ["score", "lowPowerMode", "memory", "storage"])
    #expect(availability.contains(.memory))
    #expect(!availability.contains(.thermalState))
    #expect(availability.failures(of: .lowPowerMode) == [.lowPowerMode])
    #expect(availability.failureDescriptions == [
        "Requires effective score 84, but current score is 60.",
        "Low Power Mode is enabled.",
        "Requires 512 MiB available memory, but only 128 MiB is available.",
        "Requires 2 GiB available important storage, but available storage could not be read.",
    ])
    #expect(availability.recoverySuggestions.count == 4)
    #expect(availability.diagnosticSummary.hasPrefix("Unavailable: Requires effective score 84"))
    #expect(String(describing: HeadroomFeatureAvailability(failures: [])) == "Available")
}

@Test
func availabilityFailureCodableUsesStableTaggedDiagnosticShape() throws {
    let failure = HeadroomAvailabilityFailure.score(required: 84, current: 60, source: .effective)

    let data = try JSONEncoder().encode(failure)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(object["kind"] as? String == "score")
    #expect(object["requiredScore"] as? Int == 84)
    #expect(object["currentScore"] as? Int == 60)
    #expect(object["source"] as? String == "effective")
    #expect(try JSONDecoder().decode(HeadroomAvailabilityFailure.self, from: data) == failure)

    let storageFailure = HeadroomAvailabilityFailure.storage(
        requiredBytes: 2 * 1_073_741_824,
        availableBytes: nil,
        usage: .important
    )
    let storageData = try JSONEncoder().encode(storageFailure)
    let storageObject = try #require(JSONSerialization.jsonObject(with: storageData) as? [String: Any])

    #expect(storageObject["kind"] as? String == "storage")
    #expect(storageObject["requiredBytes"] as? Int == 2 * 1_073_741_824)
    #expect(storageObject["availableBytes"] == nil)
    #expect(storageObject["usage"] as? String == "important")
    #expect(try JSONDecoder().decode(HeadroomAvailabilityFailure.self, from: storageData) == storageFailure)
}

@Test
func snapshotsResourcesFeaturesAndAvailabilityAreCodable() throws {
    let snapshot = HeadroomSnapshot(
        hardwareScore: 84,
        effectiveScore: 76,
        signals: HeadroomSignals(
            deviceDescription: "Test Device",
            deviceOverrideKey: "iPhone16,1",
            machineIdentifier: "iPhone16,1",
            isSimulator: false,
            physicalMemoryBytes: 8 * 1_073_741_824,
            deviceKitScore: 84,
            availableMemoryBytes: 2 * 1_073_741_824,
            memoryPressure: .nominal,
            lowPowerModeEnabled: true,
            thermalState: .fair,
            metalAppleGPUFamily: 9
        )
    )

    let resources = HeadroomResources(
        memory: HeadroomMemoryInfo(
            physicalBytes: 8 * 1_073_741_824,
            availableBytes: 2 * 1_073_741_824
        ),
        storage: HeadroomStorageInfo(
            totalCapacityBytes: 128 * 1_073_741_824,
            availableCapacityBytes: 64 * 1_073_741_824,
            importantAvailableCapacityBytes: 60 * 1_073_741_824,
            opportunisticAvailableCapacityBytes: 40 * 1_073_741_824
        ),
        thermalState: .fair,
        memoryPressure: .nominal
    )

    let feature = HeadroomFeature(
        requiredScore: 84,
        minimumAvailableMemoryBytes: 512 * 1_048_576,
        minimumAvailableStorageBytes: 2 * 1_073_741_824,
        allowsLowPowerMode: false,
        maximumThermalState: .fair
    )

    let availability = HeadroomFeatureAvailability(failures: [
        .score(required: 84, current: 76, source: .effective),
        .lowPowerMode,
    ])

    var configuration = HeadroomConfiguration(forcedHardwareScore: 84, forcedEffectiveScore: 76)
    configuration.lowPowerModePenalty = 12
    configuration.overrideMetalAppleGPUFamily(9, as: 88)

    try expectJSONRoundTrip(snapshot)
    try expectJSONRoundTrip(resources)
    try expectJSONRoundTrip(feature)
    try expectJSONRoundTrip(availability)
    try expectJSONRoundTrip(configuration)
    try expectJSONRoundTrip(configuration.policy)
    try expectJSONRoundTrip(HeadroomAvailabilityFailureKind.score)
}

@Test
func featureCodableDerivesRequiredTierFromScore() throws {
    let json = """
    {
      "requiredScore": 84,
      "requiredTier": "low",
      "tierSource": "effective",
      "storageUsage": "important",
      "allowsLowPowerMode": true
    }
    """

    let feature = try JSONDecoder().decode(HeadroomFeature.self, from: Data(json.utf8))

    #expect(feature.requiredScore == 84)
    #expect(feature.requiredTier == .ultra)
}

@Test
func featureCodableUsesInitializerDefaultsAndNormalizesNonPositiveResources() throws {
    let initialized = HeadroomFeature(
        requiredScore: 40,
        minimumAvailableMemoryBytes: 0,
        minimumAvailableStorageBytes: -1
    )

    #expect(initialized.minimumAvailableMemoryBytes == nil)
    #expect(initialized.minimumAvailableStorageBytes == nil)

    let json = """
    {
      "requiredScore": 40,
      "minimumAvailableMemoryBytes": 0,
      "minimumAvailableStorageBytes": -5
    }
    """

    let decoded = try JSONDecoder().decode(HeadroomFeature.self, from: Data(json.utf8))

    #expect(decoded.requiredScore == 40)
    #expect(decoded.tierSource == .effective)
    #expect(decoded.minimumAvailableMemoryBytes == nil)
    #expect(decoded.minimumAvailableStorageBytes == nil)
    #expect(decoded.storageUsage == .important)
    #expect(decoded.allowsLowPowerMode)

    #expect(Headroom.isAvailable(
        decoded,
        snapshot: usabilitySnapshot(hardwareScore: 80, effectiveScore: 80),
        resources: usabilityResources()
    ))
}

@Test
func featureAvailabilityCanEvaluateSuppliedDiagnostics() {
    let feature = HeadroomFeature(
        requiredScore: 70,
        minimumAvailableMemoryBytes: 512 * 1_048_576
    )

    let result = Headroom.availability(
        of: feature,
        snapshot: usabilitySnapshot(hardwareScore: 90, effectiveScore: 60),
        resources: usabilityResources(availableMemoryBytes: 256 * 1_048_576)
    )

    #expect(!result.isAvailable)
    let expectedFailures: [HeadroomAvailabilityFailure] = [
        .score(required: HeadroomScore(70), current: HeadroomScore(60), source: .effective),
        .memory(requiredBytes: UInt64(512 * 1_048_576), availableBytes: UInt64(256 * 1_048_576)),
    ]
    #expect(result.failures == expectedFailures)

    let hardwareOnlyFeature = HeadroomFeature(requiredScore: 70, tierSource: .hardware)
    #expect(Headroom.isAvailable(
        hardwareOnlyFeature,
        snapshot: usabilitySnapshot(hardwareScore: 90, effectiveScore: 60),
        resources: usabilityResources()
    ))
}

@Test
func diagnosticReportBundlesFeatureSnapshotResourcesAndAvailability() throws {
    let feature = HeadroomFeature(
        requiredScore: 70,
        resources: .init(memory: .mebibytes(512), storage: .gibibytes(2)),
        allowsLowPowerMode: false
    )
    let snapshot = usabilitySnapshot(
        hardwareScore: 90,
        effectiveScore: 60,
        lowPowerModeEnabled: true
    )
    let resources = usabilityResources(
        availableMemoryBytes: 256 * 1_048_576,
        availableStorageBytes: 1 * 1_073_741_824
    )

    let report = Headroom.diagnosticReport(
        of: feature,
        snapshot: snapshot,
        resources: resources
    )

    #expect(report.schemaVersion == HeadroomFeatureDiagnosticReport.currentSchemaVersion)
    #expect(report.isCurrentSchemaVersion)
    #expect(report.feature == feature)
    #expect(report.snapshot == snapshot)
    #expect(report.resources == resources)
    #expect(!report.isAvailable)
    #expect(report.failureCodes == ["score", "lowPowerMode", "memory", "storage"])
    #expect(report.failureKinds == [.score, .lowPowerMode, .memory, .storage])
    #expect(report.recoverySuggestions.count == 4)
    #expect(report.replayedAvailability == report.availability)
    #expect(report.isReplayConsistent)
    #expect(report.diagnosticSummary == report.availability.diagnosticSummary)
    #expect(String(describing: report) == report.diagnosticSummary)

    try expectJSONRoundTrip(report)

    let encoded = try JSONEncoder().encode(report)
    let encodedObject = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    #expect(encodedObject["schemaVersion"] as? Int == HeadroomFeatureDiagnosticReport.currentSchemaVersion)
}

@Test
func diagnosticReportCanDetectInconsistentDecodedArtifacts() {
    let feature = HeadroomFeature(requiredScore: 90)
    let snapshot = usabilitySnapshot(hardwareScore: 80, effectiveScore: 70)
    let resources = usabilityResources()
    let inconsistentReport = HeadroomFeatureDiagnosticReport(
        feature: feature,
        snapshot: snapshot,
        resources: resources,
        availability: HeadroomFeatureAvailability(failures: [])
    )

    #expect(inconsistentReport.isAvailable)
    #expect(!inconsistentReport.replayedAvailability.isAvailable)
    #expect(inconsistentReport.replayedAvailability.failureCodes == ["score"])
    #expect(!inconsistentReport.isReplayConsistent)
}

@Test
func diagnosticReportDecodesLegacyArtifactsWithoutSchemaVersion() throws {
    let feature = HeadroomFeature(requiredScore: 70)
    let snapshot = usabilitySnapshot(hardwareScore: 90, effectiveScore: 90)
    let resources = usabilityResources()
    let currentReport = HeadroomFeatureDiagnosticReport(
        feature: feature,
        snapshot: snapshot,
        resources: resources
    )
    let data = try JSONEncoder().encode(currentReport)
    var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    object.removeValue(forKey: "schemaVersion")

    let legacyData = try JSONSerialization.data(withJSONObject: object)
    let decoded = try JSONDecoder().decode(HeadroomFeatureDiagnosticReport.self, from: legacyData)

    #expect(decoded.schemaVersion == 0)
    #expect(!decoded.isCurrentSchemaVersion)
    #expect(decoded.feature == currentReport.feature)
    #expect(decoded.snapshot == currentReport.snapshot)
    #expect(decoded.resources == currentReport.resources)
    #expect(decoded.availability == currentReport.availability)
    #expect(decoded.isReplayConsistent)
}

private func expectJSONRoundTrip<T>(_ value: T) throws where T: Codable & Equatable {
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(T.self, from: data)
    #expect(decoded == value)
}

private func usabilitySnapshot(
    hardwareScore: HeadroomScore,
    effectiveScore: HeadroomScore,
    lowPowerModeEnabled: Bool = false,
    thermalState: HeadroomThermalState = .nominal
) -> HeadroomSnapshot {
    HeadroomSnapshot(
        hardwareScore: hardwareScore,
        effectiveScore: effectiveScore,
        signals: HeadroomSignals(
            deviceDescription: "Test Device",
            deviceOverrideKey: "Test Device",
            machineIdentifier: "iPhone16,1",
            isSimulator: false,
            physicalMemoryBytes: 8 * 1_073_741_824,
            deviceKitScore: hardwareScore,
            availableMemoryBytes: 2 * 1_073_741_824,
            memoryPressure: .nominal,
            lowPowerModeEnabled: lowPowerModeEnabled,
            thermalState: thermalState,
            metalAppleGPUFamily: 9
        )
    )
}

private func usabilityResources(
    availableMemoryBytes: UInt64? = nil,
    availableStorageBytes: Int64? = nil
) -> HeadroomResources {
    HeadroomResources(
        memory: HeadroomMemoryInfo(
            physicalBytes: 8 * 1_073_741_824,
            availableBytes: availableMemoryBytes
        ),
        storage: HeadroomStorageInfo(
            totalCapacityBytes: availableStorageBytes.map { $0 * 2 },
            availableCapacityBytes: availableStorageBytes,
            importantAvailableCapacityBytes: availableStorageBytes,
            opportunisticAvailableCapacityBytes: availableStorageBytes
        ),
        thermalState: .nominal,
        memoryPressure: .nominal
    )
}
