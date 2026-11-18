import XCTest
@testable import LiveryCore

final class DecorationPositionTests: XCTestCase {

    func testRawValuesAreStableAndOrdered() {
        XCTAssertEqual(DecorationPosition.allCases.map(\.rawValue),
                       ["topLeading", "topTrailing"])
    }

    func testIDIsRawValue() {
        for position in DecorationPosition.allCases {
            XCTAssertEqual(position.id, position.rawValue)
        }
    }

    func testLabels() {
        XCTAssertEqual(DecorationPosition.topLeading.label, "Top left")
        XCTAssertEqual(DecorationPosition.topTrailing.label, "Top right")
    }
}
