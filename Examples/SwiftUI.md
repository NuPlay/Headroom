# SwiftUI Integration Examples

Evaluate Headroom at feature boundaries, keep a stable fallback, and refresh the decision when runtime conditions may have changed.

## A small gate model

```swift
import Combine
import Headroom
import SwiftUI
import UIKit

@MainActor
final class RealtimeBlurGate: ObservableObject {
    @Published private(set) var isAvailable = false
    @Published private(set) var diagnosticSummary = "Not evaluated yet"

    private let feature = HeadroomFeature(
        .iPhone13,
        resources: .init(memory: .mebibytes(300)),
        allowsLowPowerMode: false,
        maximumThermalState: .fair
    )

    func refresh() {
        let result = Headroom.availability(of: feature)
        isAvailable = result.isAvailable
        diagnosticSummary = result.diagnosticSummary
    }
}

struct AdaptiveBackground: View {
    @StateObject private var gate = RealtimeBlurGate()

    var body: some View {
        ZStack {
            if gate.isAvailable {
                RealtimeBlurBackground()
            } else {
                StaticBackground()
            }

            #if DEBUG
            VStack {
                Spacer()
                Text(gate.diagnosticSummary)
                    .font(.caption2)
                    .padding(8)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            #endif
        }
        .task { gate.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            gate.refresh()
        }
    }
}
```

## Best practices

- Evaluate once per screen, flow, download, or expensive operation rather than inside tight animation loops.
- Always provide a real fallback; Headroom is a feature gate, not a crash-prevention mechanism.
- Use `.adaptive` for runtime-sensitive work and `.hardwareOnly` for product eligibility that should not change because of Low Power Mode or thermal pressure.
- In internal builds, surface `diagnosticSummary` or `failureCodes` so QA can explain fallback behavior.
- Pair Headroom with `#available` when a feature also requires a specific OS API.
