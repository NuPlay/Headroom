import Foundation

/// Coarse performance tiers used for feature gating.
public enum HeadroomTier: Int, CaseIterable, Codable, Sendable {
    /// Conservative UI, fallback paths, or older hardware.
    case low = 0

    /// Default experience with lightweight effects.
    case medium = 1

    /// Richer animations, media, and moderately expensive realtime work.
    case high = 2

    /// Premium paths for recent high-end hardware.
    case ultra = 3
}

extension HeadroomTier: Comparable {
    /// Compares tiers by increasing capability.
    public static func < (lhs: HeadroomTier, rhs: HeadroomTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension HeadroomTier {
    /// Minimum score required for this tier.
    public var minimumScore: HeadroomScore {
        switch self {
        case .low:
            0
        case .medium:
            40
        case .high:
            70
        case .ultra:
            82
        }
    }

    /// Representative score used when a tier is the only available input.
    public var representativeScore: HeadroomScore {
        switch self {
        case .low:
            25
        case .medium:
            55
        case .high:
            74
        case .ultra:
            88
        }
    }

    /// Creates a tier from a normalized score.
    public init(score: HeadroomScore) {
        if score >= HeadroomTier.ultra.minimumScore {
            self = .ultra
        } else if score >= HeadroomTier.high.minimumScore {
            self = .high
        } else if score >= HeadroomTier.medium.minimumScore {
            self = .medium
        } else {
            self = .low
        }
    }

    /// Returns a tier downgraded by `steps`, clamped at `.low`.
    public func downgraded(by steps: Int = 1) -> HeadroomTier {
        guard steps > 0 else { return self }
        return HeadroomTier(rawValue: max(Self.low.rawValue, rawValue - steps)) ?? .low
    }

    /// Returns a tier upgraded by `steps`, clamped at `.ultra`.
    public func upgraded(by steps: Int = 1) -> HeadroomTier {
        guard steps > 0 else { return self }
        return HeadroomTier(rawValue: min(Self.ultra.rawValue, rawValue + steps)) ?? .ultra
    }
}
