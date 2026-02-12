# macOS-Specific Notes

## No Simulator Needed

On macOS, the app runs natively — no simulator is needed. Use `-destination 'platform=macOS'` in your xcodebuild commands.

## Sandbox and File Paths

Xcode always sandboxes the XCUITest runner on macOS. The test runner **cannot** write to `/tmp/`. Files must be written to the runner's sandbox container instead.

The container path depends on your UI test runner's bundle identifier. For example:
```
~/Library/Containers/<your-uitest-runner-bundle-id>/Data/tmp/
```

Use the `--container` (`-c`) flag on every CLI command to set all file paths from this directory:
```bash
$CLI -c "$CT" screenshot
$CLI -c "$CT" tap --target myButton --target-type button
```

The `$CONTAINER` value should come from `.xcuitest-config.json` (`containerPath` field).

## Window Visibility and Focus

- The app window must be visible (not minimized or fully occluded) for screenshots and interactions to work.
- macOS windows can be behind other windows. If interactions fail, run `activate` to bring the app to foreground.
- **Always** run `activate` after starting the test before any scroll/tap commands.

## Kill Stale Processes

Always kill any running app processes before starting a test. Stale app processes from previous runs cause "Failed to terminate" errors:

```bash
pkill -f "$PROCESS_NAME" 2>/dev/null; sleep 2
```

## Orphaned Processes

Killing `xcodebuild` or sending `done` terminates the test runner but leaves the app running. Always clean up after test completion:

```bash
pkill -f "$PROCESS_NAME" 2>/dev/null
```

## Automation Mode Timeout

The first run after an Xcode restart may fail with "Timed out while enabling automation mode." Retrying usually succeeds.

## "Automation Running" Notification

macOS shows a system notification/banner when XCUITest starts automating a native app. This is normal macOS behavior — it doesn't happen on iOS because iOS tests run inside the Simulator. The notification is harmless and does not indicate a different automation mechanism is being used. The implementation uses standard XCUITest APIs.

## Build-First Pattern

Always run `xcodebuild build-for-testing` before `xcodebuild test-without-building` to catch build errors early. `xcodebuild test` can hang if the build fails.

```bash
# Step 1: Build (catches errors without hanging)
xcodebuild build-for-testing \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination '$DESTINATION'

# Step 2: Run (MUST use Bash tool's run_in_background: true)
xcodebuild test-without-building \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination '$DESTINATION' \
  -only-testing:"$UI_TEST_TARGET/$TEST_CLASS/$TEST_METHOD"
```

## SwiftUI List Identifier Placement

In SwiftUI `List`/`OutlineRow`, accessibility identifiers set via `.accessibilityIdentifier()` on row content land on `StaticText` children, not the `Cell` or `OutlineRow` itself. When tapping by identifier on list rows, use `--target-type staticText` instead of `--target-type cell`.

Using `--target-type any` may match other elements in the row (e.g., Button children like Edit/Trash icons) before the text. Use `--target-type staticText --index 0` to reliably hit the label.

## Pinch Not Available

The `pinch` command is iOS-only and will not work on macOS.
