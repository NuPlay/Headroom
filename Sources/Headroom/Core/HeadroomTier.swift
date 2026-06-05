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
