import ArgumentParser
import Foundation
import XCUITestControlModels

struct TapCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tap",
        abstract: "Tap on an element."
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
            action: .tap,
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
