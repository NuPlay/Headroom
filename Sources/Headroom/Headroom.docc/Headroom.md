# ``Headroom``

Use device capability and runtime pressure signals to decide whether an expensive iOS feature should run right now.

## Overview

Headroom is a lightweight companion to `#available`. OS availability tells you whether an API exists; Headroom helps you decide whether the current device and runtime conditions have enough capacity for a feature to feel good.

The default API is intentionally small:

```swift
if Headroom.isAvailable(.iPhone13) {
    runRealtimeEffect()
} else {
    useFallback()
}
```

For feature gates that need more than a device baseline, attach typed resource requirements and policy:

```swift
let realtimeEffect = HeadroomFeature(
    .iPhone13,
    resources: .init(memory: .mebibytes(300), storage: .gibibytes(2)),
    allowsLowPowerMode: false,
    maximumThermalState: .fair
)
```

Use detailed availability when code or diagnostics needs failure reasons:

```swift
let result = Headroom.availability(of: realtimeEffect)

if !result.isAvailable {
    print(result.failureCodes)
    print(result.diagnosticSummary)
}
```

For deterministic tests or QA replay, evaluate a feature against a saved snapshot and resource bundle:

```swift
let result = Headroom.availability(
    of: realtimeEffect,
    snapshot: savedSnapshot,
    resources: savedResources
)
```

When you need a single support artifact, create a Codable diagnostic report:

```swift
let report = Headroom.diagnosticReport(of: realtimeEffect)
let data = try JSONEncoder().encode(report)
```

Keep OS availability checks at the API boundary:

```swift
if #available(iOS 17, *), Headroom.isAvailable(.high) {
    runNewExpensiveAPI()
} else {
    runFallback()
}
```

## Topics

### Quick decisions

- ``Headroom``

### Scores and tiers

- ``HeadroomScore``
- ``HeadroomTier``
- ``HeadroomAvailabilityMode``

### Feature gates

- ``HeadroomFeature``
- ``HeadroomFeatureResourceRequirements``
- ``HeadroomFeatureDiagnosticReport``
- ``HeadroomFeatureAvailability``
- ``HeadroomAvailabilityFailure``
- ``HeadroomAvailabilityFailureKind``
- ``HeadroomFeatureTierSource``

### Runtime diagnostics

- ``HeadroomSnapshot``
- ``HeadroomSignals``
- ``HeadroomResources``
- ``HeadroomByteCount``
- ``HeadroomMemoryInfo``
- ``HeadroomStorageInfo``
- ``HeadroomThermalState``
- ``HeadroomMemoryPressure``

### Configuration

- ``HeadroomConfiguration``
- ``HeadroomPolicy``
- ``HeadroomMemoryPressurePolicy``
- ``HeadroomMemoryScoreThresholds``
