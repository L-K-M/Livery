import Foundation

/// WCAG 2.2 contrast maths over 8-bit sRGB colours: relative luminance, the
/// contrast ratio, and the black-versus-white foreground choice.
public enum Contrast {

    /// WCAG 2.2 SC 1.4.3, the minimum contrast ratio for normal text.
    public static let minimumTextRatio = 4.5

    /// The minimum contrast ratio for large text (WCAG 2.2 SC 1.4.3) and for
    /// user interface components and graphics (SC 1.4.11).
    public static let minimumNonTextRatio = 3.0

    /// Relative luminance of an sRGB colour whose components are unit-interval.
    /// Inputs are clamped into 0...1 first, because a wide-gamut or
    /// extended-range colour can report components outside that range.
    public static func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
        func linearized(_ channel: Double) -> Double {
            let value = min(max(channel, 0), 1)
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
    }

    /// Relative luminance of an 8-bit sRGB colour.
    public static func relativeLuminance(_ color: RGBA8) -> Double {
        relativeLuminance(red: Double(color.red) / 255,
                          green: Double(color.green) / 255,
                          blue: Double(color.blue) / 255)
    }

    /// Contrast ratio between two relative luminances, independent of order:
    /// `(lighter + 0.05) / (darker + 0.05)`.
    public static func ratio(_ l1: Double, _ l2: Double) -> Double {
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Contrast ratio between two 8-bit sRGB colours.
    public static func ratio(_ a: RGBA8, _ b: RGBA8) -> Double {
        ratio(relativeLuminance(a), relativeLuminance(b))
    }

    /// Whether black text reads better than white on a background of the given
    /// relative luminance. Black wins ties, so a mid-grey background keeps the
    /// darker foreground.
    public static func prefersBlackForeground(luminance: Double) -> Bool {
        let contrastWithBlack = (luminance + 0.05) / 0.05
        let contrastWithWhite = 1.05 / (luminance + 0.05)
        return contrastWithBlack >= contrastWithWhite
    }
}
