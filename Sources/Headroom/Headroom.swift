import DeviceKit
import Foundation

/// Adaptive performance availability for iOS.
public enum Headroom {
    /// Alias for a more fluent API: `Headroom.Tier.high`.
    public typealias Tier = HeadroomTier

    /// Alias for score-oriented APIs.
    public typealias Score = HeadroomScore

    /// Current global configuration.
    public static var configuration: HeadroomConfiguration {
        HeadroomConfigurationStore.shared.configuration
    }

    /// Updates the global configuration used by Headroom.
    public static func configure(_ update: (inout HeadroomConfiguration) -> Void) {
        HeadroomConfigurationStore.shared.configure(update)
    }

    /// Restores the default configuration.
    public static func resetConfiguration() {
        HeadroomConfigurationStore.shared.reset()
    }

    /// Current device baseline score.
    public static var hardwareScore: HeadroomScore {
        snapshot.hardwareScore
    }

    /// Current effective score after runtime pressure modifiers.
    public static var effectiveScore: HeadroomScore {
        snapshot.effectiveScore
    }

    /// Current device baseline capability.
    public static var hardwareTier: HeadroomTier {
        snapshot.hardwareTier
    }

    /// Current effective capability after runtime pressure modifiers.
    public static var effectiveTier: HeadroomTier {
        snapshot.effectiveTier
    }

    /// Returns the current score for an availability mode.
    ///
    /// Use `.adaptive` for the default runtime-aware score and `.hardwareOnly`
    /// when a decision should ignore current Low Power Mode, thermal, and memory pressure.
    public static func score(for mode: HeadroomAvailabilityMode = .adaptive) -> HeadroomScore {
        let currentSnapshot = snapshot

        switch mode {
        case .adaptive:
            return currentSnapshot.effectiveScore
        case .hardwareOnly:
            return currentSnapshot.hardwareScore
        }
    }

    /// Returns the current tier for an availability mode.
    ///
    /// Use `.adaptive` for the default runtime-aware tier and `.hardwareOnly`
    /// when a decision should ignore current Low Power Mode, thermal, and memory pressure.
    public static func tier(for mode: HeadroomAvailabilityMode = .adaptive) -> HeadroomTier {
        score(for: mode).tier
    }

    /// Full diagnostic view of the current device and runtime signals.
    public static var snapshot: HeadroomSnapshot {
        evaluator().snapshot()
    }

    /// Current memory, storage, and thermal readings.
    public static var resources: HeadroomResources {
        HeadroomResourceReader.resources(memoryPressurePolicy: configuration.policy.memoryPressurePolicy)
    }

    /// Current memory reading.
    public static var memory: HeadroomMemoryInfo {
        HeadroomResourceReader.memory()
    }

    /// Current memory pressure using Headroom's configured memory pressure policy.
    public static var memoryPressure: HeadroomMemoryPressure {
        memory.pressure(using: configuration.policy.memoryPressurePolicy)
    }

    /// Current storage reading for the app's home volume.
    public static var storage: HeadroomStorageInfo {
        HeadroomResourceReader.storage()
    }

    /// Storage reading for a specific file URL's volume.
    public static func storage(at url: URL) -> HeadroomStorageInfo {
        HeadroomResourceReader.storage(url: url)
    }

    /// Current thermal state. iOS public API exposes state, not an exact device temperature.
    public static var thermalState: HeadroomThermalState {
        HeadroomResourceReader.thermalState()
    }

    /// Whether current thermal state should be treated as performance-constrained.
    public static var isThermallyConstrained: Bool {
        thermalState.isPerformanceConstrained
    }

    /// Returns whether the current score can run a feature that requires `score`.
    ///
    /// The default `.adaptive` mode uses `effectiveScore`. Use `.hardwareOnly`
    /// to compare against `hardwareScore` instead.
    public static func isAvailable(
        _ score: HeadroomScore,
        mode: HeadroomAvailabilityMode = .adaptive
    ) -> Bool {
        Self.score(for: mode) >= score
    }

    /// Returns whether the current score can run a feature that requires `tier`.
    ///
    /// The default `.adaptive` mode uses `effectiveScore`. Use `.hardwareOnly`
    /// to compare against `hardwareScore` instead.
    public static func isAvailable(
        _ tier: HeadroomTier,
        mode: HeadroomAvailabilityMode = .adaptive
    ) -> Bool {
        score(for: mode) >= tier.minimumScore
    }

    /// Returns whether the current device can run a feature that requires a DeviceKit reference device.
    ///
    /// The default `.adaptive` mode considers Low Power Mode, thermal state, and memory pressure.
    public static func isAvailable(
        _ device: Device,
        mode: HeadroomAvailabilityMode = .adaptive
    ) -> Bool {
        isAvailable(device.headroomScore, mode: mode)
    }

    /// Returns whether the current hardware score can run a feature that requires `score`, ignoring runtime pressure.
    public static func hardwareIsAvailable(_ score: HeadroomScore) -> Bool {
        hardwareScore >= score
    }

    /// Returns whether the current hardware tier can run a feature that requires `tier`, ignoring runtime pressure.
    public static func hardwareIsAvailable(_ tier: HeadroomTier) -> Bool {
        hardwareScore >= tier.minimumScore
    }

    /// Returns whether the current hardware score can run a feature that requires `device`, ignoring runtime pressure.
    public static func hardwareIsAvailable(_ device: Device) -> Bool {
        hardwareScore >= device.headroomScore
    }

    /// Returns whether a feature is available under the current snapshot and resources.
    public static func isAvailable(_ feature: HeadroomFeature) -> Bool {
        availability(of: feature).isAvailable
    }

    /// Returns whether a feature is available for supplied diagnostics.
    ///
    /// Use this overload in tests, previews, QA tools, or when replaying a previously logged
    /// `HeadroomSnapshot` and `HeadroomResources` pair.
    public static func isAvailable(
        _ feature: HeadroomFeature,
        snapshot: HeadroomSnapshot,
        resources: HeadroomResources
    ) -> Bool {
        availability(of: feature, snapshot: snapshot, resources: resources).isAvailable
    }

    /// Returns a detailed feature availability result with failure reasons.
    public static func availability(of feature: HeadroomFeature) -> HeadroomFeatureAvailability {
        availability(
            of: feature,
            snapshot: snapshot,
            resources: resources
        )
    }

    /// Returns a detailed feature availability result for supplied diagnostics.
    ///
    /// This is useful for deterministic tests, previews, and post-hoc analysis because it does
    /// not read live device state.
    public static func availability(
        of feature: HeadroomFeature,
        snapshot: HeadroomSnapshot,
        resources: HeadroomResources
    ) -> HeadroomFeatureAvailability {
        HeadroomFeatureEvaluator.availability(
            of: feature,
            snapshot: snapshot,
            resources: resources
        )
    }

    /// Returns a reproducible diagnostic report for a feature under current device state.
    public static func diagnosticReport(of feature: HeadroomFeature) -> HeadroomFeatureDiagnosticReport {
        diagnosticReport(
            of: feature,
            snapshot: snapshot,
            resources: resources
        )
    }

    /// Returns a reproducible diagnostic report for supplied diagnostics.
    ///
    /// The returned value is `Codable`, making it suitable for QA fixtures, logs, and support tickets.
    public static func diagnosticReport(
        of feature: HeadroomFeature,
        snapshot: HeadroomSnapshot,
        resources: HeadroomResources
    ) -> HeadroomFeatureDiagnosticReport {
        HeadroomFeatureDiagnosticReport(
            feature: feature,
            snapshot: snapshot,
            resources: resources
        )
    }

    private static func evaluator() -> HeadroomEvaluator {
        HeadroomEvaluator(configuration: configuration)
    }
}
