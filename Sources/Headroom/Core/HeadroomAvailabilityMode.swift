import Foundation

/// Whether availability should consider current runtime pressure or only hardware.
public enum HeadroomAvailabilityMode: String, Codable, Sendable {
    /// Uses `effectiveTier`: hardware tier adjusted by Low Power Mode, thermal state, and memory pressure.
    case adaptive

    /// Uses `hardwareTier`: ignores current runtime pressure.
    case hardwareOnly
}
