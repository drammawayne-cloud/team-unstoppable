import XCTest

final class SmokeTests: XCTestCase {
    func testMainScreensAndBookmarks() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 20))
        capture("home", app)
        for (name, filename) in [("Radio", "radio"), ("The Team", "team"), ("Events", "events"), ("More", "more")] {
            app.tabBars.buttons[name].tap()
            XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5))
            capture(filename, app)
        }
        app.tabBars.buttons["The Team"].tap()
        let member = app.staticTexts["Dramma Wayne"].firstMatch
        XCTAssertTrue(member.waitForExistence(timeout: 10))
        member.tap()
        let save = app.buttons["Save for later"].firstMatch
        let remove = app.buttons["Remove from saved"].firstMatch
        if remove.waitForExistence(timeout: 1) { remove.tap() }
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()
        XCTAssertTrue(remove.waitForExistence(timeout: 5))
        capture("profile", app)
        app.tabBars.buttons["More"].tap()
        app.buttons["Saved items"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Dramma Wayne"].firstMatch.waitForExistence(timeout: 5))
        capture("saved", app)
        app.terminate()
    }
    private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
