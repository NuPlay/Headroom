import Foundation

enum HardwareTierResolver {
    static func resolve(signals: HeadroomSignals, policy: HeadroomPolicy = .default) -> HeadroomTier {
        if let overrideKey = signals.deviceOverrideKey,
           let override = policy.deviceOverrides[overrideKey] {
            return override
        }

        if let identifier = signals.machineIdentifier,
           let override = policy.deviceOverrides[identifier] {
            return override
        }

        var candidates: [HeadroomTier] = []

        if let deviceKitTier = signals.deviceKitTier {
            candidates.append(deviceKitTier)
        }

        if let identifier = signals.machineIdentifier,
           let tier = tierForMachineIdentifier(identifier) {
            candidates.append(tier)
        }

        if let family = signals.metalAppleGPUFamily {
            candidates.append(tierForMetalAppleGPUFamily(family, policy: policy))
        }

        if let bestKnownTier = candidates.max() {
            return bestKnownTier
        }

        return tierForMemory(signals.physicalMemoryBytes, thresholds: policy.memoryTierThresholds)
    }

    static func tierForMachineIdentifier(_ identifier: String) -> HeadroomTier? {
        let normalized = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = normalized.prefix { !$0.isNumber }
        let numbers = normalized.dropFirst(prefix.count).split(separator: ",")

        guard let major = numbers.first.flatMap({ Int($0) }) else {
            return nil
        }

        let minor = numbers.dropFirst().first.flatMap { Int($0) }

        switch prefix {
        case "iPhone":
            return tierForIPhone(major: major, minor: minor)
        case "iPad":
            return tierForIPadMajor(major)
        case "iPod":
            return tierForIPodMajor(major)
        default:
            return nil
        }
    }

    static func tierForMetalAppleGPUFamily(_ family: Int, policy: HeadroomPolicy = .default) -> HeadroomTier {
        if let override = policy.metalFamilyOverrides[family] {
            return override
        }

        switch family {
        case 9...:
            return .ultra
        case 7...8:
            return .high
        case 5...6:
            return .medium
        default:
            return .low
        }
    }

    static func tierForMemory(
        _ bytes: UInt64,
        thresholds: HeadroomMemoryTierThresholds = .default
    ) -> HeadroomTier {
        if bytes >= thresholds.ultraBytes {
            return .ultra
        }

        if bytes >= thresholds.highBytes {
            return .high
        }

        if bytes >= thresholds.mediumBytes {
            return .medium
        }

        return .low
    }

    private static func tierForIPhone(major: Int, minor: Int?) -> HeadroomTier {
        // iPhone major identifiers roughly track product generations:
        // 11: iPhone XS/XR (A12), 12: iPhone 11 (A13), 13: iPhone 12 (A14),
        // 14: iPhone 13 (A15), 15: iPhone 14 (A15/A16), 16: iPhone 15 (A16/A17 Pro),
        // 17: iPhone 16 (A18), 18+: newer.
        if major == 16, let minor, [1, 2].contains(minor) {
            // iPhone 15 Pro / 15 Pro Max, A17 Pro.
            return .ultra
        }

        switch major {
        case 17...:
            return .ultra
        case 14...16:
            return .high
        case 11...13:
            return .medium
        default:
            return .low
        }
    }

    private static func tierForIPadMajor(_ major: Int) -> HeadroomTier {
        // Conservative because iPad identifiers are less linear across Air, mini, base, and Pro lines.
        switch major {
        case 14...:
            return .ultra
        case 11...13:
            return .high
        case 7...10:
            return .medium
        default:
            return .low
        }
    }

    private static func tierForIPodMajor(_ major: Int) -> HeadroomTier {
        switch major {
        case 9...:
            return .medium
        default:
            return .low
        }
    }
}
