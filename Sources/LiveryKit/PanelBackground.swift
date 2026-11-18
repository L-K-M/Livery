import AppKit
import SwiftUI

/// The panel's background material.
///
/// On **macOS 26 (Tahoe)** the glass variants render genuine **Liquid Glass** via
/// SwiftUI's public `.glassEffect`, honoring the user's Clear/Tinted and
/// Reduce-Transparency settings automatically, but only when built with the
/// macOS 26 SDK (`#if compiler(>=6.2)`): older toolchains can't see the `Glass`
/// type at all, so they compile the blur fallback unconditionally. On
/// macOS 13–15 use an `NSVisualEffectView` blur. Reduce Transparency replaces
/// either glass path with an opaque semantic surface; tinted glass keeps a
/// restrained theme wash. Solid and gradient materials use their fills.
public struct PanelBackground: View {
    private static let maximumFallbackTintOpacity = 0.5

    private var material: PanelMaterial
    private var tint: Color
    private var gradientColor: Color
    private var gradientAngle: Double
    /// The user's configured opacity. Reduce Transparency overrides both this
    /// multiplier and any alpha embedded in an imported fill color.
    private var opacity: Double
    private var cornerRadius: CGFloat
    /// The user's Reduce Transparency setting, supplied by the caller; replaces
    /// both native glass and the visual-effect fallback with an opaque fill.
    private var reduceTransparency: Bool
    /// The blur material used by the pre-26-SDK fallback.
    private var fallbackMaterial: NSVisualEffectView.Material

    public init(material: PanelMaterial,
                tint: Color,
                gradientColor: Color,
                gradientAngle: Double,
                opacity: Double,
                cornerRadius: CGFloat,
                reduceTransparency: Bool,
                fallbackMaterial: NSVisualEffectView.Material = .popover) {
        self.material = material
        self.tint = tint
        self.gradientColor = gradientColor
        self.gradientAngle = gradientAngle
        self.opacity = opacity
        self.cornerRadius = cornerRadius
        self.reduceTransparency = reduceTransparency
        self.fallbackMaterial = fallbackMaterial
    }

    /// The restrained wash non-native glass keeps when blur is unavailable
    /// (Reduce Transparency) or unbuildable (pre-26 SDK). `nil` means no wash;
    /// only `.glassTinted` carries theme color.
    public static func fallbackTintOpacity(
        for material: PanelMaterial,
        configuredOpacity: Double
    ) -> Double? {
        guard material == .glassTinted else { return nil }
        return min(max(0.0, configuredOpacity), maximumFallbackTintOpacity)
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        Group {
            switch material {
            case .liquidGlass, .glassClear, .glassTinted:
                glass(in: shape)
            case .solid:
                shape.fill(fillColor(tint))
            case .gradient:
                let points = GradientAngle.endpoints(degrees: gradientAngle)
                shape.fill(
                    LinearGradient(
                        colors: [fillColor(tint), fillColor(gradientColor)],
                        startPoint: UnitPoint(x: points.start.x, y: points.start.y),
                        endPoint: UnitPoint(x: points.end.x, y: points.end.y)
                    )
                )
            }
        }
    }

    /// Imported hex colors may carry alpha even though the color picker does not
    /// offer it. Increasing the opacity multiplier alone cannot remove it.
    private func fillColor(_ color: Color) -> Color {
        guard reduceTransparency else { return color.opacity(opacity) }
        return Color(nsColor: NSColor(color).withAlphaComponent(1))
    }

    @ViewBuilder
    private func glass(in shape: RoundedRectangle) -> some View {
        if reduceTransparency {
            // The semantic base is opaque. Tinted glass keeps a restrained wash
            // so system label colors remain legible in either appearance.
            ZStack {
                shape.fill(.background)
                if let wash = Self.fallbackTintOpacity(
                    for: material, configuredOpacity: opacity) {
                    shape.fill(tint.opacity(wash))
                }
            }
        } else {
            #if compiler(>=6.2)
            // Xcode 26+ carries the macOS 26 SDK, where `Glass`/`glassEffect`
            // exist; `#available` then decides at runtime.
            if #available(macOS 26.0, *) {
                let glass: Glass = {
                    switch material {
                    case .glassClear: return .clear
                    case .glassTinted: return .regular.tint(tint.opacity(max(0.0, min(opacity, 1.0))))
                    default: return .regular
                    }
                }()
                Color.clear.glassEffect(glass, in: shape)
            } else {
                fallbackGlass(in: shape)
            }
            #else
            fallbackGlass(in: shape)
            #endif
        }
    }

    /// Fallback for macOS 13–15 and older SDKs: a blurred panel with a faint
    /// tint wash, clipped to the same rounded shape.
    @ViewBuilder
    private func fallbackGlass(in shape: RoundedRectangle) -> some View {
        ZStack {
            VisualEffectBlur(material: fallbackMaterial, blendingMode: .behindWindow)
            if let wash = Self.fallbackTintOpacity(
                for: material, configuredOpacity: opacity) {
                tint.opacity(wash)
            }
        }
        .clipShape(shape)
    }
}
