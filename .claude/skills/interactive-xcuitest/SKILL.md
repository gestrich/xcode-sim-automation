---
name: interactive-xcuitest
description: Interactively controls XCUITest through a CLI. Claude reads UI state and screenshots, decides actions, and executes commands via the CLI. Use for dynamic UI exploration, complex navigation flows, or when pre-scripted navigation isn't feasible.
user-invocable: true
---

# Interactive XCUITest Control

Enables Claude to dynamically control an iOS app through XCUITest using a CLI that abstracts the file-based protocol. Unlike pre-scripted tests, this allows Claude to explore the UI, make decisions based on current state, and recover from unexpected situations.

## Usage

Invoke this skill when you need to:
- Navigate complex UI flows without knowing the exact path ahead of time
- Explore an app's UI to understand its structure
- Perform multi-step interactions that depend on dynamic content
- Test error recovery and edge cases interactively
- Take screenshots of specific views found through exploration

The skill will ask for your goal if not specified (e.g., "Navigate to Settings and enable Dark Mode").

## Prerequisites

### 1. Add the XCUITestControl Swift Package

Add the package to your project via SPM:

```swift
// In Package.swift or via Xcode:
.package(url: "https://github.com/gestrich/xcode-sim-automation.git", from: "1.0.0")
```

### 2. Create an Interactive Control Test

Create a UI test in your project's UI test target:

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

### 3. Get the CLI

Clone the xcode-sim-automation repo to get the CLI tool:

```bash
git clone https://github.com/gestrich/xcode-sim-automation.git
```

The CLI is the wrapper script at `Tools/xcuitest-control` within the cloned repo. It auto-builds the Swift CLI binary on first run and whenever source files change — no manual build step needed.

A Python fallback (`Tools/xcuitest-control.py`) is also available if the Swift toolchain isn't installed.

## CLI

The `Tools/xcuitest-control` script provides a simple interface for controlling XCUITest. It accepts the same flags as the Python CLI:

```bash
# Tap a button
Tools/xcuitest-control tap --target submitButton --target-type button

# Scroll down
Tools/xcuitest-control scroll --direction down

# Type text
Tools/xcuitest-control type --value "Hello World"

# Adjust a slider to 75%
Tools/xcuitest-control adjust --target volumeSlider --value 0.75

# Pinch to zoom in (scale > 1.0)
Tools/xcuitest-control pinch --scale 2.0 --target imageView

# Wait 2 seconds
Tools/xcuitest-control wait --value 2.0

# Take screenshot
Tools/xcuitest-control screenshot

# Check status
Tools/xcuitest-control status

# Exit the test
Tools/xcuitest-control done
```

### CLI Output

Each command returns JSON with paths to the latest hierarchy and screenshot:

```json
{
  "status": "completed",
  "hierarchy": "/tmp/xcuitest-hierarchy.txt",
  "screenshot": "/tmp/xcuitest-screenshot.png"
}
```

On error:
```json
{
  "status": "error",
  "error": "Element 'missingButton' not found after waiting 10 seconds",
  "hierarchy": "/tmp/xcuitest-hierarchy.txt",
  "screenshot": "/tmp/xcuitest-screenshot.png"
}
```

## Workflow

### 1. Start the XCUITest

Run the interactive control test using `xcodebuild`:

```bash
xcodebuild test \
  -workspace YourApp.xcworkspace \
  -scheme "YourUITestScheme" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:"YourUITestTarget/InteractiveControlTests/testInteractiveControl" &
```

Replace `YourApp.xcworkspace`, `YourUITestScheme`, and `YourUITestTarget` with your project's values.

The test will:
- Launch the app
- Write initial hierarchy and screenshot
- Begin polling for commands

### 2. Wait for Test Initialization

Poll until the hierarchy file exists:

```bash
while [ ! -f /tmp/xcuitest-hierarchy.txt ]; do sleep 1; done
```

Or use the status command:
```bash
Tools/xcuitest-control status
```

### 3. Execute Commands

Use the CLI to execute actions:

```bash
# Read current UI state
cat /tmp/xcuitest-hierarchy.txt

# View screenshot
# Read file: /tmp/xcuitest-screenshot.png

# Execute action
Tools/xcuitest-control tap --target settingsButton --target-type button

# View updated screenshot after action
# Read file: /tmp/xcuitest-screenshot.png
```

### 4. Exit Gracefully

When the goal is achieved:

```bash
Tools/xcuitest-control done
```

## CLI Commands Reference

### tap
Taps an element by identifier.

```bash
Tools/xcuitest-control tap --target submitButton --target-type button
Tools/xcuitest-control tap -t submitButton -T button
Tools/xcuitest-control tap --target Edit --target-type button --index 0
```

Options:
- `--target, -t` (required): Accessibility identifier of the element
- `--target-type, -T` (optional): Element type - `button`, `staticText`, `cell`, `textField`, `slider`, or `any`
- `--index, -i` (optional): 0-based index when multiple elements match. If omitted, taps the first hittable element.

### scroll
Scrolls content in a direction (reveals content in that direction).

**Important**: The direction specifies where you want to scroll TO (what content to reveal), not the swipe gesture direction:
- `--direction down` = reveal content below (internally swipes up)
- `--direction up` = reveal content above (internally swipes down)
- `--direction left` = reveal content to the left (internally swipes right)
- `--direction right` = reveal content to the right (internally swipes left)

```bash
Tools/xcuitest-control scroll --direction down   # Scroll down to see more content below
Tools/xcuitest-control scroll -d up --target scrollView  # Scroll up to see content above
```

Options:
- `--direction, -d` (required): `up`, `down`, `left`, or `right` - the direction to scroll content
- `--target, -t` (optional): Element to scroll. If omitted, scrolls the app.

### type
Types text into a text field.

```bash
Tools/xcuitest-control type --value "test@example.com"
Tools/xcuitest-control type -V "Hello" --target usernameField
```

Options:
- `--value, -V` (required): Text to type
- `--target, -t` (optional): Text field to type into. If omitted, types into currently focused field.

### adjust
Adjusts a slider to a normalized position (0.0 to 1.0).

```bash
Tools/xcuitest-control adjust --target volumeSlider --value 0.75
Tools/xcuitest-control adjust -t volumeSlider -V 0.5
```

Options:
- `--target, -t` (required): Accessibility identifier of the slider
- `--value, -V` (required): Normalized position between 0.0 (minimum) and 1.0 (maximum)

Examples:
- `--value 0.0` - Move slider to minimum (left)
- `--value 0.5` - Move slider to middle
- `--value 1.0` - Move slider to maximum (right)

### pinch
Pinches to zoom in or out on an element.

```bash
Tools/xcuitest-control pinch --scale 2.0 --target imageView
Tools/xcuitest-control pinch -s 0.5 -V 2.0
```

Options:
- `--scale, -s` (required): Scale factor
  - `< 1.0` = pinch in (zoom out)
  - `> 1.0` = pinch out (zoom in)
- `--velocity, -V` (optional): Speed in scale factor per second (default: 1.0)
- `--target, -t` (optional): Element to pinch. If omitted, pinches the app.

Examples:
- `--scale 2.0` - Zoom in 2x
- `--scale 0.5` - Zoom out to 50%
- `--scale 1.5 --velocity 0.5` - Slow zoom in

### wait
Pauses for a specified duration.

```bash
Tools/xcuitest-control wait --value 2.0
Tools/xcuitest-control wait  # defaults to 1.0 second
```

Options:
- `--value, -V` (optional): Seconds to wait. Defaults to 1.0.

### screenshot
Captures current state without performing any action.

```bash
Tools/xcuitest-control screenshot
```

### status
Checks current command status without executing.

```bash
Tools/xcuitest-control status
```

### done
Exits the test loop.

```bash
Tools/xcuitest-control done
```

## Handling Multiple Matches

When multiple elements share the same identifier (e.g., multiple "Edit" buttons in a list), the tap command:

1. **Without `--index`**: Automatically finds and taps the first hittable element
2. **With `--index N`**: Taps the element at the specified 0-based index

### Success Response with Multiple Matches

When a tap succeeds on one of multiple matches, the response includes info:

```json
{
  "status": "completed",
  "info": "Tapped button at index 0 of 5 matches",
  "hierarchy": "/tmp/xcuitest-hierarchy.txt",
  "screenshot": "/tmp/xcuitest-screenshot.png"
}
```

### Error Response for Ambiguous Elements

When multiple elements match but none are hittable:

```json
{
  "status": "error",
  "error": "Found 5 elements matching 'Edit', none were hittable. Specify --index 0 to 4 to select a specific element.",
  "hierarchy": "/tmp/xcuitest-hierarchy.txt",
  "screenshot": "/tmp/xcuitest-screenshot.png"
}
```

### Index Out of Range

When the specified index exceeds available matches:

```json
{
  "status": "error",
  "error": "Index 10 out of range. Found 5 'Edit' element(s). Use --index 0 to 4.",
  "hierarchy": "/tmp/xcuitest-hierarchy.txt",
  "screenshot": "/tmp/xcuitest-screenshot.png"
}
```

### Best Practices

1. **Check the hierarchy first** to see how many matching elements exist
2. **Use `--index` when you know which element** you want (e.g., the second Edit button)
3. **Let the framework auto-select** when you want any visible/hittable match
4. **Review the `info` field** to verify which element was tapped

## Keyboard Handling

When interacting with text fields, the keyboard will appear and may block other UI elements.

### Dismissing the Keyboard

Tap on a non-interactive element that's visible above the keyboard:

```bash
Tools/xcuitest-control tap --target notesLabel --target-type staticText
```

**Tips for dismissing the keyboard:**
- Look in the hierarchy for `StaticText` elements (labels) that are above the keyboard
- Navigation bar titles work well as tap targets
- Section headers or form labels are good choices
- Avoid tapping on text fields, text views, or other interactive elements

### Typing Text

1. **Tap the text field first** to focus it:
   ```bash
   Tools/xcuitest-control tap --target searchBar --target-type any
   ```

2. **Then type your text**:
   ```bash
   Tools/xcuitest-control type --value "Hello"
   ```

### Common Keyboard Issues

| Issue | Solution |
|-------|----------|
| Keyboard blocking elements | Tap a non-interactive label above the keyboard to dismiss |
| Element not hittable | The element may be behind the keyboard - dismiss keyboard first |
| Can't scroll | Keyboard may be intercepting gestures - dismiss it first |
| Text not appearing | Ensure the text field was tapped/focused before typing |

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

Use `--target-type any` if unsure - it searches all element types.

## Error Handling and Recovery

### Robustness Configuration

The skill enforces several limits to prevent runaway behavior:

| Setting | Value | Purpose |
|---------|-------|---------|
| Maximum actions | 100 | Prevents infinite loops |
| Command timeout | 5 minutes | XCUITest exits if no commands received |
| Element timeout | 10 seconds | Actions fail gracefully if element not found |
| Tap retry count | 3 | Retries if element exists but not hittable |

### Command Errors

On error, the CLI returns:
```json
{
  "status": "error",
  "error": "Element 'missingButton' not found after waiting 10 seconds",
  "hierarchy": "/tmp/xcuitest-hierarchy.txt",
  "screenshot": "/tmp/xcuitest-screenshot.png"
}
```

When this happens:
1. Read the hierarchy to find the correct element
2. Try alternative identifiers or element types
3. Consider if navigation went to an unexpected view
4. Check if the element needs to be scrolled into view

### Common Errors

| Error | Solution |
|-------|----------|
| Element not found | Check hierarchy for correct identifier, try `--target-type any` |
| Element not hittable | Wait for animations, scroll element into view, retry |
| Multiple matches, none hittable | Use `--index` to select specific element, or scroll to reveal hittable ones |
| Index out of range | Check hierarchy to count matches, use valid index (0 to N-1) |
| Wrong element type | Use `--target-type any` or check hierarchy for actual type |
| Action limit reached | Break goal into smaller steps, restart skill |
| Test timeout | XCUITest exited due to 5 min inactivity, restart test |

## Example Session

**Goal**: Navigate to the Settings view and explore

```bash
# 1. Start the test
xcodebuild test \
  -workspace YourApp.xcworkspace \
  -scheme "YourUITestScheme" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:"YourUITestTarget/InteractiveControlTests/testInteractiveControl" &

# 2. Wait for initialization
while [ ! -f /tmp/xcuitest-hierarchy.txt ]; do sleep 1; done

# 3. Read initial state
cat /tmp/xcuitest-hierarchy.txt

# 4. Read the screenshot to see the current view
# Use the Read tool on /tmp/xcuitest-screenshot.png

# 5. Tap an element based on what you see
Tools/xcuitest-control tap --target someButton --target-type button

# 6. Read updated hierarchy and screenshot
cat /tmp/xcuitest-hierarchy.txt

# 7. Exit when done
Tools/xcuitest-control done
```

## Environment Variable Overrides

The CLI supports environment variable overrides for file paths:

| Variable | Default | Description |
|----------|---------|-------------|
| `XCUITEST_COMMAND_PATH` | `/tmp/xcuitest-command.json` | Path to command JSON file |
| `XCUITEST_HIERARCHY_PATH` | `/tmp/xcuitest-hierarchy.txt` | Path to hierarchy output |
| `XCUITEST_SCREENSHOT_PATH` | `/tmp/xcuitest-screenshot.png` | Path to screenshot output |

When using custom paths, also configure the Swift `InteractiveControlLoop.Configuration` to match:

```swift
let config = InteractiveControlLoop.Configuration(
    commandPath: "/custom/path/command.json",
    hierarchyPath: "/custom/path/hierarchy.txt",
    screenshotPath: "/custom/path/screenshot.png"
)
InteractiveControlLoop(configuration: config).run(app: app)
```

## File-Based Protocol (Advanced)

For direct JSON manipulation, the CLI uses these files:

| File | Purpose |
|------|---------|
| `/tmp/xcuitest-command.json` | Commands from Claude → XCUITest |
| `/tmp/xcuitest-hierarchy.txt` | UI hierarchy from XCUITest → Claude |
| `/tmp/xcuitest-screenshot.png` | Screenshot from XCUITest → Claude |

### Command JSON Schema

```json
{
  "action": "tap" | "scroll" | "type" | "wait" | "screenshot" | "adjust" | "pinch" | "done",
  "target": "elementIdentifier",
  "targetType": "button" | "staticText" | "cell" | "textField" | "slider" | "any",
  "index": 0,
  "value": "text to type (for type) or 0.0-1.0 (for adjust)",
  "direction": "up" | "down" | "left" | "right",
  "scale": "pinch scale factor (< 1.0 = zoom out, > 1.0 = zoom in)",
  "velocity": "pinch speed in scale factor per second",
  "status": "pending" | "executing" | "completed" | "error",
  "errorMessage": "optional error description",
  "info": "optional diagnostic info (e.g., which index was tapped)"
}
```

## Tips for Effective Control

1. **Always read hierarchy first** - Don't guess element identifiers
2. **Use specific target-type** - Faster and more reliable than `any`
3. **Handle errors gracefully** - Read hierarchy after errors to adapt
4. **Wait after animations** - Use the `wait` command if UI is animating
5. **Take screenshots often** - Helps verify you're on the expected view
6. **Exit cleanly** - Always run `done` command when finished
7. **Track action count** - Monitor progress against the 100 action limit
8. **Handle keyboard** - Dismiss by tapping non-interactive labels
9. **Retry with alternatives** - Use `--target-type any` if specific type fails
