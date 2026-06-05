import Foundation
@_exported import DeviceKit

public extension Device {
    /// The coarse Headroom tier for this DeviceKit device.
    var headroomTier: HeadroomTier {
        #if os(iOS)
        switch self {
        case .simulator(let model):
            return model.headroomTier
        case .unknown(let identifier):
            return HardwareTierResolver.tierForMachineIdentifier(identifier) ?? .medium
        default:
            switch cpu {
            case .a17Pro, .a18, .a18Pro, .a19, .a19Pro, .m3, .m4, .m5:
                return .ultra
            case .a15Bionic, .a16Bionic, .m1, .m2:
                return .high
            case .a12Bionic, .a12XBionic, .a12ZBionic, .a13Bionic, .a14Bionic:
                return .medium
            default:
                return .low
            }
        }
        #else
        switch self {
        case .simulator(let model):
            return model.headroomTier
        case .unknown(let identifier):
            return HardwareTierResolver.tierForMachineIdentifier(identifier) ?? .medium
        }
        #endif
    }
}

extension Device {
    /// A stable key Headroom uses for device-level overrides.
    var headroomOverrideKey: String {
        #if os(iOS)
        switch self {
        case .simulator(let model):
            return model.headroomOverrideKey
        case .unknown(let identifier):
            return identifier
        default:
            return description
        }
        #else
        switch self {
        case .simulator(let model):
            return model.headroomOverrideKey
        case .unknown(let identifier):
            return identifier
        }
        #endif
    }
}
