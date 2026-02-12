import ArgumentParser
import Foundation

struct ResetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Delete protocol files."
    )

    @OptionGroup var globals: GlobalOptions

    func run() throws {
        let paths = globals.paths
        let fm = FileManager.default

        var removed: [String] = []
        for path in [paths.command, paths.hierarchy, paths.screenshot] {
            if fm.fileExists(atPath: path) {
                try fm.removeItem(atPath: path)
                removed.append(path)
            }
        }

        let dict: [String: Any] = [
            "status": "completed",
            "removed": removed,
            "message": removed.isEmpty ? "No files to remove" : "Removed \(removed.count) file(s)",
        ]

        ResultOutput.printJSON(dict)
    }
}
