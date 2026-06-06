import Foundation

/// A normalized capability score used by Headroom.
///
/// Scores are intentionally heuristic: they are seeded from public Geekbench
/// trends, then adjusted by runtime pressure such as Low Power Mode, thermal
/// state, and memory pressure. Higher is better.
public struct HeadroomScore: RawRepresentable, Comparable, Codable, Hashable, Sendable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    private static let minimumRawValue = 0
    private static let maximumRawValue = 100

    /// Lowest possible Headroom score.
    public static let minimum = HeadroomScore(Self.minimumRawValue)

    /// Highest possible Headroom score.
    public static let maximum = HeadroomScore(Self.maximumRawValue)

    /// Clamped integer value in `0...100`.
    public let rawValue: Int

    /// Creates a score, clamping values into `0...100`.
    public init(rawValue: Int) {
        self.rawValue = max(Self.minimumRawValue, min(Self.maximumRawValue, rawValue))
    }

    /// Creates a score, clamping values into `0...100`.
    public init(_ rawValue: Int) {
        self.init(rawValue: rawValue)
    }

    /// Creates a score from an integer literal, clamping values into `0...100`.
    public init(integerLiteral value: Int) {
        self.init(rawValue: value)
    }

    /// Compares scores by raw value.
    public static func < (lhs: HeadroomScore, rhs: HeadroomScore) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Returns a score adjusted by `delta`, clamped into `0...100`.
    public func adjusted(by delta: Int) -> HeadroomScore {
        HeadroomScore(rawValue: rawValue + delta)
    }

    /// Returns a score reduced by a positive penalty, clamped at zero.
    public func penalized(by penalty: Int) -> HeadroomScore {
        guard penalty > 0 else { return self }
        return adjusted(by: -penalty)
    }

    /// Coarse tier containing this score.
    public var tier: HeadroomTier {
        HeadroomTier(score: self)
    }
}

extension HeadroomScore {
    /// A compact display value such as `84`.
    public var description: String {
        String(rawValue)
    }
}
