import ArgumentParser
import Foundation
import XCUITestControlModels

struct ScreenshotCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screenshot",
        abstract: "Take a screenshot."
    )

    @OptionGroup var globals: GlobalOptions

    func run() throws {
        let command = InteractiveCommand(
            action: .screenshot,
            status: .pending
        )
        try globals.commandIO.writeCommand(command)
        let result = globals.commandIO.waitForCompletion()
        let code = ResultOutput.output(result: result, paths: globals.paths, verbose: globals.verbose)
        throw ExitCode(code)
    }
}
