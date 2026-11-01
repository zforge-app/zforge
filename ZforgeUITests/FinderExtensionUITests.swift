import XCTest

/// Drives Finder's own shortcut menu. Requires the Zforge Finder extension of this
/// build to be enabled (System Settings or `pluginkit -e use -i io.libor.Zforge.FinderExtension`).
final class FinderExtensionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFinderSubmenuOffersArchiveActionsAndExtractsInZforge() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-finder-fixtures", "--ui-view-mode", "list", "-appLanguagePreference", "english",
                               "-ApplePersistenceIgnoreState", "YES", "-NSQuitAlwaysKeepsWindows", "NO"]
        app.launch(); app.activate()
        addTeardownBlock { app.terminate() }
        // macOS can restore an application with no browser window; the fixture needs one.
        let browser = app.windows.matching(NSPredicate(format: "identifier BEGINSWITH %@", "browser-")).firstMatch
        if !browser.waitForExistence(timeout: 3) {
            app.menuBars.menuBarItems["File"].click()
            app.menuItems["New Zforge Window"].click()
        }
        XCTAssertTrue(browser.waitForExistence(timeout: 8), app.debugDescription)

        // The fixture window reveals Sample.zip, selected, in a new Finder window.
        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
        let finderWindow = finder.windows.matching(NSPredicate(format: "title BEGINSWITH %@", "FinderFixture-")).firstMatch
        XCTAssertTrue(finderWindow.waitForExistence(timeout: 15), finder.debugDescription)
        addTeardownBlock { self.closeFixtureWindows(in: finder) }
        finder.activate()
        // Finder opens a new folder in the user's default view (D-67: Icons on this Mac); the
        // scenario uses the list, so the fixture window, frontmost since it just opened, is
        // switched to View > as List (⌘2). The fixture folder is temporary, so the user's own
        // default view is unchanged.
        finder.typeKey("2", modifierFlags: .command)
        // The row in the file list, not the path bar's item with the same name.
        let archive = finderWindow.outlines["ListView"].textFields["Sample.zip"].firstMatch
        XCTAssertTrue(archive.waitForExistence(timeout: 10), finderWindow.debugDescription)

        archive.rightClick()
        let zforge = try visibleZforgeItem(in: finder)
        zforge.hover()
        let titles = ["Open", "Extract Here", "Extract to \"Sample\"", "Extract…", "Validate", "Add to Archive…"]
        let submenu = zforge.menus.firstMatch
        XCTAssertTrue(submenu.waitForExistence(timeout: 5), zforge.debugDescription)
        XCTAssertEqual(submenu.menuItems.allElementsBoundByIndex.map(\.title).filter { !$0.isEmpty }, titles)
        try assertSymbolsContrast(in: submenu, titles: titles)
        let menu = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        menu.name = "Finder Zforge submenu for one archive"
        menu.lifetime = .keepAlways
        add(menu)

        submenu.menuItems["Extract Here"].click()

        // Zforge comes forward with the archive's folder and the extracted folder beside it.
        let extracted = app.descendants(matching: .any).matching(identifier: "browser-item-Payload").firstMatch
        XCTAssertTrue(extracted.waitForExistence(timeout: 20), app.debugDescription)
        let source = app.descendants(matching: .any).matching(identifier: "browser-item-Sample.zip").firstMatch
        XCTAssertTrue(source.exists)
        let result = XCTAttachment(screenshot: app.screenshot())
        result.name = "Zforge after Extract Here from Finder"
        result.lifetime = .keepAlways
        add(result)

        // A plain file offers the compression actions, with the badged symbols.
        finder.activate()
        let folder = finderWindow.outlines["ListView"].textFields["Note.txt"].firstMatch
        XCTAssertTrue(folder.waitForExistence(timeout: 10), finderWindow.debugDescription)
        folder.rightClick()
        let folderZforge = try visibleZforgeItem(in: finder)
        folderZforge.hover()
        let folderMenu = folderZforge.menus.firstMatch
        XCTAssertTrue(folderMenu.waitForExistence(timeout: 5), folderZforge.debugDescription)
        let compression = ["Compress", "Compress Custom…", "Add to Archive…"]
        XCTAssertEqual(folderMenu.menuItems.allElementsBoundByIndex.map(\.title).filter { !$0.isEmpty }, compression)
        try assertSymbolsContrast(in: folderMenu, titles: compression)
        let folderCapture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        folderCapture.name = "Finder Zforge submenu for a plain file"
        folderCapture.lifetime = .keepAlways
        add(folderCapture)
        finder.typeKey(.escape, modifierFlags: [])
        finder.typeKey(.escape, modifierFlags: [])
        closeFixtureWindows(in: finder)
    }

    /// Leaves the user's Finder as it was: closes every fixture window the test revealed.
    @MainActor
    private func closeFixtureWindows(in finder: XCUIApplication) {
        finder.activate()
        finder.typeKey(.escape, modifierFlags: [])
        let fixtures = finder.windows.matching(NSPredicate(format: "title BEGINSWITH %@", "FinderFixture-"))
        for _ in 0..<5 where fixtures.count > 0 {
            fixtures.firstMatch.buttons[XCUIIdentifierCloseWindow].firstMatch.click()
            let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 0"), object: fixtures)
            _ = XCTWaiter.wait(for: [closed], timeout: 2)
        }
        XCTAssertEqual(fixtures.count, 0, "Fixture windows left open in Finder")
    }

    /// Finder's File > Open With menu also lists Zforge, closed and offscreen;
    /// the shortcut menu's item is the visible one.
    @MainActor
    private func visibleZforgeItem(in finder: XCUIApplication) throws -> XCUIElement {
        let candidates = finder.menuItems.matching(NSPredicate(format: "title == %@", "Zforge"))
        // XCTWaiter evaluates the predicate on the main thread, where XCUIElement lives.
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate { object, _ in
            MainActor.assumeIsolated {
                ((object as? XCUIElementQuery)?.allElementsBoundByIndex.contains { $0.isHittable }) == true
            }
        }, object: candidates)
        XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 5), .completed, "Is the Zforge Finder extension enabled?")
        return try XCTUnwrap(candidates.allElementsBoundByIndex.first { $0.isHittable })
    }

    /// Finder shows extension images as they are: each symbol must contrast with the
    /// menu like its title (light on a dark menu, dark on a light one).
    @MainActor
    private func assertSymbolsContrast(in menu: XCUIElement, titles: [String]) throws {
        for title in titles {
            let item = menu.menuItems[title]
            let shot = item.screenshot()
            let range = try iconLuminanceRange(shot.image, pointWidth: item.frame.width)
            let capture = XCTAttachment(screenshot: shot)
            capture.name = "Finder submenu item \(title)"
            capture.lifetime = .keepAlways
            add(capture)
            // The theme is read from the menu itself; the test runner cannot read the system setting.
            if range.background < 0.5 {
                XCTAssertGreaterThan(range.max, 0.7, "\(title) symbol is not light on the dark menu")
            } else {
                XCTAssertLessThan(range.min, 0.3, "\(title) symbol is not dark on the light menu")
            }
        }
    }

    /// Luminance range of the symbol column (the leading 34 points of a menu item, before
    /// its title) and the item's background, the most common luminance in that column.
    private func iconLuminanceRange(_ image: NSImage, pointWidth: CGFloat) throws -> (min: Double, max: Double, background: Double) {
        let bitmap = try XCTUnwrap(image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)))
        let scale = Double(bitmap.pixelsWide) / Double(pointWidth)
        var low = 1.0, high = 0.0
        var histogram = [Int](repeating: 0, count: 11)
        for x in 0..<min(bitmap.pixelsWide, Int(34 * scale)) {
            for y in 0..<bitmap.pixelsHigh {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
                let luminance = Double(color.redComponent + color.greenComponent + color.blueComponent) / 3
                low = min(low, luminance); high = max(high, luminance)
                histogram[Int((luminance * 10).rounded())] += 1
            }
        }
        let background = Double(histogram.indices.max { histogram[$0] < histogram[$1] } ?? 0) / 10
        return (low, high, background)
    }
}
