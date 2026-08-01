import XCTest

final class GohobiStickersUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCanOpenStampAndGoalEditors() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["いままでのスタンプ"].waitForExistence(timeout: 3))

        app.buttons["スタンプを押す"].tap()
        XCTAssertTrue(app.navigationBars["スタンプを押す"].waitForExistence(timeout: 2))
        app.buttons["キャンセル"].tap()

        app.buttons["ゴール設定"].tap()
        XCTAssertTrue(app.navigationBars["ゴール設定"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
