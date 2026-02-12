---
name: creating-automated-screenshots
description: Creates automated UI test for a view, runs it, and captures screenshots to ~/Downloads. Use when the user asks to create screenshots, capture UI images, test view rendering, or generate visual documentation for a view.
user-invocable: true
---

# Automated Screenshot Creator

Creates a UI automation test for a specific view, executes the test, and extracts screenshots. This skill automates the entire workflow from test creation to screenshot extraction.

## Usage

Invoke this skill when you need to:
- Generate screenshots of a specific view for documentation or review
- Create automated visual tests for a new or modified view
- Capture the current state of a UI component

The skill will ask you which view to screenshot if you don't specify one.

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

## Prerequisites

### 1. Add the XCUITestControl Swift Package

Add the package to your project via SPM:

```swift
// In Package.swift or via Xcode:
.package(url: "https://github.com/gestrich/xcode-sim-automation.git", from: "1.0.0")
```

### 2. Get the CLI

The CLI wrapper script (`Tools/xcuitest-control`) is in the xcode-sim-automation repo. To find it:

1. Search for the repo's `Tools/xcuitest-control` wrapper script (not the `.py` file)
2. Common locations: `~/Developer/personal/xcode-sim-automation/Tools/xcuitest-control`
3. If not found, clone the repo: `git clone https://github.com/gestrich/xcode-sim-automation.git`

The wrapper auto-builds the Swift CLI binary on first run and whenever source files change — no manual build step needed.

A Python fallback (`Tools/xcuitest-control.py`) is also available if the Swift toolchain isn't installed.

## Workflow

The skill executes these steps automatically:

### 1. Create UI Test File

Creates a new Swift test file in the UI test target (`$UI_TEST_TARGET`) that:
- Inherits from `XCTestCase`
- Navigates to the target view
- Takes a screenshot using `XCTAttachment`

**Test file naming**: `ScreenshotTest_<ViewName>.swift`

Example test structure:
```swift
import XCTest

final class ScreenshotTest_MyFeature: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Helpers

    /// Captures UI hierarchy at current state for debugging
    func captureHierarchy(name: String) {
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "\(name).txt"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }

    /// Finds a tappable element by trying Button, StaticText, then Cell
    func findTappable(_ identifier: String) -> XCUIElement {
        let button = app.buttons[identifier]
        if button.waitForExistence(timeout: 2.0) { return button }

        let staticText = app.staticTexts[identifier]
        if staticText.waitForExistence(timeout: 2.0) { return staticText }

        let cell = app.cells[identifier]
        if cell.waitForExistence(timeout: 2.0) { return cell }

        return button // Fallback - assertion will fail with clear message
    }

    // MARK: - Test

    func testMyFeatureScreenshot() throws {
        // Step 1: Navigate to first view
        let someTab = app.buttons["SomeTab"]
        XCTAssertTrue(someTab.waitForExistence(timeout: 10.0), "SomeTab should exist")
        someTab.tap()
        sleep(2)
        captureHierarchy(name: "Step1-AfterSomeTab")

        // Step 2: Navigate deeper - try both Button and StaticText
        let targetElement = findTappable("TargetView")
        XCTAssertTrue(targetElement.exists, "TargetView should exist")
        targetElement.tap()
        sleep(2)
        captureHierarchy(name: "Step2-AfterTargetView")

        // Verify we reached the correct view before taking screenshot
        let viewIdentifier = app.staticTexts["ExpectedViewTitle"]
        XCTAssertTrue(viewIdentifier.waitForExistence(timeout: 5.0), "Should be on MyFeature view")

        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "MyFeature"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Final hierarchy capture
        captureHierarchy(name: "Final-MyFeatureView")
    }
}
```

See [test-patterns.md](test-patterns.md) for detailed helper functions and navigation patterns.

### 2. Build and Run the Test

Always build first (catches errors without hanging), then run the specific test:

```bash
# Step 1: Build (catches errors without hanging)
xcodebuild build-for-testing \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination '$DESTINATION'

# Step 2: Run the specific test
xcodebuild test \
  -project $PROJECT \
  -scheme $SCHEME \
  -destination '$DESTINATION' \
  -only-testing:"$UI_TEST_TARGET/ScreenshotTest_MyFeature/testMyFeatureScreenshot"
```

**macOS note**: No simulator is needed — the app runs natively. Always kill stale processes first:
```bash
pkill -f "$PROCESS_NAME" 2>/dev/null; sleep 2
```

### 3. Extract Screenshots and Debug Info

Extract screenshots from the `.xcresult` bundle:

```bash
# Find the latest xcresult
RESULT_BUNDLE=$(ls -td ~/Library/Developer/Xcode/DerivedData/*/Logs/Test/*.xcresult | head -1)

# Extract attachments
xcrun xcresulttool get --path "$RESULT_BUNDLE" --list
```

**Extracted files include**:
- Screenshot images (PNG format)
- Hierarchy text files from `captureHierarchy` calls
- Any other test attachments

## App-Specific Setup

### Login and Authentication

If your app requires login, handle it in your test's `setUp` method or as the first navigation step. Common patterns:

```swift
// Option 1: Launch argument to bypass login
app.launchArguments = ["--skip-login"]
app.launch()

// Option 2: Navigate through login UI
app.launch()
let usernameField = app.textFields["username"]
usernameField.tap()
usernameField.typeText("testuser")
// ...continue login flow
```

### Credentials

If your tests need credentials, consider:
- Launch arguments or environment variables
- A test-specific configuration file
- Hard-coded test account credentials (for CI only)

## Additional Reference

- [Test Patterns](test-patterns.md) — Helper functions, navigation patterns, assertions, build-first pattern
- [Element Discovery](element-discovery.md) — Element types vs visual appearance, hierarchy reading, iterative debugging

## macOS-Specific Notes

- **No simulator needed**: The app runs natively on macOS. Use `-destination 'platform=macOS'`.
- **Sandbox**: Xcode always sandboxes the XCUITest runner on macOS. The runner cannot write to `/tmp/`.
- **Kill stale processes**: Always `pkill -f "$PROCESS_NAME"` before running tests — stale app processes cause "Failed to terminate" errors.
- **Window visibility**: The app window must be visible (not minimized or fully occluded) for screenshots and interactions to work.
- **Window focus**: macOS windows can be behind other windows. If interactions fail, ensure the app window is frontmost.
- **Pinch not available**: The `pinch` command is iOS-only and will not work on macOS.

## Example Usage

**User request**: "Create a screenshot test for the SettingsView"

**Skill will**:
1. Read `.xcuitest-config.json` for project configuration
2. Read `appSpecificNotes` file for navigation patterns (if configured)
3. Ask for navigation details (if not obvious from the app-specific notes)
4. Create `ScreenshotTest_Settings.swift` in the UI test target (includes hierarchy capture)
5. Build and run the test
6. Extract screenshots from the xcresult bundle
7. Report the output location

**If navigation fails**: Check hierarchy attachments to find correct element identifiers, then update the test with proper accessibility IDs.

## Error Handling

Common issues:

- **Test passes but screenshot shows wrong view**: Navigation failed silently because `if` statements were used instead of `XCTAssertTrue`. Always use assertions for every navigation step.
- **Element not found but it's clearly visible**: You're using the wrong element type. `app.buttons["Item"]` won't find a StaticText. Check the UI hierarchy to find the actual element type, or use the `findTappable` helper.
- **Test fails to find view**: Check hierarchy attachments to see available accessibility IDs and element structure.
- **Build hangs during test**: Always run `xcodebuild build-for-testing` as a separate step before `xcodebuild test`.
- **Navigation element not found**: Review the captured UI hierarchy to find the correct element identifier or query.
- **Window not visible**: On macOS, the app window must not be minimized. Ensure it's visible before running tests.
