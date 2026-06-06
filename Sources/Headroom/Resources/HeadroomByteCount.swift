import Foundation

/// Type-safe byte count for feature requirements, storage checks, and diagnostics.
public struct HeadroomByteCount: RawRepresentable, Codable, Comparable, Hashable, Sendable, ExpressibleByIntegerLiteral, CustomStringConvertible {
    /// Raw byte count.
    public let rawValue: UInt64

    /// Zero bytes.
    public static let zero = HeadroomByteCount(bytes: 0)

    /// Byte count as an unsigned integer.
    public var bytes: UInt64 {
        rawValue
    }

    /// Byte count clamped to `Int64.max` for Foundation storage-capacity APIs.
    public var storageBytes: Int64 {
        rawValue > UInt64(Int64.max) ? Int64.max : Int64(rawValue)
    }

    /// Creates a byte count from raw bytes.
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    /// Creates a byte count from raw bytes.
    public init(bytes: UInt64) {
        self.init(rawValue: bytes)
    }

    /// Creates a byte count from an integer literal.
    public init(integerLiteral value: UInt64) {
        self.init(bytes: value)
    }

    /// Compares byte counts by raw byte value.
    public static func < (lhs: HeadroomByteCount, rhs: HeadroomByteCount) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Creates a byte count from raw bytes.
    public static func bytes(_ value: UInt64) -> HeadroomByteCount {
        HeadroomByteCount(bytes: value)
    }

    /// Creates a byte count from kibibytes (`value * 1024`).
    public static func kibibytes(_ value: UInt64) -> HeadroomByteCount {
        multiplying(value, by: 1024)
    }

    /// Creates a byte count from mebibytes (`value * 1024^2`).
    public static func mebibytes(_ value: UInt64) -> HeadroomByteCount {
        multiplying(value, by: 1_048_576)
    }

    /// Creates a byte count from gibibytes (`value * 1024^3`).
    public static func gibibytes(_ value: UInt64) -> HeadroomByteCount {
        multiplying(value, by: 1_073_741_824)
    }

    /// Creates a byte count from tebibytes (`value * 1024^4`).
    public static func tebibytes(_ value: UInt64) -> HeadroomByteCount {
        multiplying(value, by: 1_099_511_627_776)
    }

    /// Creates a byte count from decimal kilobytes (`value * 1000`).
    public static func kilobytes(_ value: UInt64) -> HeadroomByteCount {
        multiplying(value, by: 1000)
    }

    /// Creates a byte count from decimal megabytes (`value * 1000^2`).
    public static func megabytes(_ value: UInt64) -> HeadroomByteCount {
        multiplying(value, by: 1_000_000)
    }

    /// Creates a byte count from decimal gigabytes (`value * 1000^3`).
    public static func gigabytes(_ value: UInt64) -> HeadroomByteCount {
        multiplying(value, by: 1_000_000_000)
    }

    /// Creates a byte count from decimal terabytes (`value * 1000^4`).
    public static func terabytes(_ value: UInt64) -> HeadroomByteCount {
        multiplying(value, by: 1_000_000_000_000)
    }

    /// Human-readable binary display value such as `512 MiB`.
    public var description: String {
        let units = ["bytes", "KiB", "MiB", "GiB", "TiB"]
        var value = Double(rawValue)
        var unitIndex = 0

        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(Int(value)) \(units[unitIndex])"
        }

        if value.rounded() == value {
            return "\(Int(value)) \(units[unitIndex])"
        }

        return "\(String(format: "%.1f", value)) \(units[unitIndex])"
    }

    private static func multiplying(_ value: UInt64, by multiplier: UInt64) -> HeadroomByteCount {
        let result = value.multipliedReportingOverflow(by: multiplier)
        return HeadroomByteCount(bytes: result.overflow ? UInt64.max : result.partialValue)
    }
}
