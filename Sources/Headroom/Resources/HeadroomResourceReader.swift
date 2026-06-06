import Foundation
#if canImport(Darwin)
    import Darwin
#endif

enum HeadroomResourceReader {
    static func resources(memoryPressurePolicy: HeadroomMemoryPressurePolicy = .default) -> HeadroomResources {
        let memory = memory()
        return HeadroomResources(
            memory: memory,
            storage: storage(),
            thermalState: thermalState(),
            memoryPressure: memory.pressure(using: memoryPressurePolicy)
        )
    }

    static func memory() -> HeadroomMemoryInfo {
        #if canImport(Darwin)
            if let vm = virtualMemorySnapshot() {
                return vm
            }
        #endif

        return HeadroomMemoryInfo(
            physicalBytes: ProcessInfo.processInfo.physicalMemory
        )
    }

    static func storage(url: URL? = nil) -> HeadroomStorageInfo {
        let targetURL = url ?? URL(fileURLWithPath: NSHomeDirectory())
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityForOpportunisticUsageKey,
        ]

        guard let values = try? targetURL.resourceValues(forKeys: keys) else {
            return HeadroomStorageInfo()
        }

        return HeadroomStorageInfo(
            totalCapacityBytes: values.volumeTotalCapacity.map(Int64.init),
            availableCapacityBytes: values.volumeAvailableCapacity.map(Int64.init),
            importantAvailableCapacityBytes: values.volumeAvailableCapacityForImportantUsage,
            opportunisticAvailableCapacityBytes: values.volumeAvailableCapacityForOpportunisticUsage
        )
    }

    static func thermalState() -> HeadroomThermalState {
        thermalState(ProcessInfo.processInfo.thermalState)
    }

    static func thermalState(_ state: ProcessInfo.ThermalState) -> HeadroomThermalState {
        switch state {
        case .nominal:
            return .nominal
        case .fair:
            return .fair
        case .serious:
            return .serious
        case .critical:
            return .critical
        @unknown default:
            return .unknown
        }
    }

    #if canImport(Darwin)
        private static func virtualMemorySnapshot() -> HeadroomMemoryInfo? {
            var stats = vm_statistics64_data_t()
            var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

            let result = withUnsafeMutablePointer(to: &stats) { statsPointer in
                statsPointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                    host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
                }
            }

            guard result == KERN_SUCCESS else { return nil }

            let pageSize = UInt64(vm_kernel_page_size)
            func bytes(_ pages: natural_t) -> UInt64 {
                UInt64(pages) * pageSize
            }

            let free = bytes(stats.free_count + stats.speculative_count)
            let active = bytes(stats.active_count)
            let inactive = bytes(stats.inactive_count)
            let wired = bytes(stats.wire_count)
            let compressed = bytes(stats.compressor_page_count)
            let available = free + inactive
            let used = active + wired + compressed

            return HeadroomMemoryInfo(
                physicalBytes: ProcessInfo.processInfo.physicalMemory,
                availableBytes: available,
                usedBytes: used,
                freeBytes: free,
                activeBytes: active,
                inactiveBytes: inactive,
                wiredBytes: wired,
                compressedBytes: compressed,
                pageSizeBytes: pageSize
            )
        }
    #endif
}
