import XCTest
@testable import LiveryCore

/// The angle maths shared by the angle dial and the gradient background.
final class GradientAngleTests: XCTestCase {

    // MARK: Normalisation and adjustment

    func testIncrementStepsForward() {
        XCTAssertEqual(GradientAngle.adjusted(0, by: 5), 5)
    }

    func testDecrementFromZeroWrapsTo355() {
        XCTAssertEqual(GradientAngle.adjusted(0, by: -5), 355)
    }

    func testIncrementPast360WrapsAround() {
        XCTAssertEqual(GradientAngle.adjusted(358, by: 5), 3)
        XCTAssertEqual(GradientAngle.adjusted(355, by: 5), 0)
        XCTAssertEqual(GradientAngle.adjusted(0, by: 725), 5)
    }

    func testDecrementBelowZeroWrapsAround() {
        XCTAssertEqual(GradientAngle.adjusted(2, by: -5), 357)
        XCTAssertEqual(GradientAngle.adjusted(0, by: -725), 355)
    }

    func testAngleAt360NormalizesToZero() {
        XCTAssertEqual(GradientAngle.adjusted(360, by: 0), 0)
        XCTAssertEqual(GradientAngle.adjusted(0, by: 360), 0)
        XCTAssertEqual(GradientAngle.adjusted(0, by: -360), 0)
    }

    func testNegativeAngleNormalizesIntoRange() {
        XCTAssertEqual(GradientAngle.normalized(-5), 355)
        XCTAssertEqual(GradientAngle.adjusted(-5, by: 0), 355)
    }

    func testNormalisationWrapsNegativeAbove360() {
        XCTAssertEqual(GradientAngle.normalized(-365), 355)
        XCTAssertEqual(GradientAngle.normalized(725), 5)
        XCTAssertEqual(GradientAngle.normalized(360), 0)
    }

    func testNonFiniteInputsFallBackToZero() {
        XCTAssertEqual(GradientAngle.adjusted(.nan, by: 5), 0)
        XCTAssertEqual(GradientAngle.adjusted(10, by: .nan), 0)
        XCTAssertEqual(GradientAngle.adjusted(.infinity, by: -5), 0)
        XCTAssertEqual(GradientAngle.adjusted(10, by: .infinity), 0)
        XCTAssertEqual(GradientAngle.normalized(.nan), 0)
        XCTAssertEqual(GradientAngle.normalized(.infinity), 0)
        XCTAssertEqual(GradientAngle.normalized(-.infinity), 0)
    }

    /// Finite inputs can still overflow to infinity when summed; that must fall
    /// back to 0 just like a non-finite input would.
    func testFiniteSumOverflowFallsBackToZero() {
        XCTAssertEqual(GradientAngle.adjusted(.greatestFiniteMagnitude,
                                              by: .greatestFiniteMagnitude), 0)
    }

    // MARK: VoiceOver announcement

    /// The announced value is normalized after rounding, so 359.7 (which rounds
    /// to 360) announces 0 rather than an out-of-range reading.
    func testAnnouncedDegreesNormalizeRoundedBoundary() {
        XCTAssertEqual(GradientAngle.announcedDegrees(359.7), 0)
        XCTAssertEqual(GradientAngle.announcedDegrees(358.6), 359)
        XCTAssertEqual(GradientAngle.announcedDegrees(-1), 359)
        XCTAssertEqual(GradientAngle.announcedDegrees(360), 0)
    }

    /// Invalid bindings announce 0; huge-but-finite bindings announce some
    /// in-range remainder rather than overflowing the Int conversion.
    func testAnnouncedDegreesHandleInvalidAndHugeBindings() {
        XCTAssertEqual(GradientAngle.announcedDegrees(.nan), 0)
        XCTAssertEqual(GradientAngle.announcedDegrees(.infinity), 0)
        XCTAssertEqual(GradientAngle.announcedDegrees(-.infinity), 0)
        for angle in [Double.greatestFiniteMagnitude, -Double.greatestFiniteMagnitude] {
            XCTAssertTrue((0..<360).contains(GradientAngle.announcedDegrees(angle)))
        }
    }

    // MARK: Gradient endpoints

    func testEndpointsAtCardinalAngles() {
        let tolerance = 0.0001

        let zero = GradientAngle.endpoints(degrees: 0)
        XCTAssertEqual(zero.start.x, 0.5, accuracy: tolerance)
        XCTAssertEqual(zero.start.y, 0.0, accuracy: tolerance)
        XCTAssertEqual(zero.end.x, 0.5, accuracy: tolerance)
        XCTAssertEqual(zero.end.y, 1.0, accuracy: tolerance)

        let ninety = GradientAngle.endpoints(degrees: 90)
        XCTAssertEqual(ninety.start.x, 0.0, accuracy: tolerance)
        XCTAssertEqual(ninety.start.y, 0.5, accuracy: tolerance)
        XCTAssertEqual(ninety.end.x, 1.0, accuracy: tolerance)
        XCTAssertEqual(ninety.end.y, 0.5, accuracy: tolerance)

        let oneEighty = GradientAngle.endpoints(degrees: 180)
        XCTAssertEqual(oneEighty.start.x, 0.5, accuracy: tolerance)
        XCTAssertEqual(oneEighty.start.y, 1.0, accuracy: tolerance)
        XCTAssertEqual(oneEighty.end.x, 0.5, accuracy: tolerance)
        XCTAssertEqual(oneEighty.end.y, 0.0, accuracy: tolerance)

        let twoSeventy = GradientAngle.endpoints(degrees: 270)
        XCTAssertEqual(twoSeventy.start.x, 1.0, accuracy: tolerance)
        XCTAssertEqual(twoSeventy.start.y, 0.5, accuracy: tolerance)
        XCTAssertEqual(twoSeventy.end.x, 0.0, accuracy: tolerance)
        XCTAssertEqual(twoSeventy.end.y, 0.5, accuracy: tolerance)
    }

    func testEndpointsAreAntipodal() {
        for degrees in [0.0, 37.5, 90.0, 180.0, 270.0, 312.25] {
            let points = GradientAngle.endpoints(degrees: degrees)
            XCTAssertEqual((points.start.x + points.end.x) / 2, 0.5, accuracy: 0.0001)
            XCTAssertEqual((points.start.y + points.end.y) / 2, 0.5, accuracy: 0.0001)
        }
    }
}
