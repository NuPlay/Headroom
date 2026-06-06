import Headroom
import SwiftUI
import UIKit

struct AdaptiveExperienceView: View {
    @StateObject private var viewModel = HeadroomSampleViewModel()

    var body: some View {
        List {
            Section(header: Text("Realtime effects")) {
                if viewModel.realtimeEffectsAvailable {
                    PremiumRealtimeEffectsView()
                } else {
                    StaticFallbackEffectsView()
                }

                DiagnosticText(report: viewModel.realtimeEffectsReport)
            }

            Section(header: Text("Editing tools")) {
                if viewModel.proEditingToolsVisible {
                    Label("Pro editing tools are visible", systemImage: "slider.horizontal.3")
                } else {
                    Label("Showing the standard editor", systemImage: "slider.horizontal.below.rectangle")
                }
            }

            Section(header: Text("Offline pack")) {
                Button("Download offline pack") {
                    startOfflinePackDownload()
                }
                .disabled(!viewModel.offlinePackAvailable)

                DiagnosticText(report: viewModel.offlinePackReport)
            }
        }
        .navigationTitle("Headroom")
        .onAppear(perform: viewModel.refresh)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.refresh()
        }
    }

    private func startOfflinePackDownload() {
        // Start the real download in your app. The feature gate keeps this button
        // disabled when storage, thermal state, or device headroom is not suitable.
    }
}

private struct PremiumRealtimeEffectsView: View {
    var body: some View {
        Label("Premium realtime effects enabled", systemImage: "sparkles")
    }
}

private struct StaticFallbackEffectsView: View {
    var body: some View {
        Label("Static fallback enabled", systemImage: "photo")
    }
}

private struct DiagnosticText: View {
    let report: HeadroomFeatureDiagnosticReport?

    var body: some View {
        #if DEBUG
            if let report {
                Text(report.diagnosticSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        #else
            EmptyView()
        #endif
    }
}
