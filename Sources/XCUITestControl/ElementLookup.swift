import XCTest

public struct ElementLookupResult {
    public let element: XCUIElement?
    public let matchCount: Int
    public let tappedIndex: Int?
    public let elementType: String

    public init(element: XCUIElement?, matchCount: Int, tappedIndex: Int?, elementType: String) {
        self.element = element
        self.matchCount = matchCount
        self.tappedIndex = tappedIndex
        self.elementType = elementType
    }
}

struct ElementLookup {

    static func findElement(
        identifier: String,
        type: InteractiveTargetType?,
        in app: XCUIApplication
    ) -> XCUIElement {
        switch type {
        case .button:
            return app.buttons[identifier]
        case .staticText:
            return app.staticTexts[identifier]
        case .cell:
            return app.cells[identifier]
        case .textField:
            return app.textFields[identifier]
        case .slider:
            return app.sliders[identifier]
        case .any, .none:
            let button = app.buttons[identifier]
            if button.exists { return button }

            let staticText = app.staticTexts[identifier]
            if staticText.exists { return staticText }

            let textField = app.textFields[identifier]
            if textField.exists { return textField }

            let cell = app.cells[identifier]
            if cell.exists { return cell }

            let slider = app.sliders[identifier]
            if slider.exists { return slider }

            return app.descendants(matching: .any)[identifier]
        }
    }

    static func findHittableElement(
        identifier: String,
        type: InteractiveTargetType?,
        index: Int?,
        in app: XCUIApplication
    ) -> ElementLookupResult {
        let query: XCUIElementQuery
        let elementType: String

        switch type {
        case .button:
            query = app.buttons.matching(identifier: identifier)
            elementType = "button"
        case .staticText:
            query = app.staticTexts.matching(identifier: identifier)
            elementType = "staticText"
        case .cell:
            query = app.cells.matching(identifier: identifier)
            elementType = "cell"
        case .textField:
            query = app.textFields.matching(identifier: identifier)
            elementType = "textField"
        case .slider:
            query = app.sliders.matching(identifier: identifier)
            elementType = "slider"
        case .any, .none:
            for typeToTry in [InteractiveTargetType.button, .staticText, .textField, .cell, .slider] {
                let result = findHittableElement(identifier: identifier, type: typeToTry, index: index, in: app)
                if result.matchCount > 0 {
                    return result
                }
            }
            query = app.descendants(matching: .any).matching(identifier: identifier)
            elementType = "any"
        }

        let matchCount = query.count
        guard matchCount > 0 else {
            return ElementLookupResult(element: nil, matchCount: 0, tappedIndex: nil, elementType: elementType)
        }

        if let specificIndex = index {
            guard specificIndex < matchCount else {
                return ElementLookupResult(element: nil, matchCount: matchCount, tappedIndex: nil, elementType: elementType)
            }
            let element = query.element(boundBy: specificIndex)
            return ElementLookupResult(element: element, matchCount: matchCount, tappedIndex: specificIndex, elementType: elementType)
        }

        for i in 0..<matchCount {
            let element = query.element(boundBy: i)
            if element.exists && element.isHittable {
                return ElementLookupResult(element: element, matchCount: matchCount, tappedIndex: i, elementType: elementType)
            }
        }

        let firstElement = query.element(boundBy: 0)
        return ElementLookupResult(element: firstElement, matchCount: matchCount, tappedIndex: 0, elementType: elementType)
    }
}
