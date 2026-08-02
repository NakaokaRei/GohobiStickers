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
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
