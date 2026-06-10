import Foundation

/// `@unchecked Sendable`: all access to `storedConfiguration` is serialized through `lock`.
final class HeadroomConfigurationStore: @unchecked Sendable {
    static let shared = HeadroomConfigurationStore()

    private let lock = NSRecursiveLock()
    private var storedConfiguration = HeadroomConfiguration()

    var configuration: HeadroomConfiguration {
        lock.withLock { storedConfiguration }
    }

    func configure(_ update: (inout HeadroomConfiguration) -> Void) {
        lock.withLock {
            var updatedConfiguration = storedConfiguration
            update(&updatedConfiguration)
            storedConfiguration = updatedConfiguration
        }
    }

    func reset() {
        lock.withLock {
            storedConfiguration = HeadroomConfiguration()
        }
    }
}

extension NSRecursiveLock {
    fileprivate func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
