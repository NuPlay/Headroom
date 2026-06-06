import Foundation

/// Resource requirements that can be attached to a feature gate.
public struct HeadroomFeatureResourceRequirements: Codable, Equatable, Sendable {
    /// Empty resource requirements.
    public static let none = HeadroomFeatureResourceRequirements()

    /// Optional minimum currently available memory, in bytes.
    public let minimumAvailableMemoryBytes: UInt64?

    /// Optional minimum currently available storage, in bytes.
    public let minimumAvailableStorageBytes: Int64?

    /// Which storage-capacity reading to use for `minimumAvailableStorageBytes`.
    public let storageUsage: HeadroomStorageUsage

    /// Whether no memory or storage requirement is set.
    public var isEmpty: Bool {
        minimumAvailableMemoryBytes == nil && minimumAvailableStorageBytes == nil
    }

    /// Creates resource requirements from typed byte counts.
    public init(
        memory: HeadroomByteCount? = nil,
        storage: HeadroomByteCount? = nil,
        storageUsage: HeadroomStorageUsage = .important
    ) {
        minimumAvailableMemoryBytes = memory.flatMap(Self.normalizedMemoryBytes)
        minimumAvailableStorageBytes = storage.flatMap(Self.normalizedStorageBytes)
        self.storageUsage = storageUsage
    }

    /// Creates resource requirements from raw byte counts.
    public init(
        minimumAvailableMemoryBytes: UInt64?,
        minimumAvailableStorageBytes: Int64?,
        storageUsage: HeadroomStorageUsage = .important
    ) {
        self.minimumAvailableMemoryBytes = Self.normalizedMemoryBytes(minimumAvailableMemoryBytes)
        self.minimumAvailableStorageBytes = Self.normalizedStorageBytes(minimumAvailableStorageBytes)
        self.storageUsage = storageUsage
    }

    /// Creates memory-only requirements.
    public static func memory(_ byteCount: HeadroomByteCount) -> HeadroomFeatureResourceRequirements {
        HeadroomFeatureResourceRequirements(memory: byteCount)
    }

    /// Creates storage-only requirements.
    public static func storage(
        _ byteCount: HeadroomByteCount,
        usage: HeadroomStorageUsage = .important
    ) -> HeadroomFeatureResourceRequirements {
        HeadroomFeatureResourceRequirements(storage: byteCount, storageUsage: usage)
    }

    private static func normalizedMemoryBytes(_ byteCount: HeadroomByteCount) -> UInt64? {
        normalizedMemoryBytes(byteCount.bytes)
    }

    private static func normalizedMemoryBytes(_ bytes: UInt64?) -> UInt64? {
        guard let bytes, bytes > 0 else { return nil }
        return bytes
    }

    private static func normalizedStorageBytes(_ byteCount: HeadroomByteCount) -> Int64? {
        normalizedStorageBytes(byteCount.storageBytes)
    }

    private static func normalizedStorageBytes(_ bytes: Int64?) -> Int64? {
        guard let bytes, bytes > 0 else { return nil }
        return bytes
    }
}
