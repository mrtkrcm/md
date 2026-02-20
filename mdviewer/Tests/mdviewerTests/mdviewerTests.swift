#if canImport(XCTest)
import XCTest
@testable import mdviewer

final class mdviewerTests: XCTestCase {
    func testAppThemeRawValuesRemainStable() {
        XCTAssertEqual(AppTheme.basic.rawValue, "Basic")
        XCTAssertEqual(AppTheme.github.rawValue, "GitHub")
        XCTAssertEqual(AppTheme.docC.rawValue, "DocC")
    }

    func testSyntaxPalettesRemainStable() {
        XCTAssertEqual(SyntaxPalette.sundellsColors.rawValue, "Sundell's Colors")
        XCTAssertEqual(SyntaxPalette.midnight.rawValue, "Midnight")
        XCTAssertEqual(SyntaxPalette.sunset.rawValue, "Sunset")
    }
}
#endif
