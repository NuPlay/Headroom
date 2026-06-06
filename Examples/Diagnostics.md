# Diagnostics Examples

Headroom decisions are designed to be explainable and replayable.

## User-visible fallback reason for internal builds

```swift
import Headroom

let result = Headroom.availability(of: realtimeBlur)

if !result.isAvailable {
    print(result.failureCodes)
    print(result.diagnosticSummary)
    result.recoverySuggestions.forEach { print("• \($0)") }
}
```

## Codable support artifact

Attach a diagnostic report to QA feedback or support tickets so maintainers can reproduce the exact decision.

```swift
import Foundation
import Headroom

let report = Headroom.diagnosticReport(of: realtimeBlur)
let data = try JSONEncoder().encode(report)
```

Reports include `schemaVersion` so support tools can distinguish current and legacy artifacts. Failure records use a stable tagged JSON shape. For example, a score failure encodes the `kind`, required score, current score, and score source instead of requiring tools to parse display text.

## Replay a captured decision

```swift
import Headroom

let replayed = Headroom.availability(
    of: capturedReport.feature,
    snapshot: capturedReport.snapshot,
    resources: capturedReport.resources
)

assert(replayed == capturedReport.availability)
```

## Validate decoded reports

If a diagnostic report came from a log, ticket, or copied JSON, verify that it still replays with the current Headroom version:

```swift
if !capturedReport.isCurrentSchemaVersion {
    print("Report uses a legacy diagnostic schema")
}

if !capturedReport.isReplayConsistent {
    print("Report availability does not match a fresh replay")
}
```
