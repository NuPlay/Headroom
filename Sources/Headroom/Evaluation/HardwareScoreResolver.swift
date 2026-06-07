import DeviceKit
import Foundation

enum HardwareScoreResolver {
    static func resolve(signals: HeadroomSignals, policy: HeadroomPolicy = .default) -> HeadroomScore {
        if let overrideKey = signals.deviceOverrideKey,
           let override = policy.deviceOverrides[overrideKey]
        {
            return override
        }

        if let identifier = signals.machineIdentifier,
           let override = policy.deviceOverrides[identifier]
        {
            return override
        }

        var candidates: [HeadroomScore] = []

        if let deviceKitScore = signals.deviceKitScore {
            candidates.append(deviceKitScore)
        } else if let deviceKitTier = signals.deviceKitTier {
            candidates.append(deviceKitTier.representativeScore)
        }

        if let identifier = signals.machineIdentifier,
           let score = scoreForMachineIdentifier(identifier)
        {
            candidates.append(score)
        }

        if let family = signals.metalAppleGPUFamily {
            candidates.append(scoreForMetalAppleGPUFamily(family, policy: policy))
        }

        if let bestKnownScore = candidates.max() {
            return bestKnownScore
        }

        return scoreForMemory(signals.physicalMemoryBytes, thresholds: policy.memoryScoreThresholds)
    }

    static func scoreForMachineIdentifier(_ identifier: String) -> HeadroomScore? {
        let normalized = identifier.trimmingCharacters(in: .whitespacesAndNewlines)

        #if os(iOS)
            // Prefer the typed identifier map for known iOS hardware.
            // The parser below is only a conservative fallback for unknown identifiers.
            if let mappedScore = scoreForMappedIdentifier(normalized) {
                return mappedScore
            }
        #endif

        let prefix = normalized.prefix { !$0.isNumber }
        let numbers = normalized.dropFirst(prefix.count).split(separator: ",")

        guard let major = numbers.first.flatMap({ Int($0) }) else {
            return nil
        }

        let minor = numbers.dropFirst().first.flatMap { Int($0) }

        switch prefix {
        case "iPhone":
            return scoreForIPhone(major: major, minor: minor)
        case "iPad":
            return scoreForIPadMajor(major)
        case "iPod":
            return scoreForIPodMajor(major)
        default:
            return nil
        }
    }

    #if os(iOS)
        private static func scoreForMappedIdentifier(_ identifier: String) -> HeadroomScore? {
            let device = Device.mapToDevice(identifier: identifier)

            switch device {
            case .unknown(_):
                return nil
            default:
                return device.headroomScore
            }
        }
    #endif

    static func scoreForMetalAppleGPUFamily(_ family: Int, policy: HeadroomPolicy = .default) -> HeadroomScore {
        if let override = policy.metalFamilyOverrides[family] {
            return override
        }

        switch family {
        case 10...:
            return 92
        case 9:
            return 84
        case 7 ... 8:
            return 74
        case 5 ... 6:
            return 60
        default:
            return 35
        }
    }

    static func scoreForMemory(
        _ bytes: UInt64,
        thresholds: HeadroomMemoryScoreThresholds = .default
    ) -> HeadroomScore {
        if bytes >= thresholds.ultraBytes {
            return thresholds.ultraScore
        }

        if bytes >= thresholds.highBytes {
            return thresholds.highScore
        }

        if bytes >= thresholds.mediumBytes {
            return thresholds.mediumScore
        }

        return thresholds.lowScore
    }

    static func scoreForCPU(_ cpu: Device.CPU) -> HeadroomScore {
        #if os(iOS) || os(tvOS)
            switch cpu {
            case .a19Pro:
                return 98
            case .a19:
                return 95
            case .a18Pro:
                return 92
            case .a18:
                return 90
            case .a17Pro:
                return 84
            case .a16Bionic:
                return 79
            case .a15Bionic:
                return 72
            case .a14Bionic:
                return 66
            case .a13Bionic:
                return 60
            case .a12XBionic, .a12ZBionic:
                return 64
            case .a12Bionic:
                return 50
            case .a11Bionic:
                return 40
            case .a10XFusion:
                return 38
            case .a10Fusion:
                return 32
            case .a9X:
                return 30
            case .a9:
                return 28
            case .m5:
                return 100
            case .m4:
                return 96
            case .m3:
                return 94
            case .m2:
                return 90
            case .m1:
                return 86
            default:
                return 25
            }
        #else
            return 25
        #endif
    }

    private static func scoreForIPhone(major: Int, minor: Int?) -> HeadroomScore {
        if major >= 18 { return 96 }
        if major == 17 { return (minor == 1 || minor == 2) ? 92 : 90 }
        if major == 16 { return (minor == 1 || minor == 2) ? 84 : 79 }
        if major == 15 { return 79 }
        if major == 14 { return (minor == 4 || minor == 5) ? 71 : 74 }
        if major == 13 { return 66 }
        if major == 12 { return 60 }
        if major == 11 { return 50 }
        if major == 10 { return 39 }
        return 25
    }

    private static func scoreForIPadMajor(_ major: Int) -> HeadroomScore {
        // Conservative because iPad identifiers are less linear across Air, mini, base, and Pro lines.
        switch major {
        case 16...:
            92
        case 14 ... 15:
            84
        case 11 ... 13:
            72
        case 7 ... 10:
            55
        default:
            35
        }
    }

    private static func scoreForIPodMajor(_ major: Int) -> HeadroomScore {
        switch major {
        case 9...:
            40
        default:
            25
        }
    }
}
