# XCUITestControl

A Swift package that provides file-based interactive control of iOS apps through XCUITest. Designed for AI agents (like Claude) to drive UI interactions via a simple JSON protocol.

## How It Works

```
Claude (AI) → CLI → JSON file → XCUITest polling loop → iOS app
```

1. The XCUITest polling loop runs inside your app's UI test target, watching a JSON command file
2. A CLI writes commands to that file and polls for results
3. After each action, the loop writes back a UI hierarchy snapshot and screenshot
4. The AI agent reads those artifacts, decides the next action, and repeats

## Installation

Add the package to your project via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/gestrich/xcode-sim-automation.git", from: "1.0.0")
]
```

Then add `XCUITestControl` to your UI test target's dependencies:

```swift
.testTarget(
    name: "MyAppUITests",
    dependencies: [
        .product(name: "XCUITestControl", package: "xcode-sim-automation")
    ]
)
```

## Quick Start

Create a UI test that launches the control loop:

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

Run the test:

```bash
xcodebuild test \
    -workspace MyApp.xcworkspace \
    -scheme MyAppUITests \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:MyAppUITests/InteractiveControlTests/testInteractiveControl
```

Once the test is running, use the CLI to send commands:

```bash
Tools/xcuitest-control screenshot
Tools/xcuitest-control tap --target "Login"
Tools/xcuitest-control type --value "user@example.com" --target "Email"
Tools/xcuitest-control done
```

The wrapper script auto-builds the Swift CLI binary on first run and whenever source files change. A Python fallback (`Tools/xcuitest-control.py`) is also available.

## Configuration

`InteractiveControlLoop` accepts a `Configuration` struct with these properties:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `commandPath` | `String` | `/tmp/xcuitest-command.json` | Path to the JSON command file |
| `hierarchyPath` | `String` | `/tmp/xcuitest-hierarchy.txt` | Path where UI hierarchy is written |
| `screenshotPath` | `String` | `/tmp/xcuitest-screenshot.png` | Path where screenshots are written |
| `pollingInterval` | `TimeInterval` | `0.5` | Seconds between command file polls |
| `sessionTimeout` | `TimeInterval` | `300` | Seconds before the loop exits if no commands arrive |
| `elementWaitTimeout` | `TimeInterval` | `10` | Seconds to wait for an element to appear |
| `tapRetryCount` | `Int` | `3` | Number of tap attempts before failing |
| `tapRetryDelay` | `TimeInterval` | `0.5` | Seconds between tap retries |

Example with custom configuration:

```swift
let config = InteractiveControlLoop.Configuration(
    sessionTimeout: 600,
    tapRetryCount: 5
)
InteractiveControlLoop(configuration: config).run(app: app)
```

## CLI

The CLI wrapper lives at `Tools/xcuitest-control`. Clone this repo to get it:

```bash
git clone https://github.com/gestrich/xcode-sim-automation.git
xcode-sim-automation/Tools/xcuitest-control --help
```

### Commands

| Command | Description | Example |
|---------|-------------|---------|
| `tap` | Tap an element by identifier | `tap --target "Submit" --target-type button` |
| `scroll` | Scroll in a direction | `scroll --direction down --target "tableView"` |
| `type` | Type text into a field | `type --value "hello" --target "searchField"` |
| `adjust` | Set a slider value (0.0–1.0) | `adjust --target "volume" --value 0.75` |
| `pinch` | Pinch to zoom | `pinch --scale 2.0 --velocity 1.0` |
| `wait` | Pause for a duration | `wait --value 2.0` |
| `screenshot` | Capture screenshot and hierarchy | `screenshot` |
| `done` | Exit the test loop | `done` |
| `status` | Check current command status | `status` |

### Environment Variables

Override default file paths by setting these before running the CLI:

| Variable | Default |
|----------|---------|
| `XCUITEST_COMMAND_PATH` | `/tmp/xcuitest-command.json` |
| `XCUITEST_HIERARCHY_PATH` | `/tmp/xcuitest-hierarchy.txt` |
| `XCUITEST_SCREENSHOT_PATH` | `/tmp/xcuitest-screenshot.png` |

## Protocol Reference

Commands are exchanged as JSON through the command file. The polling loop reads commands and writes results back to the same file.

### Command Schema

```json
{
    "action": "tap | scroll | type | wait | screenshot | adjust | pinch | done",
    "target": "element identifier (optional)",
    "targetType": "button | staticText | cell | textField | slider | any (optional)",
    "index": 0,
    "value": "text to type or slider value (optional)",
    "direction": "up | down | left | right (optional)",
    "scale": "pinch scale factor (optional)",
    "velocity": "pinch velocity (optional)",
    "status": "pending | executing | completed | error",
    "errorMessage": "error description (set on failure)",
    "info": "additional result info (set on success)"
}
```

### Lifecycle

1. CLI writes a command with `"status": "pending"`
2. Polling loop picks it up, sets status to `"executing"`
3. Loop performs the action, writes hierarchy + screenshot, sets status to `"completed"` or `"error"`
4. CLI polls until it sees a terminal status, then prints the result

### Element Lookup

When `target` is provided, the loop searches across element types in this order: **button → staticText → textField → cell → slider → any descendants**. If `targetType` is specified, only that type is searched.

When multiple elements match, the `index` field (0-based) selects which one. If omitted, the first match is used. The result `info` field reports the total match count.

## Claude Skills

This repo includes two Claude Code skills in `.claude/skills/`:

- **`interactive-xcuitest`** — Protocol for AI-driven interactive UI exploration
- **`creating-automated-screenshots`** — Protocol for AI-driven automated screenshot capture

Copy the `.claude/skills/` directory into your project to make them available to Claude Code.

## License

MIT
