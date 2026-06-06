import Foundation
#if os(iOS)
    import DeviceKit
#endif

struct SystemHeadroomSignalProvider: HeadroomSignalProviding {
    func signals(memoryPressurePolicy: HeadroomMemoryPressurePolicy) -> HeadroomSignals {
        let processInfo = ProcessInfo.processInfo
        let memory = HeadroomResourceReader.memory()
        let device = currentDevice()

        return HeadroomSignals(
            deviceDescription: deviceDescription(device),
            deviceOverrideKey: deviceOverrideKey(device),
            machineIdentifier: MachineIdentifier.current(),
            isSimulator: isSimulator(device),
            physicalMemoryBytes: memory.physicalBytes,
            deviceKitScore: deviceKitScore(device),
            availableMemoryBytes: memory.availableBytes,
            memoryPressure: memory.pressure(using: memoryPressurePolicy),
            lowPowerModeEnabled: lowPowerModeEnabled(processInfo),
            thermalState: HeadroomResourceReader.thermalState(processInfo.thermalState),
            metalAppleGPUFamily: MetalGPUFamilyResolver.highestSupportedAppleFamily()
        )
    }

    private func currentDevice() -> Device? {
        #if os(iOS)
            return Device.current
        #else
            return nil
        #endif
    }

    private func deviceDescription(_ device: Device?) -> String {
        #if os(iOS)
            return device?.description ?? "Unknown device"
        #else
            return "Unsupported platform"
        #endif
    }

    private func deviceOverrideKey(_ device: Device?) -> String? {
        #if os(iOS)
            return device?.headroomOverrideKey
        #else
            return nil
        #endif
    }

    private func deviceKitScore(_ device: Device?) -> HeadroomScore? {
        #if os(iOS)
            return device?.headroomScore
        #else
            return nil
        #endif
    }

    private func isSimulator(_ device: Device?) -> Bool {
        #if os(iOS)
            return device?.isSimulator ?? false
        #else
            return false
        #endif
    }

    private func lowPowerModeEnabled(_ processInfo: ProcessInfo) -> Bool {
        #if os(iOS) || os(tvOS) || os(watchOS)
            return processInfo.isLowPowerModeEnabled
        #elseif os(macOS)
            if #available(macOS 12.0, *) {
                return processInfo.isLowPowerModeEnabled
            } else {
                return false
            }
        #else
            return false
        #endif
    }
}
