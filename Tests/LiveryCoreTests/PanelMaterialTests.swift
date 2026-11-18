import XCTest
@testable import LiveryCore

final class PanelMaterialTests: XCTestCase {

    func testRawValuesAreStableAndOrdered() {
        XCTAssertEqual(PanelMaterial.allCases.map(\.rawValue), [
            "liquidGlass", "glassClear", "glassTinted", "solid", "gradient",
        ])
    }

    func testIDIsRawValue() {
        for material in PanelMaterial.allCases {
            XCTAssertEqual(material.id, material.rawValue)
        }
    }

    func testLabelsAreNonEmpty() {
        for material in PanelMaterial.allCases {
            XCTAssertFalse(material.label.isEmpty, material.rawValue)
        }
    }

    func testMaterialTintAndOpacityUsage() {
        XCTAssertFalse(PanelMaterial.liquidGlass.usesTintAndOpacity)
        XCTAssertFalse(PanelMaterial.glassClear.usesTintAndOpacity)
        XCTAssertTrue(PanelMaterial.glassTinted.usesTintAndOpacity)
        XCTAssertTrue(PanelMaterial.solid.usesTintAndOpacity)
        XCTAssertTrue(PanelMaterial.gradient.usesTintAndOpacity)
    }

    func testThemeTextOnlyOnOwnedBackgrounds() {
        // Glass defers to the system text color; solid/gradient own the
        // background and must own the foreground too.
        XCTAssertFalse(PanelMaterial.liquidGlass.usesThemeTextColor)
        XCTAssertFalse(PanelMaterial.glassClear.usesThemeTextColor)
        XCTAssertFalse(PanelMaterial.glassTinted.usesThemeTextColor)
        XCTAssertTrue(PanelMaterial.solid.usesThemeTextColor)
        XCTAssertTrue(PanelMaterial.gradient.usesThemeTextColor)
    }

    func testRawValuesRoundTripThroughCodable() throws {
        for material in PanelMaterial.allCases {
            let data = try JSONEncoder().encode(material)
            let decoded = try JSONDecoder().decode(PanelMaterial.self, from: data)
            XCTAssertEqual(decoded, material)
        }
    }
}
