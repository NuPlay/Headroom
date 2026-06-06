@_exported import DeviceKit
import Foundation

extension Device {
    /// Normalized Headroom score for this DeviceKit device.
    public var headroomScore: HeadroomScore {
        #if os(iOS)
            switch self {
            case let .simulator(model):
                return model.headroomScore
            case let .unknown(identifier):
                return HardwareScoreResolver.scoreForMachineIdentifier(identifier) ?? HeadroomTier.medium.representativeScore
            case .iPhone17Pro, .iPhone17ProMax:
                return 100
            case .iPhoneAir:
                return 96
            case .iPhone17, .iPhone17e:
                return 95
            case .iPhone16Pro, .iPhone16ProMax:
                return 92
            case .iPhone16, .iPhone16Plus, .iPhone16e:
                return 90
            case .iPhone15Pro, .iPhone15ProMax:
                return 84
            case .iPhone14Pro, .iPhone14ProMax, .iPhone15, .iPhone15Plus:
                return 79
            case .iPhone13Pro, .iPhone13ProMax, .iPhone14, .iPhone14Plus, .iPhoneSE3:
                return 74
            case .iPhone13, .iPhone13Mini:
                return 71
            case .iPhone12ProMax:
                return 68
            case .iPhone12Pro:
                return 67
            case .iPhone12, .iPhone12Mini:
                return 66
            case .iPhone11ProMax:
                return 62
            case .iPhone11Pro:
                return 61
            case .iPhone11:
                return 60
            case .iPhoneSE2:
                return 56
            case .iPhoneXS, .iPhoneXSMax, .iPhoneXR:
                return 50
            case .iPhone8Plus, .iPhoneX:
                return 39
            case .iPhone8:
                return 39
            default:
                return HardwareScoreResolver.scoreForCPU(cpu)
            }
        #else
            switch self {
            case let .simulator(model):
                return model.headroomScore
            case let .unknown(identifier):
                return HardwareScoreResolver.scoreForMachineIdentifier(identifier) ?? HeadroomTier.medium.representativeScore
            }
        #endif
    }

    /// The coarse Headroom tier for this DeviceKit device.
    public var headroomTier: HeadroomTier {
        headroomScore.tier
    }
}

extension Device {
    /// A stable key Headroom uses for device-level overrides.
    var headroomOverrideKey: String {
        #if os(iOS)
            switch self {
            case let .simulator(model):
                return model.headroomOverrideKey
            case let .unknown(identifier):
                return identifier
            default:
                return description
            }
        #else
            switch self {
            case let .simulator(model):
                return model.headroomOverrideKey
            case let .unknown(identifier):
                return identifier
            }
        #endif
    }
}
