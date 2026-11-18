import AppKit
import SwiftUI
import XCTest
@testable import LiveryKit

/// The `NSColor`/`Color` bridge: live colours route through `RGBA8`, so the
/// hex grammar itself is asserted in LiveryCoreTests.
final class ColorHexTests: XCTestCase {

    // MARK: NSColor parsing

    func testNSColorParsesSixDigitHex() {
        let red = NSColor(hex: "#FF0000")
        XCTAssertNotNil(red)
        let srgb = red!.usingColorSpace(.sRGB)!
        XCTAssertEqual(srgb.redComponent, 1, accuracy: 0.01)
        XCTAssertEqual(srgb.greenComponent, 0, accuracy: 0.01)
        XCTAssertEqual(srgb.blueComponent, 0, accuracy: 0.01)
    }

    func testNSColorParsesEightDigitHexWithAlpha() {
        let color = NSColor(hex: "#abcd")
        XCTAssertNotNil(color)
        let srgb = color!.usingColorSpace(.sRGB)!
        XCTAssertEqual(srgb.redComponent, CGFloat(0xAA) / 255, accuracy: 0.001)
        XCTAssertEqual(srgb.greenComponent, CGFloat(0xBB) / 255, accuracy: 0.001)
        XCTAssertEqual(srgb.blueComponent, CGFloat(0xCC) / 255, accuracy: 0.001)
        XCTAssertEqual(srgb.alphaComponent, CGFloat(0xDD) / 255, accuracy: 0.001)
    }

    func testNSColorParsesLowercaseEightDigitHex() {
        XCTAssertNotNil(NSColor(hex: "#0a84ffcc"))
    }

    func testNSColorRejectsInvalidHex() {
        XCTAssertNil(NSColor(hex: "+84FF0"))
        XCTAssertNil(NSColor(hex: "#+84FF0"))
        XCTAssertNil(NSColor(hex: "-84FF0"))
        XCTAssertNil(NSColor(hex: ""))
        XCTAssertNil(NSColor(hex: "#GGGGGG"))
        XCTAssertNil(NSColor(hex: "#12345"))
        XCTAssertNil(NSColor(hex: "#1234567"))
        XCTAssertNil(NSColor(hex: "not a color"))
    }

    // MARK: Round trips

    /// The bridge has to survive the round trip, not just each half: this is what
    /// catches a conversion that loses precision between `RGBA8` and a live colour.
    func testNSColorHexStringRoundTrip() {
        XCTAssertEqual(NSColor(hex: "#3A7BD5")!.hexString, "#3A7BD5")
        XCTAssertEqual(NSColor(hex: "#3A7BD580")!.hexString, "#3A7BD580")
        XCTAssertEqual(NSColor(hex: "#3A7BD5FF")!.hexString, "#3A7BD5")
        XCTAssertNil(NSColor(hex: "+ABCDEF"))
        // Shorthand expansion went through `NSColor` before the split and only
        // through `RGBA8` after it; keep one case on the bridge so a separate
        // fast path could not skip nibble expansion unnoticed.
        XCTAssertEqual(NSColor(hex: "#abc")!.hexString, "#AABBCC")
    }

    func testSwiftUIColorBridging() {
        XCTAssertEqual(Color(hexString: "#0A84FF").hexString, "#0A84FF")
        XCTAssertEqual(Color(hexString: "#0A84FF80").hexString, "#0A84FF80")
    }

    // MARK: readableForeground

    func testReadableForegroundPicksByLuminance() {
        XCTAssertEqual(Color.readableForeground(on: NSColor(hex: "#FFFFFF") ?? .white),
                       .black)
        XCTAssertEqual(Color.readableForeground(on: NSColor(hex: "#1C1C1E") ?? .black),
                       .white)
        XCTAssertEqual(Color.readableForeground(on: NSColor(hex: "#0A84FF") ?? .blue),
                       .black)
    }

    func testSaturatedHighlightsChooseTheHigherContrastForeground() throws {
        for hex in ["#00FF00", "#00FFFF", "#FF0000", "#808080"] {
            let color = try XCTUnwrap(NSColor(hex: hex))
            XCTAssertEqual(Color.readableForeground(on: color), .black, hex)
        }
        XCTAssertEqual(Color.readableForeground(on: try XCTUnwrap(NSColor(hex: "#0000FF"))),
                       .white)
    }

    // MARK: composited

    func testCompositeAtFullOpacityReturnsTop() {
        let top = NSColor(hex: "#FF0000") ?? .red
        let base = NSColor(hex: "#0000FF") ?? .blue
        let c = top.composited(alpha: 1, over: base).usingColorSpace(.sRGB)
        XCTAssertEqual(c?.redComponent ?? 0, 1, accuracy: 0.01)
        XCTAssertEqual(c?.blueComponent ?? 0, 0, accuracy: 0.01)
    }

    func testCompositeAtHalfOpacityBlends() {
        let top = NSColor(hex: "#FFFFFF") ?? .white
        let base = NSColor.black
        let c = top.composited(alpha: 0.5, over: base).usingColorSpace(.sRGB)
        XCTAssertEqual(c?.redComponent ?? 0, 0.5, accuracy: 0.01)
    }

    func testCompositeMultipliesIntrinsicAlphaByConfiguredOpacity() throws {
        let top = try XCTUnwrap(NSColor(hex: "#FFFFFF80"))
        let c = try XCTUnwrap(top.composited(alpha: 0.5, over: .black).usingColorSpace(.sRGB))
        XCTAssertEqual(c.redComponent, 0.5 * 128 / 255, accuracy: 0.001)
        XCTAssertEqual(c.greenComponent, c.redComponent, accuracy: 0.001)
        XCTAssertEqual(c.blueComponent, c.redComponent, accuracy: 0.001)
        XCTAssertEqual(c.alphaComponent, 1)
    }

    func testTransparentHighlightKeepsBackgroundAndReadableForeground() throws {
        let top = try XCTUnwrap(NSColor(hex: "#FFFFFF00"))
        let c = try XCTUnwrap(top.composited(alpha: 1, over: .black).usingColorSpace(.sRGB))
        XCTAssertEqual(c.redComponent, 0)
        XCTAssertEqual(c.greenComponent, 0)
        XCTAssertEqual(c.blueComponent, 0)
        XCTAssertEqual(Color.readableForeground(on: c), .white)
    }
}
