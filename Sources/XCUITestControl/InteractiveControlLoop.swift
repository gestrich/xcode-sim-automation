import XCTest
import XCUITestControlModels

public struct InteractiveControlLoop {

    public struct Configuration {
        public var commandPath: String
        public var hierarchyPath: String
        public var screenshotPath: String
        public var pollingInterval: TimeInterval
        public var sessionTimeout: TimeInterval
        public var elementWaitTimeout: TimeInterval
        public var tapRetryCount: Int
        public var tapRetryDelay: TimeInterval

        public init(
            commandPath: String = "/tmp/xcuitest-command.json",
            hierarchyPath: String = "/tmp/xcuitest-hierarchy.txt",
            screenshotPath: String = "/tmp/xcuitest-screenshot.png",
            pollingInterval: TimeInterval = 0.5,
            sessionTimeout: TimeInterval = 300,
            elementWaitTimeout: TimeInterval = 10,
            tapRetryCount: Int = 3,
            tapRetryDelay: TimeInterval = 0.5
        ) {
            self.commandPath = commandPath
            self.hierarchyPath = hierarchyPath
            self.screenshotPath = screenshotPath
            self.pollingInterval = pollingInterval
            self.sessionTimeout = sessionTimeout
            self.elementWaitTimeout = elementWaitTimeout
            self.tapRetryCount = tapRetryCount
            self.tapRetryDelay = tapRetryDelay
        }
    }

    public let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    @MainActor
    public func run(app: XCUIApplication) {
        let executor = InteractiveActionExecutor(configuration: configuration)

        // Clear stale commands from previous sessions to prevent
        // the loop from immediately exiting on a leftover "done" command
        try? FileManager.default.removeItem(atPath: configuration.commandPath)

        writeHierarchy(app: app)
        writeScreenshot(app: app)
        writeInitialCommand()

        var lastPendingCommandTime = Date()
        print("Interactive control: Loop starting. Session timeout: \(Int(configuration.sessionTimeout))s. Command path: \(configuration.commandPath)")

        while true {
            guard let command = readCommand() else {
                print("Interactive control: No command file found, polling...")
                Thread.sleep(forTimeInterval: configuration.pollingInterval)
                if Date().timeIntervalSince(lastPendingCommandTime) > configuration.sessionTimeout {
                    print("Interactive control: Timeout - no commands received for \(Int(configuration.sessionTimeout)) seconds. Exiting.")
                    break
                }
                continue
            }

            print("Interactive control: Read command - action=\(command.action.rawValue) status=\(command.status.rawValue)")

            if command.action == .done {
                print("Interactive control: Received done command. Exiting.")
                break
            }
            if command.status != .pending {
                Thread.sleep(forTimeInterval: configuration.pollingInterval)
                if Date().timeIntervalSince(lastPendingCommandTime) > configuration.sessionTimeout {
                    print("Interactive control: Timeout - no pending commands for \(Int(configuration.sessionTimeout)) seconds. Exiting.")
                    break
                }
                continue
            }

            lastPendingCommandTime = Date()
            updateStatus(command: command, status: .executing)

            let result = executor.execute(command, in: app)

            writeHierarchy(app: app)
            writeScreenshot(app: app)

            if result.success {
                updateStatus(command: command, status: .completed, info: result.info)
            } else {
                updateStatus(command: command, status: .error, errorMessage: result.errorMessage)
            }
        }
    }

    // MARK: - File I/O

    private func readCommand() -> InteractiveCommand? {
        guard let data = FileManager.default.contents(atPath: configuration.commandPath) else {
            return nil
        }
        return try? JSONDecoder().decode(InteractiveCommand.self, from: data)
    }

    private func writeHierarchy(app: XCUIApplication) {
        let hierarchy = app.debugDescription
        try? hierarchy.write(toFile: configuration.hierarchyPath, atomically: true, encoding: .utf8)
    }

    private func writeScreenshot(app: XCUIApplication) {
        let screenshot = app.screenshot()
        let pngData = screenshot.pngRepresentation
        try? pngData.write(to: URL(fileURLWithPath: configuration.screenshotPath))
    }

    private func writeInitialCommand() {
        let command = InteractiveCommand.initialCommand()
        writeCommand(command)
    }

    private func writeCommand(_ command: InteractiveCommand) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(command) else { return }
        try? data.write(to: URL(fileURLWithPath: configuration.commandPath))
    }

    private func updateStatus(
        command: InteractiveCommand,
        status: InteractiveCommandStatus,
        errorMessage: String? = nil,
        info: String? = nil
    ) {
        var updated = command
        updated.status = status
        updated.errorMessage = errorMessage
        updated.info = info
        writeCommand(updated)
    }
}
