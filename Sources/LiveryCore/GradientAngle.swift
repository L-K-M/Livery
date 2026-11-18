import Foundation

/// Gradient angle maths shared by the angle dial and the gradient background.
///
/// Angles are degrees in `0..<360`. 0° runs top to bottom and angles increase
/// counterclockwise on screen, so 90° runs left to right, 180° bottom to top
/// and 270° right to left. Screen y grows downward, hence the `(sin, cos)`
/// pairing.
public enum GradientAngle {

    /// Wraps `degrees` into `0..<360`. Non-finite input, or a value whose
    /// wrapping is not finite, falls back to 0.
    public static func normalized(_ degrees: Double) -> Double {
        guard degrees.isFinite else { return 0 }
        let wrapped = degrees.truncatingRemainder(dividingBy: 360)
        guard wrapped.isFinite else { return 0 }
        return wrapped < 0 ? wrapped + 360 : wrapped
    }

    /// Returns `degrees + delta` wrapped into `0..<360`; the shared adjustment
    /// path for keyboard and accessibility input. Non-finite input, or a finite
    /// sum overflowing to infinity, falls back to 0.
    public static func adjusted(_ degrees: Double, by delta: Double) -> Double {
        guard degrees.isFinite, delta.isFinite else { return 0 }
        let sum = degrees + delta
        guard sum.isFinite else { return 0 }
        return normalized(sum)
    }

    /// Whole degrees announced to VoiceOver, normalized into `0..<360` so an
    /// arbitrary binding value cannot read out nonsense.
    public static func announcedDegrees(_ degrees: Double) -> Int {
        Int(adjusted(degrees, by: 0).rounded()) % 360
    }

    /// The gradient's start and end points in unit coordinates. 0° runs top to
    /// bottom and 90° left to right; y grows downward, so the start is the
    /// corner the gradient leaves from.
    public static func endpoints(degrees: Double) -> (start: (x: Double, y: Double),
                                                       end: (x: Double, y: Double)) {
        let radians = degrees * .pi / 180
        let sin = sin(radians)
        let cos = cos(radians)
        return (start: (x: 0.5 - sin / 2, y: 0.5 - cos / 2),
                end: (x: 0.5 + sin / 2, y: 0.5 + cos / 2))
    }
}
