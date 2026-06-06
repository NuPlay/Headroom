import Foundation

/// A convenience bundle of the current runtime resource readings.
public struct HeadroomResources: Codable, Equatable, Sendable {
    /// Current memory snapshot.
    public let memory: HeadroomMemoryInfo

    /// Current storage snapshot.
    public let storage: HeadroomStorageInfo

    /// Current thermal state.
    public let thermalState: HeadroomThermalState

    /// Current memory-pressure classification.
    public let memoryPressure: HeadroomMemoryPressure

    /// Creates a resource bundle.
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
