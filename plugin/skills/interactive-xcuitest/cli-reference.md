# CLI Commands Reference

The `xcuitest-control` wrapper script provides a command-line interface for controlling XCUITest. It auto-builds the Swift CLI binary on first run and whenever source files change. Always use `--container` (`-c`) to set the sandbox paths.

## Quick Reference

```bash
$CLI -c "$CT" tap --target submitButton --target-type button
$CLI -c "$CT" scroll --direction down --target listView --target-type any
$CLI -c "$CT" type --value "Hello World"
$CLI -c "$CT" adjust --target volumeSlider --value 0.75
$CLI -c "$CT" pinch --scale 2.0 --target imageView
$CLI -c "$CT" wait --value 2.0
$CLI -c "$CT" screenshot
$CLI -c "$CT" status
$CLI -c "$CT" activate
$CLI -c "$CT" reset
$CLI -c "$CT" ready --timeout 30
$CLI -c "$CT" done
```

## CLI Output

Each command returns JSON with paths to the latest hierarchy and screenshot:

```json
{
  "status": "completed",
  "hierarchy": "<container>/xcuitest-hierarchy.txt",
  "screenshot": "<container>/xcuitest-screenshot.png"
}
```

On error:
```json
{
  "status": "error",
  "error": "Element 'missingButton' not found after waiting 10 seconds",
  "hierarchy": "<container>/xcuitest-hierarchy.txt",
  "screenshot": "<container>/xcuitest-screenshot.png"
}
```

## Commands

### tap

Taps an element by identifier.

```bash
$CLI tap --target submitButton --target-type button
$CLI tap -t submitButton -T button
$CLI tap --target Edit --target-type button --index 0
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
$CLI scroll --direction down   # Scroll down to see more content below
$CLI scroll -d up --target scrollView  # Scroll up to see content above
```

Options:
- `--direction, -d` (required): `up`, `down`, `left`, or `right` - the direction to scroll content
- `--target, -t` (optional): Element to scroll. If omitted, scrolls the app.

### type

Types text into a text field.

```bash
$CLI type --value "test@example.com"
$CLI type -V "Hello" --target usernameField
```

Options:
- `--value, -V` (required): Text to type
- `--target, -t` (optional): Text field to type into. If omitted, types into currently focused field.

### adjust

Adjusts a slider to a normalized position (0.0 to 1.0).

```bash
$CLI adjust --target volumeSlider --value 0.75
$CLI adjust -t volumeSlider -V 0.5
```

Options:
- `--target, -t` (required): Accessibility identifier of the slider
- `--value, -V` (required): Normalized position between 0.0 (minimum) and 1.0 (maximum)

Examples:
- `--value 0.0` - Move slider to minimum (left)
- `--value 0.5` - Move slider to middle
- `--value 1.0` - Move slider to maximum (right)

### pinch

Pinches to zoom in or out on an element (iOS only — not available on macOS).

```bash
$CLI pinch --scale 2.0 --target imageView
$CLI pinch -s 0.5 -V 2.0
```

Options:
- `--scale, -s` (required): Scale factor (`< 1.0` = zoom out, `> 1.0` = zoom in)
- `--velocity, -V` (optional): Speed in scale factor per second (default: 1.0)
- `--target, -t` (optional): Element to pinch. If omitted, pinches the app.

### wait

Pauses for a specified duration.

```bash
$CLI wait --value 2.0
$CLI wait  # defaults to 1.0 second
```

Options:
- `--value, -V` (optional): Seconds to wait. Defaults to 1.0.

### screenshot

Captures current state without performing any action.

```bash
$CLI screenshot
```

### status

Checks current command status without executing.

```bash
$CLI status
```

### activate

Brings the app to the foreground. **Always call this after starting the test** — if the app window is behind other windows, scroll/tap actions will fail with "Unable to find hit point".

```bash
$CLI -c "$CT" activate
```

### reset

Cleans protocol files for a fresh session. Use before starting a new test.

```bash
$CLI -c "$CT" reset
```

### ready

Checks if XCUITest is running and ready for commands. With `--timeout`, polls until ready or timeout expires.

```bash
$CLI -c "$CT" ready                  # Instant check
$CLI -c "$CT" ready --timeout 30     # Wait up to 30 seconds
```

Options:
- `--timeout, -t` (optional): Seconds to wait for ready state. Defaults to 0 (instant check).

### done

Exits the test loop.

```bash
$CLI -c "$CT" done
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
  "hierarchy": "...",
  "screenshot": "..."
}
```

### Error Response for Ambiguous Elements

When multiple elements match but none are hittable:

```json
{
  "status": "error",
  "error": "Found 5 elements matching 'Edit', none were hittable. Specify --index 0 to 4 to select a specific element.",
  "hierarchy": "...",
  "screenshot": "..."
}
```

### Index Out of Range

When the specified index exceeds available matches:

```json
{
  "status": "error",
  "error": "Index 10 out of range. Found 5 'Edit' element(s). Use --index 0 to 4.",
  "hierarchy": "...",
  "screenshot": "..."
}
```

### Best Practices

1. **Check the hierarchy first** to see how many matching elements exist
2. **Use `--index` when you know which element** you want (e.g., the second Edit button)
3. **Let the framework auto-select** when you want any visible/hittable match
4. **Review the `info` field** to verify which element was tapped

## File-Based Protocol (Advanced)

For direct JSON manipulation, the CLI uses these files (within the container directory):

| File | Purpose |
|------|---------|
| `xcuitest-command.json` | Commands from Claude → XCUITest |
| `xcuitest-hierarchy.txt` | UI hierarchy from XCUITest → Claude |
| `xcuitest-screenshot.png` | Screenshot from XCUITest → Claude |

### Command JSON Schema

```json
{
  "action": "tap" | "scroll" | "type" | "wait" | "screenshot" | "adjust" | "activate" | "pinch" | "done",
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

## Environment Variable Overrides

The CLI supports environment variable overrides for file paths:

| Variable | Default | Description |
|----------|---------|-------------|
| `XCUITEST_COMMAND_PATH` | `/tmp/xcuitest-command.json` | Path to command JSON file |
| `XCUITEST_HIERARCHY_PATH` | `/tmp/xcuitest-hierarchy.txt` | Path to hierarchy output |
| `XCUITEST_SCREENSHOT_PATH` | `/tmp/xcuitest-screenshot.png` | Path to screenshot output |

The `--container` flag is preferred over env vars as it sets all three paths at once.

When using custom paths, also configure the Swift `InteractiveControlLoop.Configuration` to match:

```swift
let config = InteractiveControlLoop.Configuration(
    commandPath: "/custom/path/command.json",
    hierarchyPath: "/custom/path/hierarchy.txt",
    screenshotPath: "/custom/path/screenshot.png"
)
InteractiveControlLoop(configuration: config).run(app: app)
```
