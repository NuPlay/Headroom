import Combine
import Foundation
import Headroom

@MainActor
final class HeadroomSampleViewModel: ObservableObject {
    @Published private(set) var realtimeEffectsAvailable = false
    @Published private(set) var proEditingToolsVisible = false
    @Published private(set) var offlinePackAvailable = false
    @Published private(set) var realtimeEffectsReport: HeadroomFeatureDiagnosticReport?
    @Published private(set) var offlinePackReport: HeadroomFeatureDiagnosticReport?

    private let realtimeEffects = HeadroomFeature(
        .iPhone13,
        resources: .init(memory: .mebibytes(300)),
        allowsLowPowerMode: false,
        maximumThermalState: .fair
    )

    private let proEditingTools = HeadroomFeature(
        .iPhone15Pro,
        mode: .hardwareOnly
    )

    private let offlinePack = HeadroomFeature(
        requiredTier: .medium,
        resources: .storage(.gibibytes(2), usage: .important),
        maximumThermalState: .serious
    )

    func refresh() {
        let realtimeReport = Headroom.diagnosticReport(of: realtimeEffects)
        let offlineReport = Headroom.diagnosticReport(of: offlinePack)

        realtimeEffectsAvailable = realtimeReport.isAvailable
        proEditingToolsVisible = Headroom.isAvailable(proEditingTools)
        offlinePackAvailable = offlineReport.isAvailable
        realtimeEffectsReport = realtimeReport
        offlinePackReport = offlineReport
    }
}
