import Foundation

/// Snapshot-style disk capacity information for the app's home volume.
public struct HeadroomStorageInfo: Codable, Equatable, Sendable {
    /// Volume total capacity, in bytes.
    public let totalCapacityBytes: Int64?

    /// General available capacity, in bytes.
    public let availableCapacityBytes: Int64?

    /// Capacity available for important user-visible work, in bytes.
    public let importantAvailableCapacityBytes: Int64?

    /// Capacity available for opportunistic caches or prefetching, in bytes.
    public let opportunisticAvailableCapacityBytes: Int64?

    /// Creates a storage snapshot.
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

    /// Total capacity minus general available capacity, clamped at zero.
    public var usedCapacityBytes: Int64? {
        guard let totalCapacityBytes, let availableCapacityBytes else { return nil }
        return max(0, totalCapacityBytes - availableCapacityBytes)
    }

    /// General available capacity divided by total capacity.
    public var availableRatio: Double? {
        guard let totalCapacityBytes, let availableCapacityBytes, totalCapacityBytes > 0 else { return nil }
        return Double(availableCapacityBytes) / Double(totalCapacityBytes)
    }

    /// Returns the best available-capacity value for the intended usage.
    public func availableBytes(for usage: HeadroomStorageUsage = .important) -> Int64? {
        switch usage {
        case .regular:
            availableCapacityBytes
        case .important:
            importantAvailableCapacityBytes ?? availableCapacityBytes
        case .opportunistic:
            opportunisticAvailableCapacityBytes ?? availableCapacityBytes
        }
    }

    /// Returns whether the requested byte count fits in the selected usage bucket.
    public func canFit(bytes: Int64, usage: HeadroomStorageUsage = .important) -> Bool {
        guard bytes >= 0 else { return false }
        guard bytes > 0 else { return true }
        guard let available = availableBytes(for: usage) else { return false }
        return available >= bytes
    }

    /// Returns whether the requested byte count fits in the selected usage bucket.
    public func canFit(_ byteCount: HeadroomByteCount, usage: HeadroomStorageUsage = .important) -> Bool {
        canFit(bytes: byteCount.storageBytes, usage: usage)
    }
}

/// Storage capacity bucket to use for a feature or download decision.
public enum HeadroomStorageUsage: String, Codable, Sendable {
    /// General free-space reading.
    case regular
    /// Space for something the user explicitly asked for or the app really needs.
    case important
    /// Space for nice-to-have caches, prefetching, or optional downloads.
    case opportunistic
}
