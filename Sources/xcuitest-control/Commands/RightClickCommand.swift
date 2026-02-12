import ArgumentParser
import Foundation
import XCUITestControlModels

struct RightClickCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "right-click",
        abstract: "Right-click on an element (macOS only)."
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: [.short, .long], help: "Element identifier.")
    var target: String

    @Option(name: [.customShort("T"), .customLong("target-type")], help: "Element type for faster lookup.")
    var targetType: InteractiveTargetType?

    @Option(name: [.short, .long], help: "Index of element when multiple match (0-based).")
    var index: Int?

    func run() throws {
        let command = InteractiveCommand(
            action: .rightClick,
            target: target,
            targetType: targetType,
            index: index,
            status: .pending
        )
        try globals.commandIO.writeCommand(command)
        let result = globals.commandIO.waitForCompletion()
        let code = ResultOutput.output(result: result, paths: globals.paths, verbose: globals.verbose)
        throw ExitCode(code)
    }
}
