import ArgumentParser
import Foundation
import XCUITestControlModels

struct ReadyCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ready",
        abstract: "Check if the test harness is ready."
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: [.short, .long], help: "Seconds to wait for ready state (0 = instant check).")
    var timeout: String = "0"

    func run() throws {
        let paths = globals.paths
        let io = globals.commandIO
        let fm = FileManager.default
        let timeoutSeconds = Double(timeout) ?? 0
        let start = Date()

        while true {
            let hierarchyExists = fm.fileExists(atPath: paths.hierarchy)
            var hierarchyAge: Double?
            if hierarchyExists,
               let attrs = try? fm.attributesOfItem(atPath: paths.hierarchy),
               let mtime = attrs[.modificationDate] as? Date {
                hierarchyAge = Date().timeIntervalSince(mtime)
            }

            let command = io.readCommand()
            let commandStatus = command?.status.rawValue

            let ready = hierarchyExists && (commandStatus == "completed" || commandStatus == "error" || commandStatus == nil)

            if ready || timeoutSeconds <= 0 || Date().timeIntervalSince(start) >= timeoutSeconds {
                let dict: [String: Any] = [
                    "ready": ready,
                    "hierarchy_exists": hierarchyExists,
                    "hierarchy_age_seconds": hierarchyAge.map { (($0 * 10).rounded() / 10) as Any } ?? NSNull() as Any,
                    "command_status": commandStatus as Any? ?? NSNull(),
                    "hierarchy": hierarchyExists ? paths.hierarchy as Any : NSNull(),
                    "screenshot": fm.fileExists(atPath: paths.screenshot) ? paths.screenshot as Any : NSNull(),
                ]

                ResultOutput.printJSON(dict)
                throw ExitCode(ready ? 0 : 1)
            }

            Thread.sleep(forTimeInterval: 1.0)
        }
    }
}
