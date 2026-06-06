# Calibration Examples

Headroom defaults are conservative, rounded heuristics. Prefer DeviceKit reference devices for product decisions, and use overrides only when your app has better local evidence.

## Tune runtime pressure

```swift
import Headroom

Headroom.configure {
    $0.lowPowerModePenalty = 12
    $0.seriousThermalPenalty = 15
    $0.criticalThermalScore = 20
}
```

## Override a known device baseline

```swift
import Headroom

Headroom.configure {
    $0.overrideDevice(.iPhone15Pro, as: 86)
}
```

## Force scores in debug builds

```swift
import Headroom

#if DEBUG
Headroom.configure {
    $0.forcedEffectiveScore = 35
}
#endif
```

## Reset after tests or previews

```swift
import Headroom

Headroom.resetConfiguration()
```
