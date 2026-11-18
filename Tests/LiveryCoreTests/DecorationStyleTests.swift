import XCTest
@testable import LiveryCore

/// `DecorationStyle` raw values are persisted, and its palette hex strings are
/// the stripe colours the views draw.
final class DecorationStyleTests: XCTestCase {

    func testRawValuesAreStableAndOrdered() {
        XCTAssertEqual(DecorationStyle.allCases.map(\.rawValue), [
            "none", "zxSpectrum", "appleRainbow", "vaporwave", "sunset",
            "love", "memphis", "synthwave", "amiga", "amigaPixel",
        ])
    }

    func testIDIsRawValue() {
        for style in DecorationStyle.allCases {
            XCTAssertEqual(style.id, style.rawValue)
        }
    }

    func testLabelsAreNonEmpty() {
        for style in DecorationStyle.allCases {
            XCTAssertFalse(style.label.isEmpty, style.rawValue)
        }
    }

    func testKinds() {
        XCTAssertEqual(DecorationStyle.none.kind, .stripes)
        XCTAssertEqual(DecorationStyle.zxSpectrum.kind, .stripes)
        XCTAssertEqual(DecorationStyle.appleRainbow.kind, .stripes)
        XCTAssertEqual(DecorationStyle.vaporwave.kind, .stripes)
        XCTAssertEqual(DecorationStyle.sunset.kind, .stripes)
        XCTAssertEqual(DecorationStyle.love.kind, .stripes)
        XCTAssertEqual(DecorationStyle.memphis.kind, .stripes)
        XCTAssertEqual(DecorationStyle.synthwave.kind, .stripes)
        XCTAssertEqual(DecorationStyle.amiga.kind, .ball)
        XCTAssertEqual(DecorationStyle.amigaPixel.kind, .ball)
    }

    func testNoneAndBallStylesHaveNoStripes() {
        XCTAssertTrue(DecorationStyle.none.hexStrings.isEmpty)
        XCTAssertTrue(DecorationStyle.amiga.hexStrings.isEmpty)
        XCTAssertTrue(DecorationStyle.amigaPixel.hexStrings.isEmpty)
    }

    func testStripeCounts() {
        let counts: [DecorationStyle: Int] = [
            .zxSpectrum: 4,
            .appleRainbow: 6,
            .vaporwave: 5,
            .sunset: 3,
            .love: 6,
            .memphis: 4,
            .synthwave: 3,
        ]
        for (style, count) in counts {
            XCTAssertEqual(style.hexStrings.count, count, style.rawValue)
        }
    }

    /// Every palette entry must be a parseable opaque hex colour; a malformed
    /// value would silently become `.clear` through `Color(hexString:)` and
    /// render an invisible stripe.
    func testEveryStripeHexParses() {
        for style in DecorationStyle.allCases {
            for hex in style.hexStrings {
                let color = RGBA8(hex: hex)
                XCTAssertNotNil(color, "\(style.rawValue): \(hex)")
                XCTAssertEqual(color?.alpha, 255, "\(style.rawValue): \(hex)")
                XCTAssertEqual(hex, hex.uppercased(), "\(style.rawValue): \(hex)")
            }
        }
    }
}
