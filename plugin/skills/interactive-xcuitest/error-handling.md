# Error Handling and Troubleshooting

## Robustness Configuration

The XCUITest control loop enforces several limits to prevent runaway behavior:

| Setting | Value | Purpose |
|---------|-------|---------|
| Maximum actions | 100 | Prevents infinite loops |
| Command timeout | 5 minutes | XCUITest exits if no commands received |
| Element timeout | 10 seconds | Actions fail gracefully if element not found |
| Tap retry count | 3 | Retries if element exists but not hittable |

## Command Errors

On error, the CLI returns:
```json
{
  "status": "error",
  "error": "Element 'missingButton' not found after waiting 10 seconds",
  "hierarchy": "...",
  "screenshot": "..."
}
```

When this happens:
1. Read the hierarchy to find the correct element
2. Try alternative identifiers or element types
3. Consider if navigation went to an unexpected view
4. Check if the element needs to be scrolled into view

## Common Errors

| Error | Solution |
|-------|----------|
| Element not found | Check hierarchy for correct identifier, try `--target-type any` |
| Element not hittable | Wait for animations, scroll element into view, retry |
| Multiple matches, none hittable | Use `--index` to select specific element, or scroll to reveal hittable ones |
| Index out of range | Check hierarchy to count matches, use valid index (0 to N-1) |
| Wrong element type | Use `--target-type any` or check hierarchy for actual type |
| Action limit reached | Break goal into smaller steps, restart skill |
| Test timeout | XCUITest exited due to 5 min inactivity, restart test |

## Common Pitfalls

### Multiple Element Matches on Scroll

Scrolling to an element can crash the test if the target identifier matches multiple elements (e.g., a filename appearing in both a sidebar and content area). The XCUITest framework reports "Multiple matching elements found" and the test terminates.

**Fix**: Use a more unique scroll target (e.g., a section header or parent container) or narrow with `--target-type`.

### LazyVStack and Off-Screen Elements

SwiftUI `LazyVStack` only renders visible items. Elements below the scroll fold won't appear in the accessibility hierarchy at all — they simply don't exist yet.

**Fix**: Scroll down to reveal the target area before searching. Use a known visible element as the scroll anchor.

### Menu Bar Items Not Hittable

Menu items (e.g., `performZoom:`) exist in the hierarchy but are not hittable because the menu isn't open. Tapping them directly will fail.

**Fix**: First open the menu (tap the MenuBarItem), then tap the MenuItem.

## Troubleshooting

### Files not appearing / hierarchy not written

The XCUITest runner is sandboxed on macOS and **cannot write to `/tmp/`**. Ensure:
1. The test uses `InteractiveControlLoop.Configuration` with container paths
2. The CLI uses `--container` flag pointing to the correct sandbox path
3. Check the container directory exists: `ls $CONTAINER/`

### "Failed to terminate <app>"

An app process from a previous run is still active. Fix:
```bash
pkill -f "$PROCESS_NAME" 2>/dev/null; sleep 2
```

### "Timed out while enabling automation mode"

This can happen on the first run after an Xcode restart, or when running from a non-GUI terminal. Fix:
- Retry the test — second attempt usually succeeds
- Ensure Xcode is running and the terminal has Accessibility permissions (System Settings > Privacy & Security > Accessibility)

### `done` command reports timeout

This is **expected behavior**. The test exits immediately on `done` without writing a "completed" status back. The CLI times out waiting for a response that never comes. The test itself exits cleanly — check the xcodebuild output for "TEST EXECUTE SUCCEEDED".

### "Unable to find hit point for Application"

The app window is behind other windows and isn't hittable. Fix:
```bash
$CLI -c "$CT" activate
```
This brings the app to the foreground. **Always run `activate` after starting the test** before any scroll/tap commands.

### Orphaned app process after test exit

Killing `xcodebuild` or sending `done` terminates the test runner but leaves the app running. Always clean up:
```bash
pkill -f "$PROCESS_NAME" 2>/dev/null
```

### Test hangs at "Find the Target Application"

This typically means `app.debugDescription` is taking a long time (the UI hierarchy can be 200KB+). Wait longer — it should complete within 5-10 seconds. If it persists, kill and restart.

### Common Keyboard Issues

| Issue | Solution |
|-------|----------|
| Keyboard blocking elements | Tap a non-interactive label to dismiss |
| Element not hittable | The element may be behind the keyboard — dismiss keyboard first |
| Can't scroll | Keyboard may be intercepting gestures — dismiss it first |
| Text not appearing | Ensure the text field was tapped/focused before typing |
