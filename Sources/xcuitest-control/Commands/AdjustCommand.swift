import ArgumentParser
import Foundation
import XCUITestControlModels

struct AdjustCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "adjust",
        abstract: "Adjust a slider or picker."
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: [.short, .long], help: "Slider identifier.")
    var target: String

    @Option(name: [.customShort("V"), .long], help: "Normalized position (0.0-1.0).")
    var value: String

    func run() throws {
        let command = InteractiveCommand(
            action: .adjust,
            target: target,
            value: value,
            status: .pending
        )
        try globals.commandIO.writeCommand(command)
        let result = globals.commandIO.waitForCompletion()
        let code = ResultOutput.output(result: result, paths: globals.paths, verbose: globals.verbose)
        throw ExitCode(code)
    }
}
