#if canImport(XCTest)
import XCTest
@testable import mdviewer

final class mdviewerTests: XCTestCase {
    func testAppThemeRawValuesRemainStable() {
        XCTAssertEqual(AppTheme.basic.rawValue, "Basic")
        XCTAssertEqual(AppTheme.gitHub.rawValue, "GitHub")
        XCTAssertEqual(AppTheme.docC.rawValue, "DocC")
    }
}
#endif
