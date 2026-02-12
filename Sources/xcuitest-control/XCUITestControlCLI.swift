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

struct GlobalOptions: ParsableArguments {
    @Flag(name: [.short, .long], help: "Include full command in output.")
    var verbose = false

    @Option(name: [.short, .customLong("container")], help: "Container directory (sets all file paths).")
    var container: String?

    var paths: ResolvedPaths {
        PathResolver.resolve(container: container)
    }

    var commandIO: CommandIO {
        CommandIO(paths: paths)
    }
}

// MARK: - ArgumentParser conformances for model enums

extension InteractiveTargetType: ExpressibleByArgument {}
extension InteractiveScrollDirection: ExpressibleByArgument {}
