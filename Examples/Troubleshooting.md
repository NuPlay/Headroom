# Troubleshooting Headroom Decisions

Headroom decisions should be explainable from a feature, a snapshot, resources, and failure codes. Start by capturing a diagnostic report:

```swift
let report = Headroom.diagnosticReport(of: feature)
print(report.failureCodes)
print(report.diagnosticSummary)
```

If you need to reproduce the decision later, encode the report:

```swift
let data = try JSONEncoder().encode(report)
```

## Common symptoms

| Symptom | Likely cause | What to do |
| --- | --- | --- |
| A feature passes on simulator but fails on device | Simulator identity and runtime pressure can differ from real hardware | Test on a representative device and attach `HeadroomFeatureDiagnosticReport` JSON |
| A modern phone suddenly falls back | Low Power Mode, thermal state, or memory pressure reduced the effective score | Check `failureCodes`; use `.hardwareOnly` only when runtime pressure should not affect eligibility |
| A storage gate fails even though Settings shows free space | iOS reports different capacity buckets for regular, important, and opportunistic work | Pick the correct `HeadroomStorageUsage` for the operation |
| A memory gate fails with missing available memory | The OS may not provide a reliable available-memory reading in every environment | Keep a safe fallback or remove the hard memory requirement for that feature |
| A device score looks too strict or too loose for your app | Built-in scores are rounded product heuristics, not app-specific benchmark results | Calibrate with `Headroom.configure { $0.overrideDevice(..., as: ...) }` |
| A privacy manifest warning appears in an app archive | The package resource may not be included or a new required-reason API was added | Confirm `PrivacyInfo.xcprivacy` is bundled and update the manifest if APIs change |
| Tests affect each other | `Headroom.configure` changes global configuration | Reset with `Headroom.resetConfiguration()` after each test or use an isolated helper |
| An OS API still crashes or is unavailable | Headroom does not replace OS availability checks | Keep `#available` checks for OS APIs and use Headroom for capability decisions |

## Minimal support checklist

When opening an issue, include:

- the `HeadroomFeature` requirement,
- `report.failureCodes` and `report.diagnosticSummary`,
- `HeadroomFeatureDiagnosticReport` JSON when possible,
- device model or machine identifier,
- whether the run was on a simulator,
- Low Power Mode and thermal state if visible,
- any custom `Headroom.configure` overrides.
