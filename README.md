# Agent Device: stale trailing-window reproduction

A small UIKit app and real XCUITest reproducing the window-resolution race in
[callstack/agent-device](https://github.com/callstack/agent-device).
No React Native, Expo, backend, account, or npm dependencies are needed.

The app keeps its main `UIWindow` alive. Every five seconds it shows a second
window for 600 ms, then hides/releases it. The test repeatedly calls either the
original or proposed window resolver. Both use real `XCUIApplication` and
`XCUIElement` objects. There are no mocked failures, test hooks inside the
resolver, or artificial delays between its existence and frame reads.

The original resolver reads every window frame before selecting the first usable
window. A trailing window can disappear after `exists` returns true but before
`frame` resolves it. XCTest records `Failed to get matching snapshot: No matches
found for Element at index ...`, even though the main window remains usable.
The proposed resolver returns immediately after finding the first non-empty frame.

## Run

Requirements: macOS, Xcode with an installed iOS Simulator runtime, and an iOS
simulator UDID. The generated Xcode project is committed; XcodeGen is only needed
if editing `project.yml`. Simulator signing is disabled; no developer team is needed.

```sh
git clone https://github.com/wcastand/agent-device-window-race-repro.git
cd agent-device-window-race-repro
xcrun simctl list devices available
./reproduce.sh <iOS-simulator-UDID>
```

Use a simulator available for testing; Xcode launches the fixture and test runner
on it. The script runs the original first and requires the specific stale-element
failure. It then runs the patched resolver and requires a successful test. Exit 0
means both conditions were met. Build/setup errors and a run that misses the race
are failures, not successful reproductions. Logs and `.xcresult` bundles stay in
`.build/`, outside Git. Automatic verbose failure diagnostics are disabled to
avoid collecting a simulator sysdiagnose for the expected failure.

This is a timing-dependent race, not a deterministic scheduler. Each test is
bounded to 60 seconds of resolver calls (with a 6,000-call cap), plus app startup. If the original does not fail, run it again;
window-query timing varies across machines and simulator versions.

To inspect the individual tests, open `WindowRace.xcodeproj`, select the
`WindowRace` scheme and an iOS simulator, then run `testOriginal` (expected red)
or `testPatched` (expected green). Running the whole suite is expected to be red.

## Source and proposed fix

The original resolver and its helper are taken from Agent Device 0.21.15. The same
implementation was present at upstream commit
[`3660c7fa`](https://github.com/callstack/agent-device/blob/3660c7fa413f386447e4311ca6875db4c83b0010/apple/runner/AgentDeviceRunner/AgentDeviceRunnerUITests/RunnerTests%2BInteraction.swift#L227-L245).
The source is MIT-licensed; Callstack's notice is retained in `LICENSE`.

[`proposed.patch`](proposed.patch) targets the upstream source path, not the npm
package's generated `dist/` path. It preserves first-non-empty-window selection
and the `app.frame` fallback. It avoids unnecessary trailing-window reads; it does
not make `exists` plus `frame` atomic or solve disappearance of the selected window.

This isolates the native resolver, not the entire Agent Device CLI/daemon. It
does not reproduce a keyboard-specific lifecycle or prove that every disappearing
window race is fixed.

## Verified result

On 2026-09-27, `./reproduce.sh` completed with exit 0 on an iPhone 18 Pro simulator
running iOS 27.0, using Xcode 27.0 (27A266a) on macOS 27.0 arm64:

- Original: failed on the 332nd resolver call (zero-based iteration 331), with
  the missing-window snapshot error while `Window (Main)` remained.
- Patched: completed 3843 resolver calls over the one-minute loop without a failure.
- The original race was also observed earlier on iPhone 17 / iOS 26.5.

See [sanitized console excerpts](evidence/validation.txt). The race is probabilistic:
an earlier short run missed it; these results are observations, not a guarantee
that every run or iOS version will fail at the same iteration.
