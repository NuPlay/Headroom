import Foundation

protocol HeadroomSignalProviding: Sendable {
    func signals(memoryPressurePolicy: HeadroomMemoryPressurePolicy) -> HeadroomSignals
}
