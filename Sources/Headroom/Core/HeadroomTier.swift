import Foundation

/// Coarse performance tiers used for feature gating.
public enum HeadroomTier: Int, CaseIterable, Codable, Sendable {
    case low = 0
    case medium = 1
    case high = 2
    case ultra = 3
}

extension HeadroomTier: Comparable {
    public static func < (lhs: HeadroomTier, rhs: HeadroomTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public extension HeadroomTier {
    /// Minimum score required for this tier.
    var minimumScore: HeadroomScore {
        switch self {
        case .low:
            return 0
        case .medium:
            return 40
        case .high:
            return 70
        case .ultra:
            return 82
        }
    }

    /// Representative score used when a tier is the only available input.
    var representativeScore: HeadroomScore {
        switch self {
        case .low:
            return 25
        case .medium:
            return 55
        case .high:
            return 74
        case .ultra:
            return 88
        }
    }

    init(score: HeadroomScore) {
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
    func downgraded(by steps: Int = 1) -> HeadroomTier {
        guard steps > 0 else { return self }
        return HeadroomTier(rawValue: max(Self.low.rawValue, rawValue - steps)) ?? .low
    }

    /// Returns a tier upgraded by `steps`, clamped at `.ultra`.
    func upgraded(by steps: Int = 1) -> HeadroomTier {
        guard steps > 0 else { return self }
        return HeadroomTier(rawValue: min(Self.ultra.rawValue, rawValue + steps)) ?? .ultra
    }
}
