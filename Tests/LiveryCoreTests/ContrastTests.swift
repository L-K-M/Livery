import XCTest
@testable import LiveryCore

/// WCAG 2.2 contrast maths, checked against published reference values.
final class ContrastTests: XCTestCase {

    func testBlackAndWhiteLuminance() {
        XCTAssertEqual(Contrast.relativeLuminance(red: 0, green: 0, blue: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(Contrast.relativeLuminance(red: 1, green: 1, blue: 1), 1, accuracy: 0.0001)
        XCTAssertEqual(Contrast.relativeLuminance(RGBA8.black), 0, accuracy: 0.0001)
        XCTAssertEqual(Contrast.relativeLuminance(RGBA8.white), 1, accuracy: 0.0001)
    }

    func testLuminanceInputsAreClamped() {
        XCTAssertEqual(Contrast.relativeLuminance(red: 1.4, green: -0.3, blue: 0.5),
                       Contrast.relativeLuminance(red: 1, green: 0, blue: 0.5),
                       accuracy: 0.0001)
    }

    func testBlackOnWhiteIs21ToOne() {
        XCTAssertEqual(Contrast.ratio(RGBA8.black, RGBA8.white), 21, accuracy: 0.001)
    }

    func testRatioIsOrderIndependent() {
        let black = Contrast.relativeLuminance(RGBA8.black)
        let white = Contrast.relativeLuminance(RGBA8.white)
        XCTAssertEqual(Contrast.ratio(black, white), Contrast.ratio(white, black), accuracy: 0.0001)
    }

    func testSevenSevenSevenOnWhiteIsAbout4Point48() {
        let ratio = Contrast.ratio(RGBA8(hex: "#777777")!, RGBA8.white)
        XCTAssertEqual(ratio, 4.48, accuracy: 0.01)
    }

    func testRGBArgumentRatioMatchesColourRatio() {
        let a = RGBA8(hex: "#3A7BD5")!
        let b = RGBA8(hex: "#F5E6C8")!
        XCTAssertEqual(Contrast.ratio(a, b),
                       Contrast.ratio(Contrast.relativeLuminance(a),
                                      Contrast.relativeLuminance(b)),
                       accuracy: 0.0001)
    }

    func testPrefersBlackForeground() {
        XCTAssertFalse(Contrast.prefersBlackForeground(luminance: 0))
        XCTAssertTrue(Contrast.prefersBlackForeground(luminance: 1))
        // Mid grey: black text still reads better than white.
        XCTAssertTrue(Contrast.prefersBlackForeground(
            luminance: Contrast.relativeLuminance(RGBA8(hex: "#777777")!)))
        // A saturated blue is dark enough to take black text.
        XCTAssertTrue(Contrast.prefersBlackForeground(
            luminance: Contrast.relativeLuminance(RGBA8(hex: "#0A84FF")!)))
    }

    func testMinimumRatios() {
        XCTAssertEqual(Contrast.minimumTextRatio, 4.5)
        XCTAssertEqual(Contrast.minimumNonTextRatio, 3.0)
    }
}
