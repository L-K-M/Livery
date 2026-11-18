import XCTest
@testable import LiveryCore

/// The hex grammar is a storage contract: every build that persists or reads a
/// theme has to agree on exactly which strings are colours.
final class RGBA8Tests: XCTestCase {

    // MARK: Parsing

    func testParsesSixDigitHex() {
        XCTAssertEqual(RGBA8(hex: "#FF0000"), RGBA8(red: 255, green: 0, blue: 0))
        XCTAssertEqual(RGBA8(hex: "#FF8800"),
                       RGBA8(red: 0xFF, green: 0x88, blue: 0x00, alpha: 0xFF))
    }

    func testParsesEightDigitHexWithAlpha() {
        let c = RGBA8(hex: "#10203040")
        XCTAssertEqual(c?.alpha, 0x40)
        XCTAssertEqual(c?.red, 0x10)
        XCTAssertEqual(c?.green, 0x20)
        XCTAssertEqual(c?.blue, 0x30)
    }

    func testLeadingHashOptional() {
        XCTAssertEqual(RGBA8(hex: "00FF00"), RGBA8(red: 0, green: 255, blue: 0))
        XCTAssertEqual(RGBA8(hex: "FF8800"), RGBA8(hex: "#FF8800"))
    }

    func testWhitespaceIsTrimmed() {
        XCTAssertEqual(RGBA8(hex: "  #abcdef  "), RGBA8(hex: "#ABCDEF"))
        XCTAssertEqual(RGBA8(hex: "\t#ABC\n"), RGBA8(hex: "#AABBCC"))
    }

    func testShorthandRGBExpandsNibbles() {
        // #abc must decode exactly like #aabbcc.
        XCTAssertEqual(RGBA8(hex: "#abc")?.hexString, "#AABBCC")
        // Against the concrete expansion, not against the other spelling: two
        // nils compare equal, so a parser that regressed to returning nil for
        // both forms would pass the relative version.
        XCTAssertEqual(RGBA8(hex: "#abc"), RGBA8(red: 0xAA, green: 0xBB, blue: 0xCC))
        XCTAssertEqual(RGBA8(hex: "#FFF"), RGBA8.white)
    }

    func testShorthandRGBAParsesWithAlpha() {
        XCTAssertEqual(RGBA8(hex: "#abcd"),
                       RGBA8(red: 0xAA, green: 0xBB, blue: 0xCC, alpha: 0xDD))
    }

    func testValidGrammarTable() {
        let cases: [(String, RGBA8)] = [
            ("#FFF", RGBA8(red: 255, green: 255, blue: 255)),
            ("#FFFF", RGBA8(red: 255, green: 255, blue: 255, alpha: 255)),
            ("#000", RGBA8.black),
            ("#00000000", RGBA8(red: 0, green: 0, blue: 0, alpha: 0)),
            ("#3A7BD5", RGBA8(red: 0x3A, green: 0x7B, blue: 0xD5)),
            ("#3A7BD580", RGBA8(red: 0x3A, green: 0x7B, blue: 0xD5, alpha: 0x80)),
            ("11223380", RGBA8(red: 0x11, green: 0x22, blue: 0x33, alpha: 0x80)),
            (" #FfFfFf ", RGBA8.white),
        ]
        for (input, expected) in cases {
            XCTAssertEqual(RGBA8(hex: input), expected, input)
        }
    }

    func testInvalidGrammarTable() {
        let inputs = [
            "", "#", "#12", "#12345", "#1234567", "#GGGGGG",
            "+12345", "+ABCDEF", "#+ABCDE", "-ABCDEF", "not a color",
        ]
        for input in inputs {
            XCTAssertNil(RGBA8(hex: input), input)
        }
    }

    func testSignedHexRejected() {
        // `UInt64(_, radix: 16)` accepts a leading "+"; the parser must not.
        XCTAssertNil(RGBA8(hex: "+ABCDE"))
        XCTAssertNil(RGBA8(hex: "+ABCDEF"))
        XCTAssertNil(RGBA8(hex: "#+ABCDE"))
        XCTAssertNil(RGBA8(hex: "-ABCDEF"))
    }

    // MARK: Formatting

    func testHexStringRoundTrip() {
        XCTAssertEqual(RGBA8(hex: "#3A7BD5")?.hexString, "#3A7BD5")
        XCTAssertEqual(RGBA8(hex: "#B18CFF")?.hexString, "#B18CFF")
    }

    func testOpaqueColorEmitsSixDigits() {
        // Fully opaque stays #RRGGBB, even when parsed from an 8-digit string.
        XCTAssertEqual(RGBA8(hex: "#3A7BD5FF")?.hexString, "#3A7BD5")
    }

    func testAlphaRoundTripsThroughHexString() {
        // Translucent colors emit #RRGGBBAA and survive a parse → format cycle.
        XCTAssertEqual(RGBA8(hex: "#3A7BD580")?.hexString, "#3A7BD580")
        XCTAssertEqual(RGBA8(hex: "#3A7BD500")?.hexString, "#3A7BD500")
        XCTAssertEqual(RGBA8(hex: "#11223380")?.hexString, "#11223380")
    }

    func testShorthandRoundTripsToLongForm() {
        XCTAssertEqual(RGBA8(hex: "#FFF")?.hexString, "#FFFFFF")
        XCTAssertEqual(RGBA8(hex: "#abcd")?.hexString, "#AABBCCDD")
    }

    // MARK: Clamping

    /// Components outside 0...1 clamp instead of formatting to a string that no
    /// longer parses: the bug that turned a wide-gamut colour into `.clear` on
    /// the next read.
    func testClampingComponentsStayInRange() {
        let clamped = RGBA8(clampingRed: 1.4, green: -0.3, blue: 0.5, alpha: 1)
        XCTAssertEqual(clamped, RGBA8(red: 255, green: 0, blue: 128))
        XCTAssertEqual(clamped.hexString, "#FF0080")
        XCTAssertNotNil(RGBA8(hex: clamped.hexString), "a clamped colour must re-parse")
    }

    /// Non-finite components. NaN is the one value the clamp did not clamp: every
    /// comparison against it is false, so it passed through `max` and `min`
    /// untouched and trapped in the `UInt8` conversion, a crash in the
    /// persistence path. ±infinity is different and must stay different: the
    /// clamp already maps it to black and white, which is the right answer.
    func testNonFiniteComponentsClampRatherThanTrap() {
        XCTAssertEqual(RGBA8(clampingRed: .nan, green: 0, blue: 0, alpha: 1),
                       RGBA8(red: 0, green: 0, blue: 0, alpha: 255))
        XCTAssertEqual(RGBA8(clampingRed: .infinity, green: -.infinity, blue: 0.5, alpha: .nan),
                       RGBA8(red: 255, green: 0, blue: 128, alpha: 0))
    }

    // MARK: Constants and conformances

    func testBlackAndWhiteConstants() {
        XCTAssertEqual(RGBA8.black, RGBA8(red: 0, green: 0, blue: 0))
        XCTAssertEqual(RGBA8.white, RGBA8(red: 255, green: 255, blue: 255))
    }

    func testHashable() {
        var set: Set<RGBA8> = [.black, .white]
        set.insert(RGBA8(red: 0, green: 0, blue: 0))
        XCTAssertEqual(set.count, 2)
    }
}
