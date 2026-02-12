import ArgumentParser
import Foundation
import XCUITestControlModels

struct TypeCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "type",
        abstract: "Type text into an element."
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: [.customShort("V"), .long], help: "Text to type.")
    var value: String

    @Option(name: [.short, .long], help: "Text field to type into (optional).")
    var target: String?

    @Option(name: [.customShort("T"), .customLong("target-type")], help: "Element type for faster lookup.")
    var targetType: InteractiveTargetType?

    func run() throws {
        let command = InteractiveCommand(
            action: .type,
            target: target,
            targetType: targetType,
            value: value,
            status: .pending
        )
        try globals.commandIO.writeCommand(command)
        let result = globals.commandIO.waitForCompletion()
        let code = ResultOutput.output(result: result, paths: globals.paths, verbose: globals.verbose)
        throw ExitCode(code)
    }
}
