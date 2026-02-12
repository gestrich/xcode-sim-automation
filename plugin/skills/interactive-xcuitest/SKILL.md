---
name: interactive-xcuitest
description: Interactively controls an app through XCUITest via a CLI. Claude reads UI state and screenshots, decides actions, and executes commands. Use for dynamic UI exploration, complex navigation flows, or when pre-scripted navigation isn't feasible.
user-invocable: true
---

# Interactive XCUITest Control

Enables Claude to dynamically control an app through XCUITest using a CLI that abstracts the file-based protocol. Unlike pre-scripted tests, this allows Claude to explore the UI, make decisions based on current state, and recover from unexpected situations.

## Usage

Invoke this skill when you need to:
- Navigate complex UI flows without knowing the exact path ahead of time
- Explore an app's UI to understand its structure
- Perform multi-step interactions that depend on dynamic content
- Test error recovery and edge cases interactively
- Take screenshots of specific views found through exploration

The skill will ask for your goal if not specified (e.g., "Navigate to Settings and enable Dark Mode").

## Configuration

Read `.xcuitest-config.json` from the project root. If it exists, use its values throughout this skill:

- `$PROJECT` = config.xcodeProject (e.g., "MyApp.xcodeproj")
- `$SCHEME` = config.scheme (e.g., "MyApp")
- `$DESTINATION` = config.destination (e.g., "platform=macOS")
- `$UI_TEST_TARGET` = config.uiTestTarget (e.g., "MyAppUITests")
- `$TEST_CLASS` = config.testClass (e.g., "InteractiveControlTests")
- `$TEST_METHOD` = config.testMethod (e.g., "testInteractiveControl")
- `$CONTAINER` = config.containerPath (e.g., "~/Library/Containers/.../Data/tmp")
- `$PROCESS_NAME` = config.processName (e.g., "MyApp")

If `.xcuitest-config.json` doesn't exist, ask the user for these values before proceeding.

If `config.appSpecificNotes` is set, read that file from the project root for app-specific navigation patterns and accessibility identifiers.

### Locating the CLI

The CLI wrapper script (`Tools/xcuitest-control`) is in the xcode-sim-automation repo. To find it:

1. Search for the repo's `Tools/xcuitest-control` wrapper script (not the `.py` file)
2. Common locations: `~/Developer/personal/xcode-sim-automation/Tools/xcuitest-control`
3. If not found, clone the repo: `git clone https://github.com/gestrich/xcode-sim-automation.git`

The wrapper auto-builds the Swift CLI binary on first run and whenever source files change — no manual build step needed.

A Python fallback (`Tools/xcuitest-control.py`) is also available if the Swift toolchain isn't installed.

Set the CLI path variable:
```bash
CLI=<path-to-xcuitest-control>
```

## Prerequisites

### 1. Add the XCUITestControl Swift Package

Add the package to your project via SPM:

```swift
// In Package.swift or via Xcode:
.package(url: "https://github.com/gestrich/xcode-sim-automation.git", from: "1.0.0")
```

### 2. Create an Interactive Control Test

Create a UI test in your project's UI test target (`$UI_TEST_TARGET`):

```swift
import XCTest
import XCUITestControl

final class InteractiveControlTests: XCTestCase {
    @MainActor
    func testInteractiveControl() throws {
        let app = XCUIApplication()
        app.launch()
        InteractiveControlLoop().run(app: app)
    }
}
```

## Workflow

### 1. Set Up Variables

Set these variables at the top of every Bash command (shell state does not persist between Bash tool calls):

```bash
CLI=<path-to-xcuitest-control>
CT="$CONTAINER"
```

Where `$CONTAINER` comes from `.xcuitest-config.json` or is the sandbox container path for your app's UI test runner.

### 2. Kill Stale Processes and Clean Files

Kill any app processes from previous runs (stale processes cause "Failed to terminate" errors):

```bash
pkill -f "$PROCESS_NAME" 2>/dev/null; sleep 2
$CLI -c "$CT" reset
```

### 3. Build and Start the XCUITest

Always build first (catches errors without hanging), then run. All `xcodebuild` commands must be run from the directory containing `$PROJECT` (the `.xcodeproj` file).

```bash
xcodebuild build-for-testing \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination '$DESTINATION'
```

**CRITICAL**: The `xcodebuild test-without-building` command **must** be run using the Bash tool's `run_in_background: true` parameter. Do NOT use shell `&` backgrounding — the process will be killed when the Bash tool call completes.

```bash
# Use run_in_background: true on the Bash tool for this command
xcodebuild test-without-building \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination '$DESTINATION' \
  -only-testing:"$UI_TEST_TARGET/$TEST_CLASS/$TEST_METHOD"
```

The test will:
- Launch the app
- Write initial hierarchy and screenshot to the sandbox container
- Begin polling for commands

### 4. Wait for Test Initialization

Use the `ready` command to poll until the test is running:

```bash
$CLI -c "$CT" ready --timeout 30
```

### 5. Activate the App

**CRITICAL**: Always activate the app first to bring it to the foreground. If the app window is behind other windows, scroll/tap commands will fail with "Unable to find hit point".

```bash
$CLI -c "$CT" activate
```

### 6. Execute Commands

Use the CLI to execute actions:

```bash
# Read current UI state (use the Read tool)
# Read $CT/xcuitest-hierarchy.txt

# View screenshot (use the Read tool)
# Read $CT/xcuitest-screenshot.png

# Execute action
$CLI -c "$CT" tap --target settingsButton --target-type button

# Read updated hierarchy and screenshot after action
```

See [cli-reference.md](cli-reference.md) for the full command reference.

### 7. Exit Gracefully

When the goal is achieved:

```bash
$CLI -c "$CT" done
```

**Note**: The `done` command will report a timeout — this is expected. The test exits before writing a "completed" status. Check the xcodebuild output for "TEST EXECUTE SUCCEEDED" to confirm clean shutdown.

After exit, kill any orphaned app processes:

```bash
pkill -f "$PROCESS_NAME" 2>/dev/null
```

## Sandbox and File Paths

On macOS, Xcode always sandboxes the XCUITest runner. The test runner **cannot** write to `/tmp/`. Files are written to the runner's sandbox container instead.

Use the `--container` (`-c`) flag on every CLI command to set all file paths from the container directory:

```bash
$CLI -c "$CT" screenshot
$CLI -c "$CT" tap --target myButton --target-type button
```

**IMPORTANT**: Shell state does not persist between Bash tool calls. You must include `CLI=...` and `CT=...` in **every** Bash command that uses the CLI.

## Reading the UI Hierarchy

The hierarchy file shows the element tree with types, identifiers, and labels:

```
Application, pid: 12345, label: 'MyApp'
  Window, 0x600000001234
    Other, identifier: 'mainView'
      Button, identifier: 'settingsButton', label: 'Settings'
      StaticText, identifier: 'welcomeLabel', label: 'Welcome!'
      Cell, identifier: 'item_1', label: 'First Item'
      Slider, identifier: 'volumeSlider', value: '50%'
```

From this hierarchy:
- `settingsButton` is a **Button** → `--target-type button`
- `welcomeLabel` is a **StaticText** → `--target-type staticText`
- `item_1` is a **Cell** → `--target-type cell`
- `volumeSlider` is a **Slider** → `--target-type slider`

Use `--target-type any` if unsure — it searches all element types.

## Keyboard Handling

When interacting with text fields, the keyboard may appear and affect other UI elements.

### Dismissing the Keyboard

Tap on a non-interactive element that's visible:

```bash
$CLI tap --target notesLabel --target-type staticText
```

**Tips for dismissing the keyboard:**
- Look in the hierarchy for `StaticText` elements (labels) that are above the keyboard
- Navigation bar titles work well as tap targets
- Section headers or form labels are good choices
- On macOS, pressing Escape can also dismiss keyboards/popovers — use `type --value "\u{1b}"` if needed

### Typing Text

1. **Tap the text field first** to focus it:
   ```bash
   $CLI tap --target searchBar --target-type any
   ```

2. **Then type your text**:
   ```bash
   $CLI type --value "Hello"
   ```

## Additional Reference

- [CLI Commands Reference](cli-reference.md) — Full command documentation, output format, multiple match handling, file-based protocol
- [Error Handling & Troubleshooting](error-handling.md) — Common errors, recovery procedures, robustness configuration
- [macOS-Specific Notes](macos-notes.md) — Sandbox details, window visibility, build-first pattern, orphaned processes

## Tips for Effective Control

1. **Always activate first** — Run `activate` after starting the test to bring the app to foreground
2. **Always read hierarchy first** — Don't guess element identifiers
3. **Use `--container` (`-c`) flag** — Set all file paths with one flag
4. **Use specific target-type** — Faster and more reliable than `any`
5. **Handle errors gracefully** — Read hierarchy after errors to adapt
6. **Wait after animations** — Use the `wait` command if UI is animating
7. **Take screenshots often** — Helps verify you're on the expected view
8. **Exit cleanly** — Always run `done` command when finished
9. **Track action count** — Monitor progress against the 100 action limit
10. **Handle keyboard** — Dismiss by tapping non-interactive labels
11. **Retry with alternatives** — Use `--target-type any` if specific type fails
12. **Build before test** — Always `build-for-testing` first to avoid hangs
13. **Hierarchy is large (1500+ lines)** — Use Grep to search for specific identifiers rather than reading the entire file linearly
14. **Re-set CLI/CT vars every command** — Shell state doesn't persist between Bash tool calls. The first invocation per session triggers a build; subsequent calls are instant.
15. **Scroll with a target** — When scrolling lists, use `--target <listIdentifier> --target-type any` rather than scrolling the app itself
16. **Improve the shared package** — When you discover issues or missing features in xcode-sim-automation, edit the package directly and commit
