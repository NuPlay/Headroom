# Headroom Sample App

This sample shows a small SwiftUI adoption path that app teams can copy into an iOS app. It demonstrates:

- adaptive feature gates with a tested fallback path,
- a hardware-only gate for product eligibility,
- a storage gate for user-requested work,
- diagnostic summaries for internal builds,
- refreshing decisions when the app becomes active.

The sample uses the SwiftUI app lifecycle, so the full app shell targets iOS 14+. The Headroom package itself supports iOS 13+.

## Files

- [HeadroomSampleApp.swift](HeadroomSampleApp.swift): minimal SwiftUI app entry point.
- [AdaptiveExperienceView.swift](AdaptiveExperienceView.swift): UI that switches between premium and fallback paths.
- [HeadroomSampleViewModel.swift](HeadroomSampleViewModel.swift): feature definitions, availability evaluation, and diagnostics.

## Try it in an app

1. Add Headroom with Swift Package Manager as described in the [README](../../README.md).
2. Copy the sample files into an iOS app target.
3. Replace the placeholder UI functions with your product's premium and fallback experiences.
4. Run the app on a real device and toggle Low Power Mode to see adaptive decisions change.

For support or QA feedback, encode `viewModel.realtimeEffectsReport` or `viewModel.offlinePackReport` with `JSONEncoder` and attach the JSON to the issue.
