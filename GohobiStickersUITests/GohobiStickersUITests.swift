import XCTest

final class GohobiStickersUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCanOpenStampAndGoalEditors() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.descendants(matching: .any)["total-stamp-header"]
                .waitForExistence(timeout: 5)
        )

        app.buttons["next-stamp-node"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["stamp-editor-screen"]
                .waitForExistence(timeout: 5)
        )
        app.buttons["stamp-editor-cancel-button"].tap()

        app.buttons["goal-settings-button"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["goal-settings-screen"]
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testLongPressingCompletedNodeShowsStampDetails() throws {
        let app = XCUIApplication()
        app.launch()

        let nextNode = app.buttons["next-stamp-node"]
        XCTAssertTrue(nextNode.waitForExistence(timeout: 5))
        nextNode.tap()

        let saveButton = app.buttons["stamp-editor-save-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        let firstStamp = app.buttons["stamp-node-1"]
        XCTAssertTrue(firstStamp.waitForExistence(timeout: 5))
        firstStamp.press(forDuration: 1.2)

        XCTAssertTrue(
            app.buttons["stamp-node-quick-look-edit-button"]
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
