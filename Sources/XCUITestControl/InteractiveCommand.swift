import Foundation

public enum InteractiveAction: String, Codable {
    case tap
    case scroll
    case type
    case wait
    case screenshot
    case adjust
    case pinch
    case done
}

public enum InteractiveTargetType: String, Codable {
    case button
    case staticText
    case cell
    case textField
    case slider
    case any
}

public enum InteractiveScrollDirection: String, Codable {
    case up
    case down
    case left
    case right
}

public enum InteractiveCommandStatus: String, Codable {
    case pending
    case executing
    case completed
    case error
}

public struct InteractiveCommand: Codable {
    public var action: InteractiveAction
    public var target: String?
    public var targetType: InteractiveTargetType?
    public var index: Int?
    public var value: String?
    public var direction: InteractiveScrollDirection?
    public var scale: String?
    public var velocity: String?
    public var status: InteractiveCommandStatus
    public var errorMessage: String?
    public var info: String?

    public init(
        action: InteractiveAction,
        target: String? = nil,
        targetType: InteractiveTargetType? = nil,
        index: Int? = nil,
        value: String? = nil,
        direction: InteractiveScrollDirection? = nil,
        scale: String? = nil,
        velocity: String? = nil,
        status: InteractiveCommandStatus,
        errorMessage: String? = nil,
        info: String? = nil
    ) {
        self.action = action
        self.target = target
        self.targetType = targetType
        self.index = index
        self.value = value
        self.direction = direction
        self.scale = scale
        self.velocity = velocity
        self.status = status
        self.errorMessage = errorMessage
        self.info = info
    }

    public static func initialCommand() -> InteractiveCommand {
        InteractiveCommand(action: .screenshot, status: .pending)
    }

    public static func completedCommand(from command: InteractiveCommand, info: String? = nil) -> InteractiveCommand {
        var updated = command
        updated.status = .completed
        updated.errorMessage = nil
        updated.info = info
        return updated
    }

    public static func errorCommand(from command: InteractiveCommand, message: String) -> InteractiveCommand {
        var updated = command
        updated.status = .error
        updated.errorMessage = message
        return updated
    }

    public static func executingCommand(from command: InteractiveCommand) -> InteractiveCommand {
        var updated = command
        updated.status = .executing
        return updated
    }
}

public struct InteractiveActionResult {
    public let success: Bool
    public let errorMessage: String?
    public let info: String?

    public init(success: Bool, errorMessage: String?, info: String?) {
        self.success = success
        self.errorMessage = errorMessage
        self.info = info
    }

    public static func success(info: String? = nil) -> InteractiveActionResult {
        InteractiveActionResult(success: true, errorMessage: nil, info: info)
    }

    public static func failure(_ message: String) -> InteractiveActionResult {
        InteractiveActionResult(success: false, errorMessage: message, info: nil)
    }
}
