import Foundation
#if canImport(Darwin)
import Darwin
#endif

enum MachineIdentifier {
    static func current() -> String? {
        #if canImport(Darwin)
        #if targetEnvironment(simulator)
        if let simulatedIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"],
           !simulatedIdentifier.isEmpty {
            return simulatedIdentifier
        }
        #endif

        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)

        guard size > 0 else { return nil }

        var machine = [CChar](repeating: 0, count: size)
        let result = sysctlbyname("hw.machine", &machine, &size, nil, 0)

        guard result == 0 else { return nil }

        return String(cString: machine)
        #else
        return nil
        #endif
    }
}
