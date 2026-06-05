import Foundation

/// A convenience bundle of the current runtime resource readings.
public struct HeadroomResources: Equatable, Sendable {
    public let memory: HeadroomMemoryInfo
    public let storage: HeadroomStorageInfo
    public let thermalState: HeadroomThermalState
    public let memoryPressure: HeadroomMemoryPressure

    public init(
        memory: HeadroomMemoryInfo,
        storage: HeadroomStorageInfo,
        thermalState: HeadroomThermalState,
        memoryPressure: HeadroomMemoryPressure? = nil
    ) {
        self.memory = memory
        self.storage = storage
        self.thermalState = thermalState
        self.memoryPressure = memoryPressure ?? memory.pressure
    }
}
