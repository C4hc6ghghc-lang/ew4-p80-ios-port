# P80 iOS build status — 2026-09-13

This is the user's P80 reverse-engineered iOS port, separate from the Emperor's Triumph Android mod. No game-rule changes from that mod request were applied here.

## Verified

- Device Release arm64 build and unsigned IPA packaging succeeded: run 34748461764, source ee67e7cd9af94ec5158b99e7045f837b6fb6871a.
- iPhone 16 Pro and iPad Pro 11-inch (M4), both iOS 18.5: installation, launch and process checks after 15 seconds passed in run 34748471619. Its test step succeeded; the workflow as a whole failed because GitHub returned HTTP 502 while creating the evidence release. Screenshots were captured remotely but could not be retrieved for visual review.
- Evidence-upload retries were added in 9401f65 without changing app source. Follow-up screenshot run 34748760655 was queued at handoff; its result is not counted as verified here.
- 126 JS regression files, 286 Swift Testing cases and 9 XCTest cases passed on macOS.
- Source reference inventory: 6321 exact hashes; native resource inventory: 1751 exact hashes. The final downloaded IPA's resources also match all 1751 original hashes and sizes.
- Native preflight: 26 checks; Xcode candidate static gate: 6 checks.

## Packaging and compiler fixes

The Apple SDK build required MainActor isolation for SpriteKit helper classes, corrections to missing scene members, closure lifetimes, rectangle conversion/hit testing, public move-result construction, placement labels, initialization captures, scrolling delta, and a tutorial assignment typo. The build pipeline installs the reference canvas dependency and correctly parses Swift Testing summaries.

App metadata now declares landscape orientations, version 1.0.0 (80) and iPhone/iPad support. Resources are copied intact to GameAssets/Resources because a top-level Resources directory makes CFBundle misidentify the iOS app and prevents installation. Runtime resource lookup and payload gates use the same nested path, preserving all duplicate basenames.

## Delivery limits

The IPA is unsigned and requires valid signing before physical-device installation. iOS 15+ is the deployment target; physical devices and complete campaign/conquest playthroughs have not been verified. A successful simulator process check is not visual or full gameplay acceptance.

## GitHub

Repository is now PUBLIC at the user's request. Standard macos-15 hosted Actions runs are free for this public repository. Twenty old Actions artifacts were deleted from the account; all three inspected repositories reported zero remaining artifacts. Billing settings and payment methods were not changed.

Builds and diagnostics are stored in draft Release assets, not Actions artifacts. The owner must sign in to retrieve drafts. Historical archive notes describing earlier blockers are superseded by this status file.
