import Foundation
#if os(iOS)
import Metal
#endif

enum MetalGPUFamilyResolver {
    static func highestSupportedAppleFamily() -> Int? {
        #if os(iOS)
        guard #available(iOS 13.0, *), let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }

        for familyNumber in stride(from: 10, through: 1, by: -1) {
            if supportsAppleFamily(familyNumber, on: device) {
                return familyNumber
            }
        }

        return nil
        #else
        return nil
        #endif
    }

    #if os(iOS)
    @available(iOS 13.0, *)
    private static func supportsAppleFamily(_ familyNumber: Int, on device: MTLDevice) -> Bool {
        // MTLGPUFamily Apple raw values are 1001, 1002, ...
        // Using raw values keeps the package buildable on older SDKs that do not
        // yet expose newer named cases such as `.apple10`.
        guard let family = MTLGPUFamily(rawValue: 1_000 + familyNumber) else {
            return false
        }

        return device.supportsFamily(family)
    }
    #endif
}
