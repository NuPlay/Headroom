import Foundation

/// Snapshot-style memory information.
public struct HeadroomMemoryInfo: Equatable, Sendable {
    public let physicalBytes: UInt64
    public let availableBytes: UInt64?
    public let usedBytes: UInt64?
    public let freeBytes: UInt64?
    public let activeBytes: UInt64?
    public let inactiveBytes: UInt64?
    public let wiredBytes: UInt64?
    public let compressedBytes: UInt64?
    public let pageSizeBytes: UInt64?

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

    public var availableRatio: Double? {
        guard let availableBytes, physicalBytes > 0 else { return nil }
        return Double(availableBytes) / Double(physicalBytes)
    }

    public var usedRatio: Double? {
        guard let usedBytes, physicalBytes > 0 else { return nil }
        return Double(usedBytes) / Double(physicalBytes)
    }

    /// A lightweight heuristic based on currently reclaimable memory and default thresholds.
    public var pressure: HeadroomMemoryPressure {
        pressure(using: .default)
    }

    public func pressure(using policy: HeadroomMemoryPressurePolicy) -> HeadroomMemoryPressure {
        policy.pressure(availableBytes: availableBytes, physicalBytes: physicalBytes)
    }
}

public enum HeadroomMemoryPressure: String, Codable, Sendable {
    case nominal
    case constrained
    case critical
    case unknown
}
