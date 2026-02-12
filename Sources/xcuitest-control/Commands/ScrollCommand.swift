import ArgumentParser
import Foundation
import XCUITestControlModels

struct ScrollCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scroll",
        abstract: "Scroll in a direction."
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: [.short, .long], help: "Scroll direction.")
    var direction: InteractiveScrollDirection

    @Option(name: [.short, .long], help: "Element to scroll (optional, defaults to app).")
    var target: String?

    @Option(name: [.customShort("T"), .customLong("target-type")], help: "Element type for faster lookup.")
    var targetType: InteractiveTargetType?

    func run() throws {
        let command = InteractiveCommand(
            action: .scroll,
            target: target,
            targetType: targetType,
            direction: direction,
            status: .pending
        )
        try globals.commandIO.writeCommand(command)
        let result = globals.commandIO.waitForCompletion()
        let code = ResultOutput.output(result: result, paths: globals.paths, verbose: globals.verbose)
        throw ExitCode(code)
    }
}
