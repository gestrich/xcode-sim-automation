---
name: creating-automated-screenshots
description: Creates automated UI test for a view, runs it, and captures screenshots to ~/Downloads. Use when the user asks to create screenshots, capture UI images, test view rendering, or generate visual documentation for a ViewController or SwiftUI view.
user-invocable: true
---

# Automated Screenshot Creator

Creates a UI automation test for a specific ViewController or SwiftUI view, executes the test, and extracts screenshots. This skill automates the entire workflow from test creation to screenshot extraction.

## Usage

Invoke this skill when you need to:
- Generate screenshots of a specific view for documentation or review
- Create automated visual tests for a new or modified view
- Capture the current state of a UI component

The skill will ask you which view to screenshot if you don't specify one.

## Prerequisites

### 1. Add the XCUITestControl Swift Package

Add the package to your project via SPM:

```swift
// In Package.swift or via Xcode:
.package(url: "https://github.com/gestrich/xcode-sim-automation.git", from: "1.0.0")
```

### 2. Get the CLI

Clone the xcode-sim-automation repo to get the CLI tool:

```bash
git clone https://github.com/gestrich/xcode-sim-automation.git
```

The CLI is the wrapper script at `Tools/xcuitest-control` within the cloned repo. It auto-builds the Swift CLI binary on first run and whenever source files change — no manual build step needed.

A Python fallback (`Tools/xcuitest-control.py`) is also available if the Swift toolchain isn't installed.

## Workflow

The skill executes these steps automatically:

### 1. Create UI Test File

Creates a new Swift test file in your project's UI test target that:
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

**Key patterns:**
- `captureHierarchy(name:)` saves the UI state at each step for debugging
- `findTappable(_:)` tries Button → StaticText → Cell automatically
- Each navigation step captures the hierarchy, so if step 3 fails, you have step 1 and 2 hierarchies to analyze

### 2. Build and Run the Test

Run the specific test using `xcodebuild`:

```bash
xcodebuild test \
  -workspace YourApp.xcworkspace \
  -scheme "YourUITestScheme" \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:"YourUITestTarget/ScreenshotTest_MyFeature/testMyFeatureScreenshot"
```

Replace `YourApp.xcworkspace`, `YourUITestScheme`, and `YourUITestTarget` with your project's values.

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

If your app requires login, handle it in your test's `setUp` method or as the first navigation step. This is app-specific — common patterns:

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

## Element Type Discovery

### CRITICAL: Element Types Don't Match Visual Appearance

XCUITest queries are **type-specific**. This means:
- `app.buttons["FBOs"]` will **NOT** find a StaticText labeled "FBOs"
- `app.staticTexts["Settings"]` will **NOT** find a Button labeled "Settings"

Even though both elements might look identical and be tappable, you **must** use the correct element type in your query.

### Common Misconceptions

| Visual Appearance | Common Assumption | Actual Type (Often) |
|-------------------|-------------------|---------------------|
| Tappable link text | Button | **StaticText** |
| Quick action in a list | Button | **StaticText** inside Other |
| Menu item in table | Button | **Cell** or **StaticText** |
| Segmented control item | Button | **Button** (correct) |
| Tab bar item | Button | **Button** (usually correct) |
| Icon that opens something | Button | **Image** or **Button** |

### Try Multiple Element Types

Instead of guessing, try both common types. Use a short timeout for the first attempt:

```swift
// Try as Button first (short timeout), then StaticText
var element = app.buttons["MyElement"]
if !element.waitForExistence(timeout: 2.0) {
    element = app.staticTexts["MyElement"]
}
XCTAssertTrue(element.waitForExistence(timeout: 5.0), "MyElement should exist (as Button or StaticText)")
element.tap()
```

Or use the `findTappable` helper shown in the test template above.

### Reading the UI Hierarchy

The hierarchy shows element types explicitly:
```
Other, identifier: 'QuickActions'
  ↳ StaticText, label: 'Action1'        ← This is a StaticText, NOT a Button!
  ↳ StaticText, label: 'Action2'
Button, identifier: 'MainButton', label: 'MainButton'  ← This IS a Button
```

From this you can determine:
- "Action1" is a **StaticText** → use `app.staticTexts["Action1"]`
- "MainButton" is a **Button** → use `app.buttons["MainButton"]`

## Navigation Patterns

The test navigation depends on where the view is located in the app.

### CRITICAL: Use Assertions for Every Navigation Step

**Every navigation step MUST use `XCTAssertTrue` to verify the element exists before interacting with it.** This ensures the test fails immediately if navigation goes wrong, rather than silently continuing and taking a screenshot of the wrong view.

### Tab Bar Views
```swift
let tabButton = app.buttons["TabName"]
XCTAssertTrue(tabButton.waitForExistence(timeout: 10.0), "TabName tab should exist")
tabButton.tap()
```

### Table/List Items
```swift
let menuItem = app.cells.staticTexts["MenuItem"]
XCTAssertTrue(menuItem.waitForExistence(timeout: 5.0), "MenuItem should exist")
menuItem.tap()
```

### SwiftUI Sheets/Modals
```swift
let showButton = app.buttons["AccessibilityID"]
XCTAssertTrue(showButton.waitForExistence(timeout: 10.0), "Show button should exist")
showButton.tap()
sleep(2) // Wait for animation
```

### Multi-Step Navigation
For views that require multiple navigation steps, capture hierarchy at each step and use `findTappable` for uncertain elements:
```swift
// Step 1: Go to a tab
let tab = app.buttons["MyTab"]
XCTAssertTrue(tab.waitForExistence(timeout: 10.0), "MyTab tab should exist")
tab.tap()
sleep(2)
captureHierarchy(name: "Step1-AfterTab")

// Step 2: Navigate deeper - could be Button or StaticText
let target = findTappable("TargetItem")
XCTAssertTrue(target.exists, "TargetItem should exist")
target.tap()
sleep(2)
captureHierarchy(name: "Step2-AfterTarget")

// Take the screenshot
let screenshot = app.screenshot()
```

With hierarchy captures at each step, if the test fails at Step 2, you can examine `Step1-AfterTab.txt` to see what was actually on screen.

## UI Hierarchy Debugging

When navigation fails, the test automatically captures the UI hierarchy to help debug accessibility IDs and element structure.

### Automatic Capture

The test includes `captureHierarchy` calls that save `app.debugDescription` as attachments. This provides:
- Complete element tree with accessibility identifiers
- Element types (Button, StaticText, Cell, etc.)
- Element values and labels
- Element hierarchy and nesting

### Using Hierarchy for Navigation

Example hierarchy output:
```
Button, identifier: "More", label: "More"
  ↳ Table
     ↳ Cell, identifier: "SettingsCell"
        ↳ StaticText, label: "Settings"
```

From this you can determine:
- The button identifier is "More"
- The menu item is in a Cell with identifier "SettingsCell"
- The text label is "Settings"

### Debug at Specific Points

Use the `captureHierarchy` helper at each navigation step:
```swift
captureHierarchy(name: "Step1-AfterLogin")
// ... navigate ...
captureHierarchy(name: "Step2-AfterTabSwitch")
// ... navigate ...
captureHierarchy(name: "Step3-AfterSearch")
```

This creates multiple hierarchy files in the output, letting you see exactly what was on screen at each point.

### Iterative Debugging Workflow

When navigation code needs fixing:

1. **Run test** → Test fails at some step
2. **Check hierarchy files** → Open the step hierarchy files from the xcresult attachments
3. **Find the issue** → The hierarchy from the step BEFORE failure shows what was actually on screen
4. **Update test** → Fix the navigation code (wrong element type? wrong identifier?)
5. **Re-run test** → Just re-run `xcodebuild test`

## Example Usage

**User request**: "Create a screenshot test for the SettingsView"

**Skill will**:
1. Ask for navigation details (if not obvious)
2. Create `ScreenshotTest_Settings.swift` in the UI test target (includes hierarchy capture)
3. Build and run the test: `xcodebuild test ...`
4. Extract screenshots from the xcresult bundle
5. Report the output location

**If navigation fails**: Check hierarchy attachments to find correct element identifiers, then update the test with proper accessibility IDs.

## Error Handling

Common issues:

- **Test passes but screenshot shows wrong view**: Navigation failed silently because `if` statements were used instead of `XCTAssertTrue`. Always use assertions for every navigation step.
- **Element not found but it's clearly visible**: You're using the wrong element type. `app.buttons["Item"]` won't find a StaticText. Check the UI hierarchy to find the actual element type, or use the `findTappable` helper.
- **Test fails to find view**: Check hierarchy attachments to see available accessibility IDs and element structure.
- **Simulator timeout**: Increase wait times in navigation code.
- **Navigation element not found**: Review the captured UI hierarchy to find the correct element identifier or query.
