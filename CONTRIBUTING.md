# Contributing to Headroom

Thank you for helping make Headroom reliable, predictable, and easy to adopt.

## Development setup

1. Install Xcode with Swift 5.9 or newer.
2. Clone the repository.
3. Run the tests:

```sh
swift test
```

## Quality bar

Changes should keep Headroom:

- deterministic: no startup benchmarks or network calls,
- explainable: decisions should be diagnosable from `Headroom.snapshot` or feature failure reasons,
- conservative by default: prefer safe fallbacks under uncertainty,
- source-compatible whenever possible,
- covered by focused tests for score boundaries, runtime pressure, configuration, resources, and diagnostics.

When a change affects adoption, update the README, DocC overview, or examples alongside code changes.

## Pull request checklist

- [ ] Add or update tests for behavior changes.
- [ ] Update README, DocC, or examples for public API changes.
- [ ] Run `swift test`.
- [ ] Avoid committing generated build artifacts.

## Calibration guidelines

Headroom scores are product heuristics, not raw benchmark numbers. Keep values rounded and stable so feature gates stay readable. When adding a device mapping, prefer a conservative score until enough public data exists.
