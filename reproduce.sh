#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ $# != 1 ]]; then
  echo "Usage: ./reproduce.sh <iOS-simulator-UDID>" >&2
  exit 2
fi
mkdir -p .build
run_dir="$(mktemp -d "$PWD/.build/run-XXXXXX")"
common=(-project WindowRace.xcodeproj -scheme WindowRace
  -destination "platform=iOS Simulator,id=$1"
  -derivedDataPath .build/DerivedData -parallel-testing-enabled NO
  -collect-test-diagnostics never)
echo "Running original resolver; a stale-window XCTest failure is expected."
set +e
xcodebuild test "${common[@]}" -only-testing:WindowRaceUITests/WindowRaceTests/testOriginal \
  -resultBundlePath "$run_dir/original.xcresult" > "$run_dir/original.log" 2>&1
original_status=$?
set -e
if [[ $original_status != 65 ]] || ! grep -q 'Failed to get matching snapshot: No matches found for Element at index' "$run_dir/original.log"; then
  echo "Race not confirmed (exit $original_status). Inspect $run_dir/original.log" >&2
  exit 1
fi
echo "Original: reproduced the stale-window failure."
echo "Running patched resolver."
xcodebuild test-without-building "${common[@]}" -only-testing:WindowRaceUITests/WindowRaceTests/testPatched \
  -resultBundlePath "$run_dir/patched.xcresult" > "$run_dir/patched.log" 2>&1
if ! grep -q "WindowRaceTests testPatched]' passed" "$run_dir/patched.log"; then
  echo "Patched test did not report a pass. Inspect $run_dir/patched.log" >&2
  exit 1
fi
echo "Patched: passed. Logs and xcresult bundles: $run_dir"
