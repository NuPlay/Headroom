import Foundation

/// A normalized capability score used by Headroom.
///
/// Scores are intentionally heuristic: they are seeded from public Geekbench
/// trends, then adjusted by runtime pressure such as Low Power Mode, thermal
/// state, and memory pressure. Higher is better.
public struct HeadroomScore: RawRepresentable, Comparable, Codable, Hashable, Sendable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    private static let minimumRawValue = 0
    private static let maximumRawValue = 100

    public static let minimum = HeadroomScore(Self.minimumRawValue)
    public static let maximum = HeadroomScore(Self.maximumRawValue)

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = max(Self.minimumRawValue, min(Self.maximumRawValue, rawValue))
    }

    public init(_ rawValue: Int) {
        self.init(rawValue: rawValue)
    }

    public init(integerLiteral value: Int) {
        self.init(rawValue: value)
    }

    public static func < (lhs: HeadroomScore, rhs: HeadroomScore) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public func adjusted(by delta: Int) -> HeadroomScore {
        HeadroomScore(rawValue: rawValue + delta)
    }

    public func penalized(by penalty: Int) -> HeadroomScore {
        guard penalty > 0 else { return self }
        return adjusted(by: -penalty)
    }

    public var tier: HeadroomTier {
        HeadroomTier(score: self)
    }
}

public extension HeadroomScore {
    /// A compact display value such as `84`.
    var description: String {
        String(rawValue)
    }
}
