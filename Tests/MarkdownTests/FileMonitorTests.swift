import XCTest

final class FileMonitorTests: XCTestCase {

    func testShouldReloadWhenSizeChanges() {
        XCTAssertTrue(FileMonitorHelpers.shouldReload(
            newSize: 100, newMtime: date(0),
            knownSize: 50, knownMtime: date(0)
        ))
    }

    func testShouldReloadWhenMtimeChanges() {
        XCTAssertTrue(FileMonitorHelpers.shouldReload(
            newSize: 100, newMtime: date(1),
            knownSize: 100, knownMtime: date(0)
        ))
    }

    func testShouldNotReloadWhenUnchanged() {
        XCTAssertFalse(FileMonitorHelpers.shouldReload(
            newSize: 100, newMtime: date(0),
            knownSize: 100, knownMtime: date(0)
        ))
    }

    func testShouldReloadWhenBothChange() {
        XCTAssertTrue(FileMonitorHelpers.shouldReload(
            newSize: 200, newMtime: date(5),
            knownSize: 100, knownMtime: date(0)
        ))
    }

    private func date(_ offset: TimeInterval) -> Date {
        Date(timeIntervalSince1970: 1_000_000 + offset)
    }
}
