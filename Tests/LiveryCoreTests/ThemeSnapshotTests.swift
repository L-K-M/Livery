import XCTest
@testable import LiveryCore

final class ThemeSnapshotTests: XCTestCase {

    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json",
                                                  subdirectory: "Fixtures"),
                                "missing fixture \(name).json")
        return try Data(contentsOf: url)
    }

    private func snapshot(_ json: String) -> ThemeSnapshot? {
        ThemeSnapshot(themeData: Data(json.utf8))
    }

    // MARK: Conformance: each app's exported built-in theme

    func testReadsZapExport() throws {
        let theme = try XCTUnwrap(ThemeSnapshot(themeData: try fixture("zap-zx-night")))

        XCTAssertEqual(theme, ThemeSnapshot(
            format: .zap,
            name: "ZX Night",
            material: .gradient,
            tintHex: "#0B0B1A",
            gradientHex: "#1A1140",
            gradientAngle: 20,
            backgroundOpacity: 0.7,
            cornerRadius: 14,
            highlightHex: "#00AEEF",
            highlightOpacity: 0.85,
            highlightCornerRadius: 12,
            labelHex: "#FFFFFF",
            iconSize: 80,
            showsLabels: true,
            adaptiveAccent: nil,
            decorationStyle: .zxSpectrum,
            decorationPosition: .topTrailing,
            decorationOpacity: 1,
            decorationSize: 12,
            crtEnabled: true,
            crtIntensity: 0.5))
    }

    func testReadsJettyExport() throws {
        let theme = try XCTUnwrap(ThemeSnapshot(themeData: try fixture("jetty-vapor")))

        XCTAssertEqual(theme, ThemeSnapshot(
            format: .jetty,
            name: "Vapor",
            material: .gradient,
            tintHex: "#FF6AD5",
            gradientHex: "#8795E8",
            gradientAngle: 60,
            backgroundOpacity: 0.7,
            cornerRadius: 24,
            iconSize: 50,
            showsLabels: false,
            adaptiveAccent: true,
            decorationStyle: .vaporwave,
            decorationPosition: .topTrailing,
            decorationOpacity: 1,
            decorationSize: 12,
            crtEnabled: true,
            crtIntensity: 0.5))
    }

    func testReadsInvoqueExport() throws {
        let theme = try XCTUnwrap(ThemeSnapshot(themeData: try fixture("invoque-summon")))

        XCTAssertEqual(theme, ThemeSnapshot(
            format: .invoque,
            name: "Summon",
            material: .gradient,
            tintHex: "#17122B",
            gradientHex: "#2A1F4D",
            gradientAngle: 30,
            backgroundOpacity: 0.9,
            cornerRadius: 16,
            highlightHex: "#B18CFF",
            highlightOpacity: 0.4,
            highlightCornerRadius: 10,
            labelHex: "#EDE9FF",
            adaptiveAccent: true,
            decorationStyle: DecorationStyle.none,
            decorationPosition: .topTrailing,
            decorationOpacity: 1,
            decorationSize: 10,
            crtEnabled: false,
            crtIntensity: 0.5))
    }

    // MARK: Format detection

    func testZapSolidBackgroundIsSolidMaterial() {
        XCTAssertEqual(snapshot(##"{"useGradientBackground": false}"##)?.material, .solid)
        XCTAssertEqual(snapshot(##"{"backgroundColorHex": "#112233"}"##)?.material, .solid,
                       "a Zap theme without the flag still paints a solid background")
    }

    func testEveryZapOnlyKeyIdentifiesZap() {
        for key in ThemeSnapshot.FormatKeys.zap {
            XCTAssertEqual(ThemeSnapshot.format(forKeys: [key, "cornerRadius"]), .zap, key)
        }
    }

    func testEveryJettyOnlyKeyIdentifiesJetty() {
        for key in ThemeSnapshot.FormatKeys.jetty {
            XCTAssertEqual(ThemeSnapshot.format(forKeys: [key, "cornerRadius"]), .jetty, key)
        }
    }

    func testEveryInvoqueOnlyKeyIdentifiesInvoque() {
        for key in ThemeSnapshot.FormatKeys.invoque {
            XCTAssertEqual(ThemeSnapshot.format(forKeys: [key, "material", "tintHex"]), .invoque, key)
        }
    }

    func testMinimalSharedKeysReadAsJetty() {
        XCTAssertEqual(snapshot(##"{"material": "solid", "tintHex": "#101010"}"##)?.format, .jetty)
        XCTAssertEqual(snapshot(##"{"gradientHex": "#101010"}"##)?.format, .jetty)
    }

    /// Keys every format shares cannot pick one, so a file holding only
    /// those is not recognised as a theme.
    func testFileWithOnlySharedKeysIsRejected() {
        XCTAssertNil(snapshot(##"{"name": "X", "cornerRadius": 12, "decorationStyle": "amiga", "crtEnabled": true}"##))
        XCTAssertNil(snapshot(##"{"tabs": [], "version": 3}"##))
        XCTAssertNil(snapshot("{}"))
    }

    func testNonObjectJSONIsRejected() {
        XCTAssertNil(snapshot("[]"))
        XCTAssertNil(snapshot(##""material""##))
        XCTAssertNil(snapshot("not json"))
        XCTAssertNil(ThemeSnapshot(themeData: Data()))
    }

    // MARK: Tolerance

    func testWrongTypedFieldBecomesNilWithoutFailingTheImport() throws {
        let theme = try XCTUnwrap(snapshot(##"""
        {"material": "gradient", "gradientAngle": "30", "crtEnabled": 1,
         "cornerRadius": 18, "tintHex": 42}
        """##))

        XCTAssertNil(theme.gradientAngle)
        XCTAssertNil(theme.crtEnabled)
        XCTAssertNil(theme.tintHex)
        XCTAssertEqual(theme.cornerRadius, 18)
        XCTAssertEqual(theme.material, .gradient)
    }

    func testUnknownEnumValuesBecomeNil() throws {
        let theme = try XCTUnwrap(snapshot(##"""
        {"material": "holographic", "decorationStyle": "plaid", "decorationPosition": "middle"}
        """##))

        XCTAssertNil(theme.material)
        XCTAssertNil(theme.decorationStyle)
        XCTAssertNil(theme.decorationPosition)
    }

    func testUnparseableColorsBecomeNil() throws {
        let zap = try XCTUnwrap(snapshot(##"""
        {"backgroundColorHex": "blue", "highlightColorHex": "#12", "labelColorHex": "#ABC"}
        """##))
        XCTAssertNil(zap.tintHex)
        XCTAssertNil(zap.highlightHex)
        XCTAssertEqual(zap.labelHex, "#ABC", "CSS shorthand is a valid color")

        let invoque = try XCTUnwrap(snapshot(##"{"labelHex": "-FFFFFF", "highlightHex": "#11223344"}"##))
        XCTAssertNil(invoque.labelHex)
        XCTAssertEqual(invoque.highlightHex, "#11223344")
    }

    func testNameIsTrimmedAndBlankNamesAreNil() {
        XCTAssertEqual(snapshot(##"{"labelHex": "#FFF", "name": "  Dusk \n"}"##)?.name, "Dusk")
        XCTAssertNil(snapshot(##"{"labelHex": "#FFF", "name": "   "}"##)?.name)
        XCTAssertNil(snapshot(##"{"labelHex": "#FFF", "name": 7}"##)?.name)
    }

    func testJettyAccentGlowAndInvoqueAdaptiveAccentAreTheSameSetting() {
        XCTAssertEqual(snapshot(##"{"tileSpacing": 8, "accentGlow": false}"##)?.adaptiveAccent, false)
        XCTAssertEqual(snapshot(##"{"labelHex": "#FFF", "adaptiveAccent": true}"##)?.adaptiveAccent, true)
    }

    /// Numbers pass through unclamped: each app applies its own ranges.
    func testNumbersAreNotClamped() {
        let theme = snapshot(##"{"tileSpacing": 8, "iconSize": 4000, "backgroundOpacity": -2}"##)
        XCTAssertEqual(theme?.iconSize, 4000)
        XCTAssertEqual(theme?.backgroundOpacity, -2)
    }
}
