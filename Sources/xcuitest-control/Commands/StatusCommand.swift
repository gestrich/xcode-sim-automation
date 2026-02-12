import ArgumentParser
import Foundation

struct StatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Check current command status."
    )

    @OptionGroup var globals: GlobalOptions

    func run() throws {
        let paths = globals.paths
        let io = globals.commandIO
        let fm = FileManager.default

        let command = io.readCommand()

        var commandValue: Any = NSNull()
        if let command {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(command),
               let obj = try? JSONSerialization.jsonObject(with: data) {
                commandValue = obj
            }
        }

        let dict: [String: Any] = [
            "command": commandValue,
            "hierarchy": fm.fileExists(atPath: paths.hierarchy) ? paths.hierarchy as Any : NSNull(),
            "screenshot": fm.fileExists(atPath: paths.screenshot) ? paths.screenshot as Any : NSNull(),
            "hierarchy_exists": fm.fileExists(atPath: paths.hierarchy),
            "screenshot_exists": fm.fileExists(atPath: paths.screenshot),
        ]

        ResultOutput.printJSON(dict)
    }
}
