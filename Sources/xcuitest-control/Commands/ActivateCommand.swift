import ArgumentParser
import Foundation
import XCUITestControlModels

struct ActivateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "activate",
        abstract: "Activate the app under test."
    )

    @OptionGroup var globals: GlobalOptions

    func run() throws {
        let command = InteractiveCommand(
            action: .activate,
            status: .pending
        )
        try globals.commandIO.writeCommand(command)
        let result = globals.commandIO.waitForCompletion()
        let code = ResultOutput.output(result: result, paths: globals.paths, verbose: globals.verbose)
        throw ExitCode(code)
    }
}
