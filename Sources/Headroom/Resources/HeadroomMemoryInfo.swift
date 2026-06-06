import Foundation

/// Snapshot-style memory information.
public struct HeadroomMemoryInfo: Codable, Equatable, Sendable {
    /// Total physical memory, in bytes.
    public let physicalBytes: UInt64

    /// Estimated currently available memory, in bytes.
    public let availableBytes: UInt64?

    /// Estimated currently used memory, in bytes.
    public let usedBytes: UInt64?

    /// Free pages plus speculative pages, in bytes when available.
    public let freeBytes: UInt64?

    /// Active memory, in bytes when available.
    public let activeBytes: UInt64?

    /// Inactive memory, in bytes when available.
    public let inactiveBytes: UInt64?

    /// Wired memory, in bytes when available.
    public let wiredBytes: UInt64?

    /// Compressed memory, in bytes when available.
    public let compressedBytes: UInt64?

    /// Virtual-memory page size, in bytes when available.
    public let pageSizeBytes: UInt64?

    /// Creates a memory snapshot.
    public init(
        physicalBytes: UInt64,
        availableBytes: UInt64? = nil,
        usedBytes: UInt64? = nil,
        freeBytes: UInt64? = nil,
        activeBytes: UInt64? = nil,
        inactiveBytes: UInt64? = nil,
        wiredBytes: UInt64? = nil,
        compressedBytes: UInt64? = nil,
        pageSizeBytes: UInt64? = nil
    ) {
        self.physicalBytes = physicalBytes
        self.availableBytes = availableBytes
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.activeBytes = activeBytes
        self.inactiveBytes = inactiveBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.pageSizeBytes = pageSizeBytes
    }

    /// Available memory divided by physical memory.
    public var availableRatio: Double? {
        guard let availableBytes, physicalBytes > 0 else { return nil }
        return Double(availableBytes) / Double(physicalBytes)
    }

    /// Used memory divided by physical memory.
    public var usedRatio: Double? {
        guard let usedBytes, physicalBytes > 0 else { return nil }
        return Double(usedBytes) / Double(physicalBytes)
    }

    /// A lightweight heuristic based on currently reclaimable memory and default thresholds.
    public var pressure: HeadroomMemoryPressure {
        pressure(using: .default)
    }

    /// Classifies memory pressure with a custom policy.
    public func pressure(using policy: HeadroomMemoryPressurePolicy) -> HeadroomMemoryPressure {
        policy.pressure(availableBytes: availableBytes, physicalBytes: physicalBytes)
    }
}

/// Coarse available-memory pressure used by adaptive scoring and feature gates.
public enum HeadroomMemoryPressure: String, Codable, Sendable {
    /// Enough available memory for normal operation.
    case nominal

    /// Memory is low enough that expensive work should be conservative.
    case constrained

    /// Memory is critically low; expensive work should usually fall back.
    case critical

    /// Available memory could not be measured.
    case unknown
}
