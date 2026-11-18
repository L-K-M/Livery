import Foundation

/// An 8-bit-per-channel sRGB colour and the `#RRGGBB[AA]` text form it is
/// persisted in. Pure arithmetic over bytes and characters, with no colour
/// framework behind it, so the parsing and formatting rules, which are a
/// **storage format** read by every build on every platform, are unit-testable
/// anywhere.
public struct RGBA8: Equatable, Hashable, Sendable {

    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    public var alpha: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let black = RGBA8(red: 0, green: 0, blue: 0)
    public static let white = RGBA8(red: 255, green: 255, blue: 255)

    /// Rounds unit-interval components to bytes, clamping first.
    ///
    /// The clamp is load-bearing: an extended-range or wide-gamut colour can
    /// report components outside 0...1 even after conversion to sRGB, and
    /// formatting one of those unclamped produces a string that no longer
    /// parses, which used to turn a colour silently into `.clear` on the next
    /// read.
    public init(clampingRed r: Double, green g: Double, blue b: Double, alpha a: Double) {
        func channel(_ v: Double) -> UInt8 {
            // NaN first, and NaN only. Every comparison against it is false, so it
            // survives both `max` and `min` unchanged and then traps in the `UInt8`
            // conversion, the one input class this clamp did not actually clamp.
            // ±infinity needs no special case and must not get one: `max(-inf, 0)` is
            // 0 and `min(+inf, 1)` is 1, so the clamp already maps them to black and
            // white, which is the right answer. Sending them to 0 alongside NaN would
            // turn a blown-out white into black.
            guard !v.isNaN else { return 0 }
            return UInt8((Swift.min(Swift.max(v, 0), 1) * 255).rounded())
        }
        self.init(red: channel(r), green: channel(g), blue: channel(b), alpha: channel(a))
    }

    /// Parses `#RRGGBB`, `#RRGGBBAA`, or the CSS shorthands `#RGB`/`#RGBA`
    /// (the leading `#` is optional).
    public init?(hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") { string.removeFirst() }

        // `UInt64(_, radix:)` accepts a leading "+", so "+ABCDE" would otherwise
        // slip through as a 5-digit value and decode as the wrong color; require
        // pure hex digits before parsing.
        guard !string.isEmpty, string.allSatisfy(\.isHexDigit) else { return nil }

        // Expand CSS shorthand by doubling each nibble: #abc → #aabbcc.
        if string.count == 3 || string.count == 4 {
            string = string.map { "\($0)\($0)" }.joined()
        }

        guard let value = UInt64(string, radix: 16) else { return nil }

        switch string.count {
        case 6:
            self.init(red: UInt8((value & 0xFF0000) >> 16),
                      green: UInt8((value & 0x00FF00) >> 8),
                      blue: UInt8(value & 0x0000FF),
                      alpha: 255)
        case 8:
            self.init(red: UInt8((value & 0xFF00_0000) >> 24),
                      green: UInt8((value & 0x00FF_0000) >> 16),
                      blue: UInt8((value & 0x0000_FF00) >> 8),
                      alpha: UInt8(value & 0x0000_00FF))
        default:
            return nil
        }
    }

    /// `#RRGGBB` (fully opaque) or `#RRGGBBAA` (translucent). Emitting alpha only
    /// when present keeps existing opaque presets byte-identical while letting
    /// translucent colors round-trip.
    public var hexString: String {
        alpha < 255 ? String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
                    : String(format: "#%02X%02X%02X", red, green, blue)
    }
}
