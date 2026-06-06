import Foundation

/// Reproducible diagnostic bundle for a feature availability decision.
public struct HeadroomFeatureDiagnosticReport: Codable, Equatable, Sendable {
    /// Current diagnostic report schema version encoded by Headroom.
    public static let currentSchemaVersion = 1

    /// Diagnostic report schema version.
    ///
    /// Reports decoded from older Headroom versions that did not encode this field use `0`.
    public let schemaVersion: Int

    /// Feature gate that was evaluated.
    public let feature: HeadroomFeature

    /// Snapshot used for score and pressure decisions.
    public let snapshot: HeadroomSnapshot

    /// Resource readings used for memory, storage, and thermal checks.
    public let resources: HeadroomResources

    /// Detailed availability result for `feature`, `snapshot`, and `resources`.
    public let availability: HeadroomFeatureAvailability

    /// Availability recomputed from `feature`, `snapshot`, and `resources`.
    ///
    /// Use this to validate a decoded support artifact or to detect diagnostics that were
    /// edited, truncated, or produced by an incompatible version.
    public var replayedAvailability: HeadroomFeatureAvailability {
        HeadroomFeatureEvaluator.availability(
            of: feature,
            snapshot: snapshot,
            resources: resources
        )
    }

    /// Whether `availability` matches a fresh replay from `feature`, `snapshot`, and `resources`.
    public var isReplayConsistent: Bool {
        availability == replayedAvailability
    }

    /// Whether this report was encoded with the current diagnostic report schema version.
    public var isCurrentSchemaVersion: Bool {
        schemaVersion == Self.currentSchemaVersion
    }

    /// Whether the feature was available.
    public var isAvailable: Bool {
        availability.isAvailable
    }

    /// Stable failure codes in evaluation order.
    public var failureCodes: [String] {
        availability.failureCodes
    }

    /// Stable failure kinds in evaluation order.
    public var failureKinds: [HeadroomAvailabilityFailureKind] {
        availability.failureKinds
    }

    /// Human-readable remediation hints in evaluation order.
    public var recoverySuggestions: [String] {
        availability.recoverySuggestions
    }

    /// Compact one-line diagnostic summary.
    public var diagnosticSummary: String {
        availability.diagnosticSummary
    }

    /// Creates a report and evaluates availability from the supplied diagnostics.
    public init(
        feature: HeadroomFeature,
        snapshot: HeadroomSnapshot,
        resources: HeadroomResources
    ) {
        self.init(
            feature: feature,
            snapshot: snapshot,
            resources: resources,
            availability: HeadroomFeatureEvaluator.availability(
                of: feature,
                snapshot: snapshot,
                resources: resources
            )
        )
    }

    /// Creates a report from an already-computed availability result.
    public init(
        feature: HeadroomFeature,
        snapshot: HeadroomSnapshot,
        resources: HeadroomResources,
        availability: HeadroomFeatureAvailability,
        schemaVersion: Int = HeadroomFeatureDiagnosticReport.currentSchemaVersion
    ) {
        self.schemaVersion = schemaVersion
        self.feature = feature
        self.snapshot = snapshot
        self.resources = resources
        self.availability = availability
    }
}

extension HeadroomFeatureDiagnosticReport {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case feature
        case snapshot
        case resources
        case availability
    }

    /// Decodes a diagnostic report, treating missing schema metadata as a legacy report.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(
            feature: container.decode(HeadroomFeature.self, forKey: .feature),
            snapshot: container.decode(HeadroomSnapshot.self, forKey: .snapshot),
            resources: container.decode(HeadroomResources.self, forKey: .resources),
            availability: container.decode(HeadroomFeatureAvailability.self, forKey: .availability),
            schemaVersion: container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 0
        )
    }

    /// Encodes a diagnostic report with explicit schema metadata for support tooling.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(feature, forKey: .feature)
        try container.encode(snapshot, forKey: .snapshot)
        try container.encode(resources, forKey: .resources)
        try container.encode(availability, forKey: .availability)
    }
}

extension HeadroomFeatureDiagnosticReport: CustomStringConvertible {
    /// Compact one-line diagnostic summary.
    public var description: String {
        diagnosticSummary
    }
}
