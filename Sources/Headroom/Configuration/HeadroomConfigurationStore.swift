import Foundation

final class HeadroomConfigurationStore {
    static let shared = HeadroomConfigurationStore()

    private let lock = NSLock()
    private var storedConfiguration = HeadroomConfiguration()

    var configuration: HeadroomConfiguration {
        lock.withLock { storedConfiguration }
    }

    func configure(_ update: (inout HeadroomConfiguration) -> Void) {
        lock.withLock {
            update(&storedConfiguration)
        }
    }

    func reset() {
        lock.withLock {
            storedConfiguration = HeadroomConfiguration()
        }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
