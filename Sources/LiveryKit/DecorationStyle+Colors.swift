import SwiftUI

extension DecorationStyle {
    /// Stripe colors as SwiftUI colors, in the same order as `hexStrings`.
    public var colors: [Color] {
        hexStrings.map { Color(hexString: $0) }
    }
}
