import Foundation

/// The appearance settings Zap, Jetty and Invoque have in common, read from a
/// theme file any of them exported.
///
/// Each app keeps its own preset type and file format, because older versions
/// of an app must keep reading what newer ones export. What the apps share is
/// this reader: it recognises which app wrote a file and maps that app's field
/// names onto one set of fields, so every app imports the other two's themes
/// the same way. The README's "Theme files" section lists the mapping.
///
/// Every field is optional. A field is nil when the source app has no such
/// setting, when the file leaves it out, or when it holds the wrong JSON type
/// or an unknown or unparseable value; the importing app then uses its own
/// default. Numbers are passed through as written: each app clamps them to
/// its own ranges when it applies the theme.
public struct ThemeSnapshot: Equatable, Sendable {

    /// The app whose theme file format was read.
    public enum Format: String, CaseIterable, Sendable {
        case zap
        case jetty
        case invoque
    }

    // MARK: Fields

    public var format: Format
    /// Trimmed; nil when missing or blank.
    public var name: String?
    /// Zap themes are always `.solid` or `.gradient`, from
    /// `useGradientBackground`: Zap has no glass materials.
    public var material: PanelMaterial?
    /// The background color. Zap calls it `backgroundColorHex`.
    public var tintHex: String?
    /// Zap calls it `gradientColorHex`.
    public var gradientHex: String?
    public var gradientAngle: Double?
    public var backgroundOpacity: Double?
    public var cornerRadius: Double?
    /// The selected item's color: Zap's `highlightColorHex`, Invoque's
    /// `highlightHex`. Jetty has no selection highlight.
    public var highlightHex: String?
    /// Zap and Invoque.
    public var highlightOpacity: Double?
    /// Zap and Invoque.
    public var highlightCornerRadius: Double?
    /// Item label color: Zap's `labelColorHex`, Invoque's `labelHex`.
    public var labelHex: String?
    /// Zap and Jetty.
    public var iconSize: Double?
    /// Whether names show under icons: Zap's `showAppName`, Jetty's
    /// `showLabels`.
    public var showsLabels: Bool?
    /// The accent taken from the item's own colors: Jetty's `accentGlow`,
    /// Invoque's `adaptiveAccent`.
    public var adaptiveAccent: Bool?
    public var decorationStyle: DecorationStyle?
    public var decorationPosition: DecorationPosition?
    public var decorationOpacity: Double?
    public var decorationSize: Double?
    public var crtEnabled: Bool?
    public var crtIntensity: Double?

    public init(format: Format,
                name: String? = nil,
                material: PanelMaterial? = nil,
                tintHex: String? = nil,
                gradientHex: String? = nil,
                gradientAngle: Double? = nil,
                backgroundOpacity: Double? = nil,
                cornerRadius: Double? = nil,
                highlightHex: String? = nil,
                highlightOpacity: Double? = nil,
                highlightCornerRadius: Double? = nil,
                labelHex: String? = nil,
                iconSize: Double? = nil,
                showsLabels: Bool? = nil,
                adaptiveAccent: Bool? = nil,
                decorationStyle: DecorationStyle? = nil,
                decorationPosition: DecorationPosition? = nil,
                decorationOpacity: Double? = nil,
                decorationSize: Double? = nil,
                crtEnabled: Bool? = nil,
                crtIntensity: Double? = nil) {
        self.format = format
        self.name = name
        self.material = material
        self.tintHex = tintHex
        self.gradientHex = gradientHex
        self.gradientAngle = gradientAngle
        self.backgroundOpacity = backgroundOpacity
        self.cornerRadius = cornerRadius
        self.highlightHex = highlightHex
        self.highlightOpacity = highlightOpacity
        self.highlightCornerRadius = highlightCornerRadius
        self.labelHex = labelHex
        self.iconSize = iconSize
        self.showsLabels = showsLabels
        self.adaptiveAccent = adaptiveAccent
        self.decorationStyle = decorationStyle
        self.decorationPosition = decorationPosition
        self.decorationOpacity = decorationOpacity
        self.decorationSize = decorationSize
        self.crtEnabled = crtEnabled
        self.crtIntensity = crtIntensity
    }

    // MARK: Reading a theme file

    /// Reads a theme file exported by Zap, Jetty or Invoque. Returns nil for
    /// data that is not a JSON object, or an object with none of the keys
    /// that identify one of the three formats: importing the wrong file must
    /// fail visibly rather than apply an all-defaults theme.
    public init?(themeData data: Data) {
        guard let decoded = try? JSONDecoder().decode(Reader.self, from: data).snapshot else {
            return nil
        }
        self = decoded
    }

    /// Picks the format from the keys a file contains. Only keys unique to
    /// one app decide; keys every format shares (`cornerRadius`,
    /// `gradientAngle`, `decoration*`, `crt*`) cannot.
    ///
    /// Invoque's own keys win first: its exports always carry them, and a
    /// partial Invoque file can also hold names it shares with Jetty. Zap's
    /// keys come next. A file with neither but with `material`, `tintHex` or
    /// `gradientHex` (the names Jetty and Invoque share) reads as Jetty: a
    /// minimal theme maps the same through either.
    static func format(forKeys keys: Set<String>) -> Format? {
        if !keys.isDisjoint(with: FormatKeys.invoque) { return .invoque }
        if !keys.isDisjoint(with: FormatKeys.zap) { return .zap }
        if !keys.isDisjoint(with: FormatKeys.jetty) { return .jetty }
        if !keys.isDisjoint(with: FormatKeys.sharedByJettyAndInvoque) { return .jetty }
        return nil
    }

    /// Keys only one app writes, plus Jetty settings from older versions
    /// (`dockEdge`, `edge`, `autoHide`, `windowPreviewMode`, `trashIconStyle`)
    /// that still identify a Jetty file.
    enum FormatKeys {
        static let invoque: Set<String> = ["labelHex", "highlightHex", "adaptiveAccent", "typeface"]
        static let zap: Set<String> = [
            "backgroundColorHex", "useGradientBackground", "gradientColorHex",
            "highlightColorHex", "labelColorHex", "showAppName", "contentPadding",
        ]
        static let jetty: Set<String> = [
            "tileSpacing", "indicatorStyle", "indicatorHex", "accentGlow", "glyphHex",
            "magnificationEnabled", "magnification", "showLabels", "clockFace",
            "clockFaceZoom", "systemMonitorStyle", "systemMonitorShowNetwork",
            "dockEdge", "edge", "autoHide", "windowPreviewMode", "trashIconStyle",
        ]
        static let sharedByJettyAndInvoque: Set<String> = ["material", "tintHex", "gradientHex"]
    }

    // MARK: Private

    private struct Key: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init(_ string: String) { stringValue = string }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    /// Decodes through `KeyedDecodingContainer` so each field is tolerant on
    /// its own: a wrong JSON type (`"gradientAngle": "30"` in a hand-edited
    /// file) makes that field nil instead of failing the whole import.
    private struct Reader: Decodable {
        let snapshot: ThemeSnapshot?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Key.self)
            let keys = Set(container.allKeys.map(\.stringValue))
            guard let format = ThemeSnapshot.format(forKeys: keys) else {
                snapshot = nil
                return
            }

            func value<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
                (try? container.decodeIfPresent(type, forKey: Key(key))) ?? nil
            }
            func color(_ key: String) -> String? {
                value(String.self, key).flatMap { RGBA8(hex: $0) == nil ? nil : $0 }
            }

            var theme = ThemeSnapshot(format: format)
            theme.name = value(String.self, "name")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .flatMap { $0.isEmpty ? nil : $0 }
            theme.gradientAngle = value(Double.self, "gradientAngle")
            theme.backgroundOpacity = value(Double.self, "backgroundOpacity")
            theme.cornerRadius = value(Double.self, "cornerRadius")
            theme.highlightOpacity = value(Double.self, "highlightOpacity")
            theme.highlightCornerRadius = value(Double.self, "highlightCornerRadius")
            theme.iconSize = value(Double.self, "iconSize")
            theme.decorationStyle = value(String.self, "decorationStyle").flatMap(DecorationStyle.init(rawValue:))
            theme.decorationPosition = value(String.self, "decorationPosition").flatMap(DecorationPosition.init(rawValue:))
            theme.decorationOpacity = value(Double.self, "decorationOpacity")
            theme.decorationSize = value(Double.self, "decorationSize")
            theme.crtEnabled = value(Bool.self, "crtEnabled")
            theme.crtIntensity = value(Double.self, "crtIntensity")

            switch format {
            case .zap:
                // Zap paints a solid or a gradient background, nothing else,
                // so a Zap theme always names one of the two.
                theme.material = value(Bool.self, "useGradientBackground") == true ? .gradient : .solid
                theme.tintHex = color("backgroundColorHex")
                theme.gradientHex = color("gradientColorHex")
                theme.highlightHex = color("highlightColorHex")
                theme.labelHex = color("labelColorHex")
                theme.showsLabels = value(Bool.self, "showAppName")
            case .jetty, .invoque:
                theme.material = value(String.self, "material").flatMap(PanelMaterial.init(rawValue:))
                theme.tintHex = color("tintHex")
                theme.gradientHex = color("gradientHex")
                theme.highlightHex = color("highlightHex")
                theme.labelHex = color("labelHex")
                theme.showsLabels = value(Bool.self, "showLabels")
                theme.adaptiveAccent = value(Bool.self, "adaptiveAccent") ?? value(Bool.self, "accentGlow")
            }
            snapshot = theme
        }
    }
}
