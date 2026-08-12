import UIKit
import XCTest

@MainActor
final class WorkbenchLayoutContractUITests: XCTestCase {
    private enum PrototypeGeometry {
        static let horizontalContentInset: CGFloat = 24
        static let dockOuterControlInset: CGFloat = 16
        static let dockSideActionSize: CGFloat = 56
        static let dockLiveActionWidth: CGFloat = 140
        static let dockActionHeight: CGFloat = 56
        static let liveIndicatorCenterX: CGFloat = 28
        static let alignmentTolerance: CGFloat = 1
        static let indicatorCenterTolerance: CGFloat = 0.5
    }

    func testWorkbenchUsesFixedScaffoldAndSingleLineCenteredHeader() {
        let app = launchCleanApp()
        let root = app.otherElements["workbench-root"]
        let header = app.otherElements["workbench-header"]
        let title = app.staticTexts["Island Notes"]
        let more = app.buttons["open-more-menu"]

        XCTAssertTrue(root.waitForExistence(timeout: 5))
        XCTAssertFalse(app.scrollViews["workbench-root"].exists)
        XCTAssertTrue(header.exists)
        XCTAssertTrue(title.exists)
        XCTAssertEqual(title.frame.midX, app.frame.midX, accuracy: 1)
        XCTAssertGreaterThanOrEqual(more.frame.width, 44)
        XCTAssertGreaterThanOrEqual(more.frame.height, 44)
        XCTAssertFalse(title.frame.intersects(more.frame))
        XCTAssertEqual(header.staticTexts.count, 1)
        XCTAssertFalse(header.staticTexts["Not Live"].exists)
        XCTAssertFalse(header.staticTexts["Live"].exists)
    }

    func testEmptyWorkbenchUsesPrototypeCopyAndFlexibleNoteSurface() {
        let app = launchCleanApp()
        let surface = app.otherElements["workbench-note-surface"]
        let renderedNote = app.renderedNote

        XCTAssertTrue(surface.waitForExistence(timeout: 5))
        XCTAssertEqual(
            renderedNote.label,
            "Add something you want to keep close, then go live on Dynamic Island."
        )
        XCTAssertGreaterThan(surface.frame.height, 310)
    }

    func testNonEditingDockIsBottomAnchored() {
        let app = launchCleanApp()
        let dock = app.otherElements["workbench-action-dock"]

        XCTAssertTrue(dock.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(dock.frame.maxY, app.frame.maxY - 110)
        XCTAssertLessThanOrEqual(dock.frame.maxY, app.frame.maxY)
    }

    func testDockOuterActionsAlignWithNoteSurfaceContentEdges() {
        let app = launchCleanApp()
        let surface = app.otherElements["workbench-note-surface"]
        let move = app.buttons["archive-current-note"]
        let delete = app.buttons["delete-current-note"]

        XCTAssertTrue(surface.waitForExistence(timeout: 5))
        XCTAssertTrue(move.exists)
        XCTAssertTrue(delete.exists)

        // The prototype uses the same centered content region, with the outer
        // Dock controls optically inset 16 pt from the Note Surface edges.
        XCTAssertEqual(
            surface.frame.minX,
            app.frame.minX + PrototypeGeometry.horizontalContentInset,
            accuracy: PrototypeGeometry.alignmentTolerance
        )
        XCTAssertEqual(
            surface.frame.maxX,
            app.frame.maxX - PrototypeGeometry.horizontalContentInset,
            accuracy: PrototypeGeometry.alignmentTolerance
        )
        XCTAssertEqual(
            move.frame.minX,
            surface.frame.minX + PrototypeGeometry.dockOuterControlInset,
            accuracy: PrototypeGeometry.alignmentTolerance
        )
        XCTAssertEqual(
            delete.frame.maxX,
            surface.frame.maxX - PrototypeGeometry.dockOuterControlInset,
            accuracy: PrototypeGeometry.alignmentTolerance
        )
        XCTAssertEqual(
            move.frame.width,
            PrototypeGeometry.dockSideActionSize,
            accuracy: PrototypeGeometry.alignmentTolerance
        )
        XCTAssertEqual(
            move.frame.height,
            PrototypeGeometry.dockSideActionSize,
            accuracy: PrototypeGeometry.alignmentTolerance
        )
        XCTAssertEqual(
            delete.frame.width,
            move.frame.width,
            accuracy: PrototypeGeometry.alignmentTolerance
        )
        XCTAssertEqual(
            delete.frame.height,
            move.frame.height,
            accuracy: PrototypeGeometry.alignmentTolerance
        )

        let live = app.buttons["toggle-pin"]
        XCTAssertEqual(
            live.frame.width,
            PrototypeGeometry.dockLiveActionWidth,
            accuracy: PrototypeGeometry.alignmentTolerance
        )
        XCTAssertEqual(
            live.frame.height,
            PrototypeGeometry.dockActionHeight,
            accuracy: PrototypeGeometry.alignmentTolerance
        )
    }

    func testEmptyNoteCharacterCountAndLiveKeepDockAtSameY() {
        let app = launchCleanApp()
        let dock = app.otherElements["workbench-action-dock"]

        XCTAssertTrue(dock.waitForExistence(timeout: 5))
        let emptyY = dock.frame.midY

        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("A stable dock note")
        let characterProgress = app.buttons["character-progress"]
        XCTAssertTrue(characterProgress.isHittable)
        characterProgress.tap()
        app.buttons["done-editing"].tap()
        XCTAssertTrue(dock.waitForExistence(timeout: 3))
        let noteY = dock.frame.midY
        XCTAssertFalse(characterProgress.exists)
        let characterCountY = dock.frame.midY

        let live = app.buttons["toggle-pin"]
        XCTAssertTrue(live.isHittable)
        live.tap()
        waitForLabel("Live", on: live)
        let liveY = dock.frame.midY

        XCTAssertEqual(noteY, emptyY, accuracy: 1)
        XCTAssertEqual(characterCountY, emptyY, accuracy: 1)
        XCTAssertEqual(liveY, emptyY, accuracy: 1)
    }

    func testEditingRemovesDockAndPlacesCommitBarOutsideSurfaceAboveKeyboard() {
        let app = launchCleanApp()
        _ = beginWorkbenchEditing(in: app)

        XCTAssertFalse(app.otherElements["workbench-action-dock"].exists)
        XCTAssertFalse(app.buttons["archive-current-note"].exists)
        XCTAssertFalse(app.buttons["toggle-pin"].exists)
        XCTAssertFalse(app.buttons["delete-current-note"].exists)

        let surface = app.otherElements["workbench-note-surface"]
        let commitBar = app.otherElements["editing-commit-bar"]
        let done = app.buttons["done-editing"]
        let keyboard = app.keyboards.firstMatch

        XCTAssertTrue(surface.exists)
        XCTAssertTrue(commitBar.exists)
        XCTAssertTrue(done.exists)
        XCTAssertTrue(keyboard.waitForExistence(timeout: 2))
        XCTAssertTrue(done.isHittable)
        XCTAssertGreaterThanOrEqual(done.frame.height, 44)
        XCTAssertGreaterThanOrEqual(done.frame.minY, surface.frame.maxY)
        XCTAssertLessThanOrEqual(done.frame.maxY, keyboard.frame.minY)
        XCTAssertGreaterThanOrEqual(done.frame.width, app.frame.width - 48)
    }

    func testLiveTransitionPreservesCenterPillFrame() {
        let app = launchCleanApp()
        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("A stable dock note")
        app.buttons["done-editing"].tap()

        let live = app.buttons["toggle-pin"]
        XCTAssertTrue(live.waitForExistence(timeout: 3))
        let readyFrame = live.frame
        let expectedIndicatorCenter = CGPoint(
            x: PrototypeGeometry.liveIndicatorCenterX,
            y: readyFrame.height / 2
        )
        let readyScreenshot = live.screenshot()
        attach(readyScreenshot, named: "live-control-ready")
        let readyIndicatorCenter = indicatorCentroid(
            in: readyScreenshot.image,
            liveFrame: CGRect(origin: .zero, size: readyFrame.size),
            appearance: .hollow,
            expectedCenter: expectedIndicatorCenter
        )
        XCTAssertEqual(
            readyIndicatorCenter.x,
            expectedIndicatorCenter.x,
            accuracy: PrototypeGeometry.indicatorCenterTolerance
        )
        XCTAssertEqual(
            readyIndicatorCenter.y,
            expectedIndicatorCenter.y,
            accuracy: PrototypeGeometry.indicatorCenterTolerance
        )
        live.tap()

        waitForLabel("Live", on: live)
        waitForRenderedStateToSettle()
        XCTAssertEqual(live.frame.minX, readyFrame.minX, accuracy: 0.5)
        XCTAssertEqual(live.frame.minY, readyFrame.minY, accuracy: 0.5)
        XCTAssertEqual(live.frame.width, readyFrame.width, accuracy: 0.5)
        XCTAssertEqual(live.frame.height, readyFrame.height, accuracy: 0.5)
        let liveScreenshot = live.screenshot()
        attach(liveScreenshot, named: "live-control-active")
        let liveIndicatorCenter = indicatorCentroid(
            in: liveScreenshot.image,
            liveFrame: CGRect(origin: .zero, size: live.frame.size),
            appearance: .live,
            expectedCenter: expectedIndicatorCenter
        )
        XCTAssertEqual(
            liveIndicatorCenter.x,
            readyIndicatorCenter.x,
            accuracy: PrototypeGeometry.indicatorCenterTolerance,
            "Go Live's hollow circle and Live's green dot must keep the same center"
        )
        XCTAssertEqual(
            liveIndicatorCenter.y,
            readyIndicatorCenter.y,
            accuracy: PrototypeGeometry.indicatorCenterTolerance,
            "Changing Live state must not move the indicator vertically"
        )

        let header = app.otherElements["workbench-header"]
        XCTAssertFalse(header.staticTexts["Live"].exists)
        XCTAssertFalse(header.staticTexts["Not Live"].exists)
    }

    func testAccessibilityXXXLKeepsAllDockActionsHorizontalAndOnScreen() {
        let app = launchCleanApp(accessibilityXXXL: true)
        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("Maximum Dynamic Type")
        app.buttons["done-editing"].tap()

        let move = app.buttons["archive-current-note"]
        let live = app.buttons["toggle-pin"]
        let delete = app.buttons["delete-current-note"]

        for action in [move, live, delete] {
            XCTAssertTrue(action.waitForExistence(timeout: 3))
            XCTAssertTrue(action.isHittable)
            XCTAssertGreaterThanOrEqual(action.frame.width, 44)
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
            XCTAssertGreaterThanOrEqual(action.frame.minX, app.frame.minX)
            XCTAssertGreaterThanOrEqual(action.frame.minY, app.frame.minY)
            XCTAssertLessThanOrEqual(action.frame.maxX, app.frame.maxX)
            XCTAssertLessThanOrEqual(action.frame.maxY, app.frame.maxY)
        }

        XCTAssertLessThan(move.frame.midX, live.frame.midX)
        XCTAssertLessThan(live.frame.midX, delete.frame.midX)
        XCTAssertEqual(move.frame.midY, live.frame.midY, accuracy: 1)
        XCTAssertEqual(live.frame.midY, delete.frame.midY, accuracy: 1)

        let dock = app.otherElements["workbench-action-dock"]
        XCTAssertEqual(
            dock.buttons.allElementsBoundByIndex.map(\.identifier),
            ["archive-current-note", "toggle-pin", "delete-current-note"]
        )
        XCTAssertFalse(app.scrollViews["workbench-root"].exists)
    }

    private func waitForLabel(
        _ label: String,
        on element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", label),
            object: element
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 3),
            .completed,
            file: file,
            line: line
        )
    }

    private func waitForRenderedStateToSettle() {
        let settled = expectation(description: "Live control renders its final state")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            settled.fulfill()
        }
        wait(for: [settled], timeout: 0.5)
    }

    private func attach(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private enum IndicatorAppearance {
        case hollow
        case live
    }

    /// Locates the rendered indicator without adding a duplicate element to the
    /// VoiceOver tree. The search window is based on the prototype's 18 pt
    /// leading indicator slot and intentionally excludes the state label.
    private func indicatorCentroid(
        in image: UIImage,
        liveFrame: CGRect,
        appearance: IndicatorAppearance,
        expectedCenter: CGPoint? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CGPoint {
        guard let pixels = PixelBuffer(image: image) else {
            XCTFail("Could not inspect the Workbench screenshot", file: file, line: line)
            return .zero
        }

        let searchRect: CGRect
        if let expectedCenter {
            searchRect = CGRect(
                x: expectedCenter.x - 12,
                y: expectedCenter.y - 12,
                width: 24,
                height: 24
            )
        } else {
            searchRect = CGRect(
                x: liveFrame.minX + 20,
                y: liveFrame.midY - 14,
                width: 38,
                height: 28
            )
        }
        let background = pixels.color(
            at: CGPoint(x: liveFrame.minX + 16, y: liveFrame.midY)
        )
        var weightedX: CGFloat = 0
        var weightedY: CGFloat = 0
        var totalWeight: CGFloat = 0

        pixels.forEachPixel(in: searchRect) { point, color in
            let weight: CGFloat
            switch appearance {
            case .hollow:
                let channelSpread = max(color.red, color.green, color.blue)
                    - min(color.red, color.green, color.blue)
                let contrast = abs(color.luminance - background.luminance)
                weight = channelSpread < 0.16 && contrast > 0.14 ? contrast : 0
            case .live:
                // The backing buffer is normalized to RGBA, so saturation
                // isolates the green dot from the neutral capsule and text.
                let channelSpread = max(color.red, color.green, color.blue)
                    - min(color.red, color.green, color.blue)
                weight = channelSpread > 0.08 ? channelSpread : 0
            }

            guard weight > 0 else { return }
            weightedX += point.x * weight
            weightedY += point.y * weight
            totalWeight += weight
        }

        guard totalWeight > 1 else {
            XCTFail("Could not locate the rendered Live indicator", file: file, line: line)
            return .zero
        }
        return CGPoint(x: weightedX / totalWeight, y: weightedY / totalWeight)
    }

    private func launchCleanApp(accessibilityXXXL: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting-reset",
            "--uitesting-fake-live-activity",
            "--uitesting-appearance-suite",
            "WorkbenchLayoutContractUITests.clean",
            "--uitesting-reset-appearance",
        ]
        if accessibilityXXXL {
            app.launchArguments += [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            ]
        }
        app.launch()
        return app
    }
}

private struct PixelColor {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    var luminance: CGFloat {
        (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    }
}

private struct PixelBuffer {
    private let bytes: [UInt8]
    private let width: Int
    private let height: Int
    private let scaleX: CGFloat
    private let scaleY: CGFloat

    init?(image: UIImage) {
        guard let cgImage = image.cgImage else { return nil }
        width = cgImage.width
        height = cgImage.height
        scaleX = CGFloat(width) / image.size.width
        scaleY = CGFloat(height) / image.size.height

        var storage = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &storage,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue
                | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        bytes = storage
    }

    func color(at point: CGPoint) -> PixelColor {
        let x = min(max(Int(point.x * scaleX), 0), width - 1)
        let y = min(max(Int(point.y * scaleY), 0), height - 1)
        let index = ((y * width) + x) * 4
        return PixelColor(
            red: CGFloat(bytes[index + 2]) / 255,
            green: CGFloat(bytes[index + 1]) / 255,
            blue: CGFloat(bytes[index]) / 255
        )
    }

    func forEachPixel(
        in rect: CGRect,
        perform: (CGPoint, PixelColor) -> Void
    ) {
        let minX = max(Int(rect.minX * scaleX), 0)
        let maxX = min(Int(rect.maxX * scaleX), width - 1)
        let minY = max(Int(rect.minY * scaleY), 0)
        let maxY = min(Int(rect.maxY * scaleY), height - 1)

        for y in minY...maxY {
            for x in minX...maxX {
                let point = CGPoint(
                    x: (CGFloat(x) + 0.5) / scaleX,
                    y: (CGFloat(y) + 0.5) / scaleY
                )
                perform(point, color(at: point))
            }
        }
    }
}
