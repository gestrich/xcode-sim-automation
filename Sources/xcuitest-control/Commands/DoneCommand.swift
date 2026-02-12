import ArgumentParser
import Foundation
import XCUITestControlModels

struct DoneCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "done",
        abstract: "Signal test completion."
    )

    @OptionGroup var globals: GlobalOptions

    func run() throws {
        let command = InteractiveCommand(
            action: .done,
            status: .pending
        )
        try globals.commandIO.writeCommand(command)
        let result = globals.commandIO.waitForCompletion()
        let code = ResultOutput.output(result: result, paths: globals.paths, verbose: globals.verbose)
        throw ExitCode(code)
    }
}
