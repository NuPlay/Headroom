import Foundation

/// Snapshot-style disk capacity information for the app's home volume.
public struct HeadroomStorageInfo: Equatable, Sendable {
    public let totalCapacityBytes: Int64?
    public let availableCapacityBytes: Int64?
    public let importantAvailableCapacityBytes: Int64?
    public let opportunisticAvailableCapacityBytes: Int64?

    public init(
        totalCapacityBytes: Int64? = nil,
        availableCapacityBytes: Int64? = nil,
        importantAvailableCapacityBytes: Int64? = nil,
        opportunisticAvailableCapacityBytes: Int64? = nil
    ) {
        self.totalCapacityBytes = totalCapacityBytes
        self.availableCapacityBytes = availableCapacityBytes
        self.importantAvailableCapacityBytes = importantAvailableCapacityBytes
        self.opportunisticAvailableCapacityBytes = opportunisticAvailableCapacityBytes
    }

    public var usedCapacityBytes: Int64? {
        guard let totalCapacityBytes, let availableCapacityBytes else { return nil }
        return max(0, totalCapacityBytes - availableCapacityBytes)
    }

    public var availableRatio: Double? {
        guard let totalCapacityBytes, let availableCapacityBytes, totalCapacityBytes > 0 else { return nil }
        return Double(availableCapacityBytes) / Double(totalCapacityBytes)
    }

    public func availableBytes(for usage: HeadroomStorageUsage = .important) -> Int64? {
        switch usage {
        case .regular:
            return availableCapacityBytes
        case .important:
            return importantAvailableCapacityBytes ?? availableCapacityBytes
        case .opportunistic:
            return opportunisticAvailableCapacityBytes ?? availableCapacityBytes
        }
    }

    public func canFit(bytes: Int64, usage: HeadroomStorageUsage = .important) -> Bool {
        guard bytes >= 0, let available = availableBytes(for: usage) else { return false }
        return available >= bytes
    }
}

public enum HeadroomStorageUsage: String, Codable, Sendable {
    /// General free-space reading.
    case regular
    /// Space for something the user explicitly asked for or the app really needs.
    case important
    /// Space for nice-to-have caches, prefetching, or optional downloads.
    case opportunistic
}
