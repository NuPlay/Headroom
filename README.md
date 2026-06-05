# Headroom

Adaptive performance availability for iOS.

Headroom helps you decide whether an expensive feature has enough **performance headroom** to run well on the current device, under the current runtime conditions.

Think of it as a runtime companion to `#available`:

```swift
import Headroom

if Headroom.isAvailable(.high) {
    enableRealtimeBlur()
} else {
    useStaticBackground()
}
```

`#available` answers: “Is this OS API available?”  
Headroom answers: “Does this device currently have enough room to run this well?”

---

## Why Headroom exists

Modern iOS apps often ship one codebase to a very wide device range:

- older iPhones with limited memory,
- recent Pro devices with much stronger GPU/CPU headroom,
- iPads with large memory pools,
- devices in Low Power Mode,
- devices under thermal pressure,
- users with very little storage left.

Without a small abstraction, feature gating usually becomes scattered app code:

```swift
if device == .iPhoneSE || processInfo.isLowPowerModeEnabled || thermalState == .serious {
    // fallback
} else {
    // expensive feature
}
```

That logic is hard to read, hard to test, and easy to forget when adding a new feature.

Headroom centralizes this into a small, expressive API:

```swift
if Headroom.effectiveTier >= .high {
    showLiveBlur()
}

if Headroom.memoryPressure == .critical {
    reduceCacheSize()
}

if Headroom.storage.canFit(bytes: downloadSize, usage: .important) {
    startDownload()
}
```

The goal is not to produce a perfect benchmark score. The goal is to make adaptive feature decisions simple, explainable, and consistent.

---

## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/NuPlay/Headroom.git", from: "0.1.0")
```

Then add `Headroom` to your target dependencies.

### Requirements

- iOS 13+
- Swift Package Manager
- Depends on [DeviceKit](https://github.com/devicekit/DeviceKit)

DeviceKit 5.8.0 currently requires iOS 13+ through SwiftPM, so Headroom follows that minimum.

---

## Quick start

The simplest way is to describe a feature by a DeviceKit reference device:

```swift
import Headroom

// “This feature is fine on an iPhone 13 or better.”
// `.iPhone13` is DeviceKit.Device.iPhone13.
if Headroom.isAvailable(.iPhone13) {
    enableRealtimeBlur()
} else {
    useStaticBackground()
}
```

By default, this is **adaptive**: Low Power Mode, thermal pressure, and memory pressure can lower `effectiveTier`, so a feature may gracefully fall back even on good hardware.

Headroom re-exports DeviceKit, so `import Headroom` is enough for DeviceKit-style cases like `.iPhone13`, `.iPhone15Pro`, and `.iPadPro11M4`.

If you only care about the device hardware:

```swift
if Headroom.isAvailable(.iPhone13, mode: .hardwareOnly) {
    prepareHighResolutionAssets()
}
```

You can still use tiers directly:

```swift
if Headroom.effectiveTier >= .medium {
    enableAnimations()
}

if Headroom.hardwareTier >= .ultra {
    enablePremiumRenderingMode()
}
```

---

## Core concepts

Headroom separates two tier concepts:

| API | Meaning |
| --- | --- |
| `hardwareTier` | Baseline capability of the device hardware. |
| `effectiveTier` | Current usable capability after runtime pressure is applied. |

Example:

```swift
let hardware = Headroom.hardwareTier
let current = Headroom.effectiveTier
```

A recent Pro device can have strong hardware but a lower effective tier when it is hot, low on memory, or in Low Power Mode.

```swift
// Example idea:
// hardwareTier  = .ultra
// effectiveTier = .medium  // because Low Power Mode + thermal pressure
```

---

## Tiers

```swift
.low
.medium
.high
.ultra
```

Suggested interpretation:

| Tier | Suggested meaning |
| --- | --- |
| `.low` | Conservative UI, avoid expensive realtime effects. |
| `.medium` | Default experience, lightweight effects. |
| `.high` | Heavier UI effects, media work, richer animations. |
| `.ultra` | Premium paths for recent high-end hardware. |

These are intentionally coarse. Headroom is designed for product decisions, not micro-benchmarking.

---

## Snapshot

Use `snapshot` when you want the decision and the signals behind it:

```swift
let snapshot = Headroom.snapshot

print(snapshot.hardwareTier)
print(snapshot.effectiveTier)
print(snapshot.signals.deviceDescription)
print(snapshot.signals.machineIdentifier)
print(snapshot.signals.lowPowerModeEnabled)
print(snapshot.signals.thermalState)
print(snapshot.signals.memoryPressure)
print(snapshot.signals.metalAppleGPUFamily)
```

---

## Resource readings

Headroom also exposes resource snapshots directly.

### Memory

```swift
let memory = Headroom.memory

print(memory.physicalBytes)
print(memory.availableBytes)
print(memory.usedBytes)
print(memory.freeBytes)
print(memory.activeBytes)
print(memory.inactiveBytes)
print(memory.wiredBytes)
print(memory.compressedBytes)
print(memory.availableRatio)
print(memory.usedRatio)
```

Memory pressure:

```swift
switch Headroom.memoryPressure {
case .nominal:
    break
case .constrained:
    reduceCacheSize()
case .critical:
    releaseNonEssentialResources()
case .unknown:
    break
}
```

You can also evaluate pressure with a custom policy:

```swift
let pressure = Headroom.memory.pressure(
    using: .init(
        constrainedAvailableRatio: 0.15,
        criticalAvailableRatio: 0.07,
        constrainedAvailableBytes: 768 * 1_048_576,
        criticalAvailableBytes: 256 * 1_048_576
    )
)
```

### Storage

```swift
let storage = Headroom.storage

print(storage.totalCapacityBytes)
print(storage.availableCapacityBytes)
print(storage.importantAvailableCapacityBytes)
print(storage.opportunisticAvailableCapacityBytes)
print(storage.availableRatio)

if storage.canFit(bytes: 500_000_000, usage: .important) {
    startDownload()
}
```

Storage usage types:

| Usage | Meaning |
| --- | --- |
| `.regular` | General available-capacity reading. |
| `.important` | User-requested or important app work. |
| `.opportunistic` | Nice-to-have cache, prefetch, optional download. |

### Thermal

```swift
let thermalState = Headroom.thermalState

print(thermalState)
print(thermalState.isPerformanceConstrained)
print(Headroom.isThermallyConstrained)
```

> Note: iOS public API exposes `ProcessInfo.ThermalState`, not the actual device temperature in Celsius. Headroom intentionally exposes thermal state only.

### All resources at once

```swift
let resources = Headroom.resources

resources.memory.availableBytes
resources.memoryPressure
resources.storage.importantAvailableCapacityBytes
resources.thermalState
```

---

## Feature gates

For real features, a single tier check is often not enough. Headroom supports feature-level gates:

```swift
let realtimeBlur = HeadroomFeature(
    .iPhone13,
    minimumAvailableMemoryBytes: 300 * 1_048_576,
    allowsLowPowerMode: false,
    maximumThermalState: .fair
)

if Headroom.isAvailable(realtimeBlur) {
    enableRealtimeBlur()
} else {
    useStaticBackground()
}
```

If you want to know why a feature is unavailable:

```swift
let result = Headroom.availability(of: realtimeBlur)

if !result.isAvailable {
    print(result.failures)
}
```

Possible failure reasons include:

- required tier is higher than current tier,
- Low Power Mode is enabled,
- thermal state is too high,
- available memory is too low,
- available storage is too low.

You can gate against either `effectiveTier` or `hardwareTier`:

```swift
let hardwareOnlyFeature = HeadroomFeature(
    requiredTier: .ultra,
    tierSource: .hardware
)
```

---

## Customization

Most customization should stay simple: choose a DeviceKit reference device.

```swift
if Headroom.isAvailable(.iPhone13) {
    enableFeature()
}
```

Use `.adaptive` when the feature should fall back under Low Power Mode, thermal pressure, or memory pressure. This is the default.

```swift
Headroom.isAvailable(.iPhone13)
```

Use `.hardwareOnly` when you only need to know whether the hardware class is high enough.

```swift
Headroom.isAvailable(.iPhone13, mode: .hardwareOnly)
```

If Headroom's built-in tier for a DeviceKit device does not match your app's needs, override it with a DeviceKit case, not a raw identifier string:

```swift
Headroom.configure {
    $0.overrideDevice(.iPhone15Pro, as: .ultra)
    $0.overrideDevice(.iPadPro11M4, as: .ultra)
}
```

Advanced policy tuning is still available, but should be rare:

```swift
Headroom.configure {
    $0.lowPowerModeCap = .medium
    $0.fairThermalCap = .medium
    $0.seriousThermalDowngrade = 2

    $0.memoryPressurePolicy = .init(
        constrainedAvailableRatio: 0.15,
        criticalAvailableRatio: 0.07,
        constrainedAvailableBytes: 768 * 1_048_576,
        criticalAvailableBytes: 256 * 1_048_576
    )
}
```

### Debug overrides

Useful for previews, QA, and fallback testing:

```swift
#if DEBUG
Headroom.configure {
    $0.forcedEffectiveTier = .low
}
#endif
```

Reset to defaults:

```swift
Headroom.resetConfiguration()
```

---

## How Headroom decides

Headroom uses a layered strategy:

1. Device identity through DeviceKit and machine identifiers.
2. Apple SoC / device-generation heuristics.
3. Metal Apple GPU family fallback for unknown newer devices.
4. Physical memory as a fallback signal.
5. Runtime modifiers:
   - Low Power Mode,
   - thermal state,
   - memory pressure.
6. Optional app-provided policy overrides.

Headroom does **not** run synthetic benchmarks at startup. Benchmarks can be noisy, slow, battery-intensive, and affected by the exact thermal conditions they are trying to measure.

---

## Limitations

- Headroom does not replace `#available`. You still need OS availability checks for OS APIs.
- Headroom does not expose actual iPhone temperature in Celsius because public iOS API does not provide it.
- Tiers are coarse by design and should be calibrated to your app's feature set.
- The built-in device mapping is intentionally conservative; use overrides when your app needs stricter or looser behavior.

---

## License

Headroom is available under the MIT license. See [LICENSE](LICENSE).
