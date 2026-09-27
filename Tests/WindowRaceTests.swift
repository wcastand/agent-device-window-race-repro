import XCTest

final class WindowRaceTests: XCTestCase {
    // Original resolver from callstack/agent-device 0.21.15. See LICENSE.
    func original(app: XCUIApplication) -> (window: XCUIElement?, frame: CGRect) {
        let windows = app.windows.allElementsBoundByIndex
        var frames: [CGRect?] = []
        for window in windows {
            frames.append(window.exists ? window.frame : nil)
        }
        if let index = Self.firstUsableWindowIndex(frames: frames) {
            return (windows[index], frames[index] ?? .zero)
        }
        return (nil, app.frame)
    }

    static func firstUsableWindowIndex(frames: [CGRect?]) -> Int? {
        for (index, frame) in frames.enumerated() {
            if let frame, !frame.isEmpty { return index }
        }
        return nil
    }

    func patched(app: XCUIApplication) -> (window: XCUIElement?, frame: CGRect) {
        let windows = app.windows.allElementsBoundByIndex
        for window in windows where window.exists {
            let frame = window.frame
            if !frame.isEmpty { return (window, frame) }
        }
        return (nil, app.frame)
    }

    @MainActor
    func exercise(patched usePatch: Bool) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let deadline = Date().addingTimeInterval(60)
        var completed = 0
        for iteration in 0..<6000 {
            if Date() >= deadline { break }
            print("RESOLVE iteration=\(iteration) patched=\(usePatch)")
            let result = usePatch ? patched(app: app) : original(app: app)
            XCTAssertNotNil(result.window)
            XCTAssertFalse(result.frame.isEmpty)
            completed += 1
        }
        print("COMPLETED count=\(completed) patched=\(usePatch)")
        XCTAssertGreaterThan(completed, 0)
        app.terminate()
    }

    @MainActor func testOriginal() { exercise(patched: false) }
    @MainActor func testPatched() { exercise(patched: true) }
}
