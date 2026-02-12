import ArgumentParser
import XCUITestControlModels

@main
struct XCUITestControlCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcuitest-control",
        abstract: "Control XCUITest automation from the command line.",
        subcommands: [
            TapCommand.self,
            RightClickCommand.self,
            ScrollCommand.self,
            TypeCommand.self,
            AdjustCommand.self,
            PinchCommand.self,
            WaitCommand.self,
            ScreenshotCommand.self,
            ActivateCommand.self,
            DoneCommand.self,
            StatusCommand.self,
            ResetCommand.self,
            ReadyCommand.self,
        ]
    )
}

// MARK: - Stubbed Subcommands

struct TapCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "tap", abstract: "Tap on an element.")
    func run() throws { print("Not yet implemented.") }
}

struct RightClickCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "right-click", abstract: "Right-click on an element (macOS only).")
    func run() throws { print("Not yet implemented.") }
}

struct ScrollCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "scroll", abstract: "Scroll in a direction.")
    func run() throws { print("Not yet implemented.") }
}

struct TypeCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "type", abstract: "Type text into an element.")
    func run() throws { print("Not yet implemented.") }
}

struct AdjustCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "adjust", abstract: "Adjust a slider or picker.")
    func run() throws { print("Not yet implemented.") }
}

struct PinchCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "pinch", abstract: "Pinch to zoom.")
    func run() throws { print("Not yet implemented.") }
}

struct WaitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "wait", abstract: "Wait for a duration.")
    func run() throws { print("Not yet implemented.") }
}

struct ScreenshotCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "screenshot", abstract: "Take a screenshot.")
    func run() throws { print("Not yet implemented.") }
}

struct ActivateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "activate", abstract: "Activate the app under test.")
    func run() throws { print("Not yet implemented.") }
}

struct DoneCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "done", abstract: "Signal test completion.")
    func run() throws { print("Not yet implemented.") }
}

struct StatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "status", abstract: "Check current command status.")
    func run() throws { print("Not yet implemented.") }
}

struct ResetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "reset", abstract: "Delete protocol files.")
    func run() throws { print("Not yet implemented.") }
}

struct ReadyCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "ready", abstract: "Check if the test harness is ready.")
    func run() throws { print("Not yet implemented.") }
}
