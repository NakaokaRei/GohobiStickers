import XCTest

final class GohobiStickersUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCanOpenStampAndGoalEditors() throws {
        let app = makeApp()
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
    func testCanAddAndSwitchRewardRoads() throws {
        let app = makeApp()
        app.launch()

        let roadPicker = app.buttons["road-picker-button"]
        XCTAssertTrue(roadPicker.waitForExistence(timeout: 5))
        roadPicker.tap()

        let addRoadButton = app.buttons["road-picker-add-button"]
        XCTAssertTrue(addRoadButton.waitForExistence(timeout: 5))
        addRoadButton.tap()

        let nameField = app.textFields["road-editor-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("運動ロード")
        app.buttons["road-editor-save-button"].tap()

        XCTAssertTrue(roadPicker.waitForExistence(timeout: 5))
        XCTAssertTrue(roadPicker.label.contains("運動ロード"))
        XCTAssertTrue(app.buttons["next-stamp-node"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testWidgetDeepLinkOpensANewStampEditorOnLaunch() throws {
        let app = makeApp()
        app.launchArguments.append("--open-stamp-editor")
        app.launch()

        XCTAssertTrue(
            app.descendants(matching: .any)["stamp-editor-screen"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.buttons["stamp-editor-save-button"].exists)
    }

    @MainActor
    func testLongPressingCompletedNodeShowsStampDetails() throws {
        let app = makeApp()
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
    func testAttachedImageAppearsInBadgePreviewAndEditor() throws {
        let app = makeApp()
        app.launchArguments.append("--ui-testing-image-stamp")
        app.launch()

        let firstStamp = app.buttons["stamp-node-1"]
        XCTAssertTrue(firstStamp.waitForExistence(timeout: 5))
        XCTAssertTrue(app.images["stamp-image-badge-1"].exists)
        firstStamp.press(forDuration: 1.2)

        let editButton = app.buttons["stamp-node-quick-look-edit-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let imagePreview = app.buttons["stamp-image-preview"]
        XCTAssertTrue(imagePreview.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["stamp-image-picker-button"].exists)
        XCTAssertTrue(app.buttons["stamp-image-remove-button"].exists)

        imagePreview.tap()
        let viewerCloseButton = app.buttons["stamp-image-viewer-close-button"]
        XCTAssertTrue(viewerCloseButton.waitForExistence(timeout: 5))
        viewerCloseButton.tap()
        XCTAssertTrue(imagePreview.waitForExistence(timeout: 5))
    }

    @MainActor
    func testCurrentPositionButtonJumpsToNextStamp() throws {
        let app = makeApp()
        app.launchArguments.append("--ui-testing-long-route")
        app.launch()

        let currentPositionButton = app.buttons["current-position-button"]
        XCTAssertTrue(currentPositionButton.waitForExistence(timeout: 5))
        currentPositionButton.tap()

        let nextStampNode = app.buttons["next-stamp-node"]
        XCTAssertTrue(nextStampNode.waitForExistence(timeout: 5))
        let becameHittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: nextStampNode
        )
        XCTAssertEqual(XCTWaiter.wait(for: [becameHittable], timeout: 5), .completed)

        let buttonDisappeared = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: currentPositionButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [buttonDisappeared], timeout: 5), .completed)
    }

    @MainActor
    func testCanPreviewGoalCardFromCelebrationAndGoalBadge() throws {
        let app = makeApp()
        app.launch()

        for _ in 0..<5 {
            let nextNode = app.buttons["next-stamp-node"]
            XCTAssertTrue(nextNode.waitForExistence(timeout: 5))
            nextNode.tap()

            let saveButton = app.buttons["stamp-editor-save-button"]
            XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
            saveButton.tap()
        }

        let celebrationShareButton = app.buttons["celebration-share-button"]
        XCTAssertTrue(celebrationShareButton.waitForExistence(timeout: 5))
        celebrationShareButton.tap()
        assertSharePreview(in: app)
        app.buttons["goal-share-close-button"].tap()

        let celebrationDismissButton = app.buttons["celebration-dismiss-button"]
        XCTAssertTrue(celebrationDismissButton.waitForExistence(timeout: 5))
        celebrationDismissButton.tap()

        let goalShareButton = app.buttons["goal-share-button-5"]
        for _ in 0..<4 {
            if goalShareButton.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(goalShareButton.waitForExistence(timeout: 5))
        XCTAssertTrue(goalShareButton.isHittable)
        goalShareButton.tap()
        assertSharePreview(in: app)
    }

    @MainActor
    func testAchievedGoalIsLargerAndCanShare() throws {
        let app = makeApp()
        app.launchArguments += ["--ui-testing-goal-badges", "-AppleLanguages", "(ja)"]
        app.launch()

        let achieved = app.otherElements["goal-badge-1"]
        let upcoming = app.otherElements["goal-badge-2"]
        XCTAssertTrue(achieved.waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(upcoming.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(achieved.frame.width, upcoming.frame.width)
        XCTAssertGreaterThan(achieved.frame.height, upcoming.frame.height)
        saveScreenshot(named: "05-achieved-and-upcoming-goals", in: app)
        app.buttons["goal-share-button-1"].tap()
        assertSharePreview(in: app)
    }

    @MainActor
    func testLongGoalAtAccessibilityTextSize() throws {
        let app = makeApp()
        app.launchArguments += [
            "--ui-testing-goal-badges", "--ui-testing-long-reward",
            "-AppleLanguages", "(ja)",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        let share = app.buttons["goal-share-button-1"]
        for _ in 0..<6 {
            if share.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(share.isHittable)
        saveScreenshot(named: "06-long-goal-accessibility-text", in: app)
        share.tap()
        assertSharePreview(in: app)
    }

    @MainActor
    func testLaunchPerformance() throws {
        let app = makeApp()
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    @MainActor
    private func saveScreenshot(named name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        return app
    }

    @MainActor
    private func assertSharePreview(in app: XCUIApplication) {
        XCTAssertTrue(
            app.descendants(matching: .any)["goal-share-preview-screen"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.buttons["goal-share-action-button"]
                .waitForExistence(timeout: 5)
        )
    }
}
