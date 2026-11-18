import AppKit
import SwiftUI

// The hex format itself lives in `RGBA8`, pure and unit-testable, because it is
// a storage format every build has to agree on. What is left here is the part
// that genuinely needs a colour framework: converting to and from a live
// `NSColor`, and picking a legible foreground for a themed fill.

// MARK: - NSColor hex support

extension NSColor {
    /// Parses `#RRGGBB`, `#RRGGBBAA`, or the CSS shorthands `#RGB`/`#RGBA`
    /// (the leading `#` is optional).
    public convenience init?(hex: String) {
        guard let c = RGBA8(hex: hex) else { return nil }
        self.init(srgbRed: CGFloat(c.red) / 255,
                  green: CGFloat(c.green) / 255,
                  blue: CGFloat(c.blue) / 255,
                  alpha: CGFloat(c.alpha) / 255)
    }

    /// `#RRGGBB` (fully opaque) or `#RRGGBBAA` (translucent) in the sRGB color space.
    public var hexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "#000000" }
        // `RGBA8.init(clampingRed:...)` carries the clamp: wide-gamut sources can
        // report components outside 0...1 even after `.sRGB`.
        return RGBA8(clampingRed: Double(c.redComponent),
                     green: Double(c.greenComponent),
                     blue: Double(c.blueComponent),
                     alpha: Double(c.alphaComponent)).hexString
    }

    /// `self` at the additional `alpha` composited over an opaque `base` estimate.
    ///
    /// Text is chosen against the color it actually sits on: the translucent
    /// fill blended over the background, not the raw fill. At low opacity the
    /// background dominates, and inverting text on the unblended fill would pick
    /// the wrong shade.
    public func composited(alpha: CGFloat, over base: NSColor) -> NSColor {
        guard let top = usingColorSpace(.sRGB),
              let bottom = base.usingColorSpace(.sRGB) else { return self }
        // SwiftUI's opacity multiplies the imported color's own alpha. Ignoring
        // that alpha can choose dark text for a clear highlight on a dark card.
        let a = min(max(alpha, 0), 1) * top.alphaComponent
        return NSColor(srgbRed: top.redComponent * a + bottom.redComponent * (1 - a),
                       green: top.greenComponent * a + bottom.greenComponent * (1 - a),
                       blue: top.blueComponent * a + bottom.blueComponent * (1 - a),
                       alpha: 1)
    }
}

// MARK: - SwiftUI Color bridging

extension Color {
    /// Creates a `Color` from a `#RRGGBB[AA]` (or `#RGB[A]` shorthand) string,
    /// falling back to clear.
    public init(hexString: String) {
        self = Color(nsColor: NSColor(hex: hexString) ?? .clear)
    }

    /// The hex string for this color (best-effort via `NSColor`).
    public var hexString: String {
        NSColor(self).hexString
    }

    /// Whichever opaque foreground has greater contrast against the given
    /// background. Linearized sRGB luminance keeps saturated colors such as
    /// green from incorrectly choosing white text. Formula: WCAG 2.2, SC 1.4.3.
    public static func readableForeground(on color: NSColor) -> Color {
        let c = color.usingColorSpace(.sRGB) ?? .white
        let luminance = Contrast.relativeLuminance(red: Double(c.redComponent),
                                                  green: Double(c.greenComponent),
                                                  blue: Double(c.blueComponent))
        return Contrast.prefersBlackForeground(luminance: luminance) ? .black : .white
    }
}
