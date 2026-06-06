import Foundation
@testable import Headroom

enum HeadroomTestSupport {
    private static let configurationLock = NSLock()

    static func withIsolatedConfiguration<T>(_ body: () throws -> T) rethrows -> T {
        configurationLock.lock()
        defer {
            Headroom.resetConfiguration()
            configurationLock.unlock()
        }

        Headroom.resetConfiguration()
        return try body()
    }
}
