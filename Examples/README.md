# Headroom Examples

These examples are copy-paste oriented starting points for common Headroom adoption paths.

- [Feature gates](FeatureGates.md): choose feature fallbacks from device, memory, storage, thermal state, and Low Power Mode.
- [Diagnostics](Diagnostics.md): log or attach reproducible reports for QA and support.
- [Calibration](Calibration.md): tune Headroom policy and overrides for your app.
- [SwiftUI integration](SwiftUI.md): evaluate gates from a view model and surface debug diagnostics.
- [Troubleshooting](Troubleshooting.md): map common symptoms to the right diagnostic or configuration fix.
- [Sample app](SampleApp/README.md): a small SwiftUI app shell showing premium paths, fallbacks, storage gates, and diagnostics together.

All examples are intentionally small and deterministic. Headroom does not run startup benchmarks or make network calls.
