# Feature Gate Examples

Use feature gates when a code path needs more than a simple device baseline.

## Realtime visual effect

```swift
import Headroom

let realtimeBlur = HeadroomFeature(
    .iPhone13,
    resources: .init(
        memory: .mebibytes(300),
        storage: .megabytes(50)
    ),
    allowsLowPowerMode: false,
    maximumThermalState: .fair
)

if Headroom.isAvailable(realtimeBlur) {
    enableRealtimeBlur()
} else {
    useStaticBackground()
}
```

## Optional download

Use `.important` for user-requested downloads and `.opportunistic` for nice-to-have caches or prefetching.

```swift
import Headroom

let offlinePack = HeadroomFeature(
    requiredTier: .medium,
    resources: .storage(.gibibytes(2), usage: .important),
    maximumThermalState: .serious
)

if Headroom.isAvailable(offlinePack) {
    startDownload()
} else {
    showFreeSpaceOrTryLaterMessage()
}
```

## Hardware-only gate

Use hardware-only mode when transient runtime pressure should not change product eligibility.

```swift
import Headroom

let proEditingTools = HeadroomFeature(
    .iPhone15Pro,
    mode: .hardwareOnly
)

if Headroom.isAvailable(proEditingTools) {
    showProEditingTools()
}
```
