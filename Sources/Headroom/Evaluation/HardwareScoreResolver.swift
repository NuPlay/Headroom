import Foundation
import DeviceKit

enum HardwareScoreResolver {
    static func resolve(signals: HeadroomSignals, policy: HeadroomPolicy = .default) -> HeadroomScore {
        if let overrideKey = signals.deviceOverrideKey,
           let override = policy.deviceOverrides[overrideKey] {
            return override
        }

        if let identifier = signals.machineIdentifier,
           let override = policy.deviceOverrides[identifier] {
            return override
        }

        var candidates: [HeadroomScore] = []

        if let deviceKitScore = signals.deviceKitScore {
            candidates.append(deviceKitScore)
        } else if let deviceKitTier = signals.deviceKitTier {
            candidates.append(deviceKitTier.representativeScore)
        }

        if let identifier = signals.machineIdentifier,
           let score = scoreForMachineIdentifier(identifier) {
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

        switch normalized {
        case "iPhone18,1", "iPhone18,2":
            return 100
        case "iPhone18,4":
            return 96
        case "iPhone18,3", "iPhone18,5":
            return 95
        case "iPhone17,1", "iPhone17,2":
            return 92
        case "iPhone17,3", "iPhone17,4", "iPhone17,5":
            return 90
        case "iPhone16,1", "iPhone16,2":
            return 84
        case "iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5":
            return 79
        case "iPhone14,2", "iPhone14,3", "iPhone14,6", "iPhone14,7", "iPhone14,8":
            return 74
        case "iPhone14,4", "iPhone14,5":
            return 71
        case "iPhone13,4":
            return 68
        case "iPhone13,3":
            return 67
        case "iPhone13,1", "iPhone13,2":
            return 66
        case "iPhone12,5":
            return 62
        case "iPhone12,3":
            return 61
        case "iPhone12,1":
            return 60
        case "iPhone12,8":
            return 56
        case "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8":
            return 50
        case "iPhone10,2", "iPhone10,3", "iPhone10,5", "iPhone10,6":
            return 39
        case "iPhone10,1", "iPhone10,4":
            return 39
        default:
            break
        }

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

    static func scoreForMetalAppleGPUFamily(_ family: Int, policy: HeadroomPolicy = .default) -> HeadroomScore {
        if let override = policy.metalFamilyOverrides[family] {
            return override
        }

        switch family {
        case 10...:
            return 92
        case 9:
            return 84
        case 7...8:
            return 74
        case 5...6:
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
        if major == 10 { return 40 }
        return 25
    }

    private static func scoreForIPadMajor(_ major: Int) -> HeadroomScore {
        // Conservative because iPad identifiers are less linear across Air, mini, base, and Pro lines.
        switch major {
        case 16...:
            return 92
        case 14...15:
            return 84
        case 11...13:
            return 72
        case 7...10:
            return 55
        default:
            return 35
        }
    }

    private static func scoreForIPodMajor(_ major: Int) -> HeadroomScore {
        switch major {
        case 9...:
            return 40
        default:
            return 25
        }
    }
}
