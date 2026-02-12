import ArgumentParser
import Foundation
import XCUITestControlModels

struct PinchCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pinch",
        abstract: "Pinch to zoom."
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: [.short, .long], help: "Scale factor (< 1.0 = zoom out, > 1.0 = zoom in).")
    var scale: String

    @Option(name: [.customShort("V"), .long], help: "Speed in scale factor per second.")
    var velocity: String = "1.0"

    @Option(name: [.short, .long], help: "Element to pinch (optional, defaults to app).")
    var target: String?

    @Option(name: [.customShort("T"), .customLong("target-type")], help: "Element type for faster lookup.")
    var targetType: InteractiveTargetType?

    func run() throws {
        let command = InteractiveCommand(
            action: .pinch,
            target: target,
            targetType: targetType,
            scale: scale,
            velocity: velocity,
            status: .pending
        )
        try globals.commandIO.writeCommand(command)
        let result = globals.commandIO.waitForCompletion()
        let code = ResultOutput.output(result: result, paths: globals.paths, verbose: globals.verbose)
        throw ExitCode(code)
    }
}
