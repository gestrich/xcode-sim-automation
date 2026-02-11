import XCTest

struct InteractiveActionExecutor {

    let configuration: InteractiveControlLoop.Configuration

    func execute(_ command: InteractiveCommand, in app: XCUIApplication) -> InteractiveActionResult {
        switch command.action {
        case .tap:
            return executeTap(command, in: app)
        case .scroll:
            return executeScroll(command, in: app)
        case .type:
            return executeType(command, in: app)
        case .wait:
            return executeWait(command)
        case .adjust:
            return executeAdjust(command, in: app)
        case .pinch:
            return executePinch(command, in: app)
        case .screenshot:
            return .success()
        case .done:
            return .success()
        }
    }

    // MARK: - Tap

    private func executeTap(_ command: InteractiveCommand, in app: XCUIApplication) -> InteractiveActionResult {
        guard let target = command.target else {
            return .failure("No target specified for tap action")
        }

        let timeout = configuration.elementWaitTimeout
        let retryCount = configuration.tapRetryCount
        let retryDelay = configuration.tapRetryDelay

        var lookupResult: ElementLookupResult?

        for attempt in 1...retryCount {
            lookupResult = ElementLookup.findHittableElement(
                identifier: target, type: command.targetType, index: command.index, in: app
            )

            guard let result = lookupResult, result.matchCount > 0 else {
                if attempt < retryCount {
                    Thread.sleep(forTimeInterval: retryDelay)
                    continue
                }
                return .failure("Element '\(target)' not found after \(retryCount) attempts")
            }

            if let index = command.index, index >= result.matchCount {
                return .failure("Index \(index) out of range. Found \(result.matchCount) '\(target)' element(s). Use --index 0 to \(result.matchCount - 1).")
            }

            guard let element = result.element else {
                if attempt < retryCount {
                    Thread.sleep(forTimeInterval: retryDelay)
                    continue
                }
                return .failure("Element '\(target)' not found after \(retryCount) attempts")
            }

            guard element.waitForExistence(timeout: timeout) else {
                if attempt < retryCount {
                    Thread.sleep(forTimeInterval: retryDelay)
                    continue
                }
                return .failure("Element '\(target)' not found after waiting \(Int(timeout)) seconds")
            }

            if element.isHittable {
                element.tap()

                var info: String?
                if result.matchCount > 1 {
                    let tappedIndex = result.tappedIndex ?? 0
                    info = "Tapped \(result.elementType) at index \(tappedIndex) of \(result.matchCount) matches"
                }
                return .success(info: info)
            }

            if attempt < retryCount {
                Thread.sleep(forTimeInterval: retryDelay)
            }
        }

        guard let result = lookupResult else {
            return .failure("Element '\(target)' not found")
        }

        if result.matchCount > 1 {
            return .failure("Found \(result.matchCount) elements matching '\(target)', none were hittable. Specify --index 0 to \(result.matchCount - 1) to select a specific element.")
        }

        return .failure("Element '\(target)' exists but was not hittable after \(retryCount) attempts")
    }

    // MARK: - Scroll

    private func executeScroll(_ command: InteractiveCommand, in app: XCUIApplication) -> InteractiveActionResult {
        guard let direction = command.direction else {
            return .failure("No direction specified for scroll action")
        }

        let element: XCUIElement
        if let target = command.target {
            element = ElementLookup.findElement(identifier: target, type: command.targetType, in: app)
            let timeout = configuration.elementWaitTimeout
            guard element.waitForExistence(timeout: timeout) else {
                return .failure("Element '\(target)' not found for scrolling after waiting \(Int(timeout)) seconds")
            }
        } else {
            element = app
        }

        switch direction {
        case .up:
            element.swipeDown()
        case .down:
            element.swipeUp()
        case .left:
            element.swipeRight()
        case .right:
            element.swipeLeft()
        }

        return .success()
    }

    // MARK: - Type

    private func executeType(_ command: InteractiveCommand, in app: XCUIApplication) -> InteractiveActionResult {
        guard let value = command.value else {
            return .failure("No value specified for type action")
        }

        if let target = command.target {
            let element = ElementLookup.findElement(identifier: target, type: command.targetType, in: app)
            let timeout = configuration.elementWaitTimeout
            guard element.waitForExistence(timeout: timeout) else {
                return .failure("Element '\(target)' not found for typing after waiting \(Int(timeout)) seconds")
            }
            element.tap()
            element.typeText(value)
        } else {
            app.typeText(value)
        }

        return .success()
    }

    // MARK: - Wait

    private func executeWait(_ command: InteractiveCommand) -> InteractiveActionResult {
        let seconds: TimeInterval
        if let value = command.value, let parsed = Double(value) {
            seconds = parsed
        } else {
            seconds = 1.0
        }
        Thread.sleep(forTimeInterval: seconds)
        return .success()
    }

    // MARK: - Adjust

    private func executeAdjust(_ command: InteractiveCommand, in app: XCUIApplication) -> InteractiveActionResult {
        guard let target = command.target else {
            return .failure("No target specified for adjust action")
        }

        guard let value = command.value, let normalizedValue = Double(value) else {
            return .failure("No value specified for adjust action (expected 0.0-1.0)")
        }

        guard normalizedValue >= 0.0 && normalizedValue <= 1.0 else {
            return .failure("Adjust value must be between 0.0 and 1.0, got \(normalizedValue)")
        }

        let slider = app.sliders[target]
        let timeout = configuration.elementWaitTimeout

        guard slider.waitForExistence(timeout: timeout) else {
            return .failure("Slider '\(target)' not found after waiting \(Int(timeout)) seconds")
        }

        let startCoordinate = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endCoordinate = slider.coordinate(withNormalizedOffset: CGVector(dx: normalizedValue, dy: 0.5))
        startCoordinate.press(forDuration: 0.05, thenDragTo: endCoordinate)

        return .success()
    }

    // MARK: - Pinch

    private func executePinch(_ command: InteractiveCommand, in app: XCUIApplication) -> InteractiveActionResult {
        guard let scaleStr = command.scale, let scale = Double(scaleStr) else {
            return .failure("No scale specified for pinch action (< 1.0 = pinch in, > 1.0 = pinch out)")
        }

        let velocity: Double
        if let velocityStr = command.velocity, let v = Double(velocityStr) {
            velocity = v
        } else {
            velocity = 1.0
        }

        let element: XCUIElement
        if let target = command.target {
            element = ElementLookup.findElement(identifier: target, type: command.targetType, in: app)
            let timeout = configuration.elementWaitTimeout
            guard element.waitForExistence(timeout: timeout) else {
                return .failure("Element '\(target)' not found for pinch after waiting \(Int(timeout)) seconds")
            }
        } else {
            element = app
        }

        element.pinch(withScale: CGFloat(scale), velocity: CGFloat(velocity))
        return .success()
    }
}
