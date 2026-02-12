import ArgumentParser
import Foundation
import XCUITestControlModels

struct WaitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wait",
        abstract: "Wait for a duration."
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: [.customShort("V"), .long], help: "Seconds to wait.")
    var value: String = "1.0"

    func run() throws {
        let command = InteractiveCommand(
            action: .wait,
            value: value,
            status: .pending
        )
        try globals.commandIO.writeCommand(command)
        let result = globals.commandIO.waitForCompletion()
        let code = ResultOutput.output(result: result, paths: globals.paths, verbose: globals.verbose)
        throw ExitCode(code)
    }
}
