import Foundation

final class HeadroomConfigurationStore {
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
