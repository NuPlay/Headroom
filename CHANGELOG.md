# Changelog

All notable changes to Headroom will be documented in this file.

This project follows semantic versioning once `1.0.0` is released.

## Unreleased

### Changed

- CI now runs on GitHub's `macos-26` image, selects the newest available Xcode 26, and isolates SwiftPM/Xcode build state under the runner temp directory.
- CI test/build failures now emit the tail of the underlying SwiftPM or `xcodebuild` log as GitHub annotations and step summaries, so failures remain diagnosable even when full job logs are unavailable.
- CI still runs the test suite with Xcode 26 `swift test` on macOS and compiles the iOS Simulator test bundle with `xcodebuild build-for-testing`, avoiding simulator boot flakes while still checking iOS-only code.

## 0.3.1 - 2026-06-10

### Changed

- CI now runs `xcodebuild test` on the iOS Simulator instead of `swift test` on macOS, so tests execute in the same environment as the library target.
- CI selects Xcode 26 on GitHub Actions and picks a concrete available iPhone simulator instead of pinning a fixed OS image.
- Strict concurrency checks now build the iOS Simulator target in CI instead of the macOS host build.

## 0.3.0 - 2026-06-10

### Added

- GitHub Actions CI that runs `swift test` on macOS and builds the library for the iOS Simulator.

### Changed

- The library now builds without warnings under Swift strict concurrency checking, ahead of Swift 6 language mode.
- Memory page size is read with `host_page_size` instead of the `vm_kernel_page_size` global.
- The package manifest now declares a macOS 10.15 minimum so the Swift Testing test suite builds on CI toolchains.

## 0.2.0 - 2026-06-07

### Added

- Mode-aware score and tier helpers.
- Human-readable feature availability diagnostics and recovery suggestions.
- Stable feature availability failure kinds and codes for logs, QA, and product logic.
- Deterministic feature availability overloads for supplied snapshots and resource bundles.
- `HeadroomFeatureDiagnosticReport` for Codable support/QA artifacts that bundle feature, snapshot, resources, and result.
- Diagnostic report schema version metadata with legacy-artifact decoding.
- Diagnostic report replay helpers for validating decoded support artifacts.
- `HeadroomByteCount` and `HeadroomFeatureResourceRequirements` for readable memory/storage feature gates.
- Codable support for public diagnostic, configuration, resource, and feature models.
- Contributor guidance, DocC overview, and copy-paste examples for feature gates, diagnostics, and calibration.
- SwiftUI integration and troubleshooting examples for common adoption paths.
- SwiftUI sample app shell that combines adaptive feature gates, hardware-only eligibility, storage checks, and diagnostics.
- Privacy manifest declaring no data collection/tracking and disk-space required-reason API usage.

### Changed

- Configuration updates are safer when code reads configuration while applying an update.
- Feature availability failures now encode as stable tagged diagnostic JSON with a `kind` field.
- Feature gates normalize non-positive memory and storage requirements so `0` does not require unavailable resource readings.
