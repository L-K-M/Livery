import SwiftUI

/// An optional retro CRT effect drawn over the whole panel: faint horizontal
/// scanlines plus a soft vignette that darkens toward the edges, as if the panel
/// were a slightly bulged phosphor screen. Purely decorative, never hit-tests,
/// and scaled by `intensity` (0...1) so it can be as subtle or as loud as the
/// user likes; at 0 it draws nothing at all, so the slider's minimum is truly
/// invisible. Clipped to the panel's rounded rect so it doesn't bleed past the
/// corners.
public struct CRTScreenOverlay: View {
    /// Strength of the effect, 0 (invisible) ... 1 (strong). Values outside the
    /// range are clamped, and non-finite values count as 0.
    private let intensity: Double
    /// The panel's corner radius, to match the clip.
    private let cornerRadius: CGFloat

    public init(intensity: Double, cornerRadius: CGFloat) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        let effective = Self.effectiveIntensity(intensity)
        return Canvas { context, size in
            // At zero intensity both opacities are 0, so skip the work entirely.
            guard effective > 0 else { return }
            // Scanlines: a thin dark line every few points. Scales linearly from
            // invisible at 0 to full strength at 1.
            let lineGap: CGFloat = 3
            let lineOpacity = 0.38 * effective
            var y: CGFloat = 0
            while y < size.height {
                let line = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(line), with: .color(.black.opacity(lineOpacity)))
                y += lineGap
            }

            // Vignette: transparent in the middle, darkening toward the edges.
            let edge = 0.30 * effective
            let vignette = Gradient(colors: [.clear, .black.opacity(edge)])
            let maxDimension = max(size.width, size.height)
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .radialGradient(vignette,
                                      center: CGPoint(x: size.width / 2, y: size.height / 2),
                                      startRadius: maxDimension * 0.2,
                                      endRadius: maxDimension * 0.7)
            )
        }
        .allowsHitTesting(false)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private static func effectiveIntensity(_ intensity: Double) -> Double {
        intensity.isFinite ? min(max(intensity, 0), 1) : 0
    }
}
