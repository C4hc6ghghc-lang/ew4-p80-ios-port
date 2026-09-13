# P80 iOS build status — 2026-09-13

This repository is the user's P80 reverse-engineered iOS port. It is separate from the Emperor's Triumph Android mod supplied earlier.

## Verified in this session

- Original SOURCE_LEAN inventory: 6321/6321 exact hashes.
- Native resources: 1751/1751 exact hashes.
- Native static preflight: 26/26 checks; Xcode candidate checks: 6/6.
- GitHub macOS reference tests: 126/126 JS files passed.
- GitHub macOS Swift tests: 286 Swift Testing + 9 XCTest passed.
- Real iPhoneOS Release arm64 compilation: **BUILD SUCCEEDED**, run 34747646672, source commit 9873a3706ec05005c0b76c71a96baf0c2887c72b.

## Fixes made

Installed the missing skia-canvas reference-test dependency; corrected parsing of Swift Testing success output; isolated SpriteKit renderer helpers to MainActor; corrected missing scene members, closure lifetime annotations, public move-result construction, rectangle conversion/hit testing, placement argument labels, initialization captures, scrolling delta and a tutorial assignment typo.

The successful compile stopped at the post-build orientation check. The current source adds the shared UISupportedInterfaceOrientations declaration while retaining the iPhone/iPad declarations. This final metadata fix has not yet been rebuilt by Xcode.

## Current blocker

GitHub refused to start build run 34747767610 and simulator smoke run 34747768972:

> The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings

The billing overview subsequently confirmed 2000/2000 included Actions minutes and 0.5/0.5 GB included storage consumed, with included usage resetting in 18 days. Billable usage after discounts was $0 at inspection.

No billing settings were changed. No final IPA has been generated or retrieved. No simulator launch or physical-device gameplay validation has completed.

After billing is resolved, rerun **Build EW4 P80 unsigned IPA** and **Smoke test P80 iPhone and iPad** on main. There is no need to re-import the source.

Actions artifact storage was also unavailable. Workflows now save IPA/checksum/diagnostics and simulator evidence as assets of draft releases in this private repository. The drafts do not publish the game publicly.

Repository: https://github.com/C4hc6ghghc-lang/ew4-p80-ios-port

Build with successful compilation: https://github.com/C4hc6ghghc-lang/ew4-p80-ios-port/actions/runs/34747646672

Latest blocked build: https://github.com/C4hc6ghghc-lang/ew4-p80-ios-port/actions/runs/34747767610

The intended deliverable is an unsigned IPA for subsequent signing, targeting iOS 15+, iPhone and iPad. Earlier archive handoff notes are historical records, not evidence that current device testing has passed.
