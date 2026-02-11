#!/usr/bin/env python3
"""
XCUITest Control CLI

A command-line interface for controlling XCUITest through a file-based protocol.
Writes commands to /tmp/xcuitest-command.json and polls for completion.

Usage:
    ./xcuitest-control.py tap --target buttonId [--target-type button]
    ./xcuitest-control.py scroll --direction down [--target scrollView]
    ./xcuitest-control.py type --value "text to type" [--target textField]
    ./xcuitest-control.py adjust --target sliderId --value 0.5
    ./xcuitest-control.py pinch --scale 2.0 [--velocity 1.0] [--target imageView]
    ./xcuitest-control.py wait [--value 2.0]
    ./xcuitest-control.py screenshot
    ./xcuitest-control.py done
    ./xcuitest-control.py status  # Check current command status
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Optional

# File paths for communication (overridable via environment variables)
COMMAND_PATH = Path(os.environ.get("XCUITEST_COMMAND_PATH", "/tmp/xcuitest-command.json"))
HIERARCHY_PATH = Path(os.environ.get("XCUITEST_HIERARCHY_PATH", "/tmp/xcuitest-hierarchy.txt"))
SCREENSHOT_PATH = Path(os.environ.get("XCUITEST_SCREENSHOT_PATH", "/tmp/xcuitest-screenshot.png"))

# Polling configuration
POLL_INTERVAL = 0.2  # seconds
POLL_TIMEOUT = 30.0  # seconds


def read_command() -> Optional[dict]:
    """Read the current command file."""
    if not COMMAND_PATH.exists():
        return None
    try:
        with open(COMMAND_PATH, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return None


def write_command(command: dict) -> None:
    """Write a command to the command file."""
    with open(COMMAND_PATH, "w") as f:
        json.dump(command, f, indent=2, sort_keys=True)


def wait_for_completion(timeout: float = POLL_TIMEOUT) -> dict:
    """Poll until command status is 'completed' or 'error'."""
    start_time = time.time()

    while time.time() - start_time < timeout:
        command = read_command()
        if command is None:
            time.sleep(POLL_INTERVAL)
            continue

        status = command.get("status")
        if status in ("completed", "error"):
            return command

        time.sleep(POLL_INTERVAL)

    return {"status": "error", "errorMessage": f"Timeout after {timeout} seconds"}


def execute_action(action: str, **kwargs) -> dict:
    """Execute an action and wait for completion."""
    # Build the command
    command = {
        "action": action,
        "status": "pending"
    }

    # Add optional parameters
    if kwargs.get("target"):
        command["target"] = kwargs["target"]
    if kwargs.get("target_type"):
        command["targetType"] = kwargs["target_type"]
    if kwargs.get("index") is not None:
        command["index"] = kwargs["index"]
    if kwargs.get("value"):
        command["value"] = kwargs["value"]
    if kwargs.get("direction"):
        command["direction"] = kwargs["direction"]
    if kwargs.get("scale"):
        command["scale"] = kwargs["scale"]
    if kwargs.get("velocity"):
        command["velocity"] = kwargs["velocity"]

    # Write the command
    write_command(command)

    # Wait for completion
    result = wait_for_completion()
    return result


def output_result(result: dict, verbose: bool = False) -> int:
    """Output the result and return exit code."""
    status = result.get("status", "unknown")

    output = {
        "status": status,
        "hierarchy": str(HIERARCHY_PATH) if HIERARCHY_PATH.exists() else None,
        "screenshot": str(SCREENSHOT_PATH) if SCREENSHOT_PATH.exists() else None,
    }

    if status == "error":
        output["error"] = result.get("errorMessage", "Unknown error")

    if result.get("info"):
        output["info"] = result["info"]

    if verbose:
        output["command"] = result

    print(json.dumps(output, indent=2))

    return 0 if status == "completed" else 1


def cmd_tap(args) -> int:
    """Execute tap action."""
    result = execute_action(
        "tap",
        target=args.target,
        target_type=args.target_type,
        index=args.index
    )
    return output_result(result, args.verbose)


def cmd_scroll(args) -> int:
    """Execute scroll action."""
    result = execute_action(
        "scroll",
        target=args.target,
        target_type=args.target_type,
        direction=args.direction
    )
    return output_result(result, args.verbose)


def cmd_type(args) -> int:
    """Execute type action."""
    result = execute_action(
        "type",
        target=args.target,
        target_type=args.target_type,
        value=args.value
    )
    return output_result(result, args.verbose)


def cmd_adjust(args) -> int:
    """Execute adjust action for sliders."""
    result = execute_action(
        "adjust",
        target=args.target,
        value=args.value
    )
    return output_result(result, args.verbose)


def cmd_pinch(args) -> int:
    """Execute pinch action."""
    result = execute_action(
        "pinch",
        target=args.target,
        target_type=args.target_type,
        scale=args.scale,
        velocity=args.velocity
    )
    return output_result(result, args.verbose)


def cmd_wait(args) -> int:
    """Execute wait action."""
    result = execute_action(
        "wait",
        value=args.value
    )
    return output_result(result, args.verbose)


def cmd_screenshot(args) -> int:
    """Execute screenshot action."""
    result = execute_action("screenshot")
    return output_result(result, args.verbose)


def cmd_done(args) -> int:
    """Execute done action to exit test loop."""
    result = execute_action("done")
    return output_result(result, args.verbose)


def cmd_status(args) -> int:
    """Check current command status without executing."""
    command = read_command()

    output = {
        "command": command,
        "hierarchy": str(HIERARCHY_PATH) if HIERARCHY_PATH.exists() else None,
        "screenshot": str(SCREENSHOT_PATH) if SCREENSHOT_PATH.exists() else None,
        "hierarchy_exists": HIERARCHY_PATH.exists(),
        "screenshot_exists": SCREENSHOT_PATH.exists(),
    }

    print(json.dumps(output, indent=2))
    return 0


def main():
    parser = argparse.ArgumentParser(
        description="Control XCUITest through a file-based protocol",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("-v", "--verbose", action="store_true", help="Include full command in output")

    subparsers = parser.add_subparsers(dest="action", required=True)

    # tap command
    tap_parser = subparsers.add_parser("tap", help="Tap an element")
    tap_parser.add_argument("--target", "-t", required=True, help="Element identifier")
    tap_parser.add_argument("--target-type", "-T", choices=["button", "staticText", "cell", "textField", "slider", "any"],
                           help="Element type for faster lookup")
    tap_parser.add_argument("--index", "-i", type=int, help="Index of element when multiple match (0-based)")
    tap_parser.set_defaults(func=cmd_tap)

    # scroll command
    scroll_parser = subparsers.add_parser("scroll", help="Scroll/swipe in a direction")
    scroll_parser.add_argument("--direction", "-d", required=True, choices=["up", "down", "left", "right"])
    scroll_parser.add_argument("--target", "-t", help="Element to scroll (optional, defaults to app)")
    scroll_parser.add_argument("--target-type", "-T", choices=["button", "staticText", "cell", "textField", "slider", "any"])
    scroll_parser.set_defaults(func=cmd_scroll)

    # type command
    type_parser = subparsers.add_parser("type", help="Type text")
    type_parser.add_argument("--value", "-V", required=True, help="Text to type")
    type_parser.add_argument("--target", "-t", help="Text field to type into (optional)")
    type_parser.add_argument("--target-type", "-T", choices=["button", "staticText", "cell", "textField", "slider", "any"])
    type_parser.set_defaults(func=cmd_type)

    # adjust command
    adjust_parser = subparsers.add_parser("adjust", help="Adjust a slider")
    adjust_parser.add_argument("--target", "-t", required=True, help="Slider identifier")
    adjust_parser.add_argument("--value", "-V", required=True, help="Normalized position (0.0-1.0)")
    adjust_parser.set_defaults(func=cmd_adjust)

    # pinch command
    pinch_parser = subparsers.add_parser("pinch", help="Pinch to zoom in/out")
    pinch_parser.add_argument("--scale", "-s", required=True, help="Scale factor (< 1.0 = zoom out, > 1.0 = zoom in)")
    pinch_parser.add_argument("--velocity", "-V", default="1.0", help="Speed in scale factor per second (default: 1.0)")
    pinch_parser.add_argument("--target", "-t", help="Element to pinch (optional, defaults to app)")
    pinch_parser.add_argument("--target-type", "-T", choices=["button", "staticText", "cell", "textField", "slider", "any"])
    pinch_parser.set_defaults(func=cmd_pinch)

    # wait command
    wait_parser = subparsers.add_parser("wait", help="Wait for a duration")
    wait_parser.add_argument("--value", "-V", default="1.0", help="Seconds to wait (default: 1.0)")
    wait_parser.set_defaults(func=cmd_wait)

    # screenshot command
    screenshot_parser = subparsers.add_parser("screenshot", help="Capture screenshot and hierarchy")
    screenshot_parser.set_defaults(func=cmd_screenshot)

    # done command
    done_parser = subparsers.add_parser("done", help="Exit the test loop")
    done_parser.set_defaults(func=cmd_done)

    # status command
    status_parser = subparsers.add_parser("status", help="Check current status without executing")
    status_parser.set_defaults(func=cmd_status)

    args = parser.parse_args()

    try:
        exit_code = args.func(args)
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\nInterrupted", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(json.dumps({"status": "error", "error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
