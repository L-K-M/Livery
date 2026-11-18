import SwiftUI

/// A circular dial for picking a `0...360`° angle by dragging or clicking around
/// it. 0° points straight down (a top→bottom gradient) and increases
/// counterclockwise on screen (90° right, 180° up, 270° left); screen y grows
/// downward, so (sin, cos) sweeps bottom→right→top→left. Matches the gradient
/// endpoint math in `GradientAngle`. The knob points in the gradient's flow
/// direction, so the dial reads as "the gradient runs this way."
///
/// The dial is focusable: arrow keys step the angle, and VoiceOver's
/// increment/decrement actions use the same 5° step and the same normalised
/// announcement.
public struct AngleDial: View {
    @Binding private var angleDegrees: Double
    private var diameter: CGFloat

    /// Whether the dial holds keyboard focus (drives the focus ring).
    @FocusState private var isFocused: Bool

    /// Angle step for keyboard arrows and VoiceOver increment/decrement.
    private static let adjustmentStep: Double = 5

    public init(angleDegrees: Binding<Double>, diameter: CGFloat = 46) {
        self._angleDegrees = angleDegrees
        self.diameter = diameter
    }

    public var body: some View {
        let radians = GradientAngle.normalized(angleDegrees) * .pi / 180
        let reach = diameter / 2 - 6
        // Screen y grows downward, so (sin, cos) puts 0° at the bottom.
        let knob = CGPoint(x: sin(radians) * reach, y: cos(radians) * reach)

        ZStack {
            Circle().fill(Color.secondary.opacity(0.12))
            Circle().strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)

            Path { path in
                path.move(to: CGPoint(x: diameter / 2, y: diameter / 2))
                path.addLine(to: CGPoint(x: diameter / 2 + knob.x, y: diameter / 2 + knob.y))
            }
            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))

            Circle()
                .fill(Color.accentColor)
                .frame(width: 10, height: 10)
                .offset(x: knob.x, y: knob.y)
        }
        .frame(width: diameter, height: diameter)
        .overlay(
            // Focus ring drawn just outside the dial; hit testing stays on the
            // dial's own contentShape so the ring can't swallow drags.
            Circle()
                .stroke(Color.accentColor, lineWidth: 2)
                .padding(-3)
                .opacity(isFocused ? 1 : 0)
                .allowsHitTesting(false)
        )
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let dx = value.location.x - diameter / 2
                    let dy = value.location.y - diameter / 2
                    guard dx != 0 || dy != 0 else { return }
                    var degrees = atan2(dx, dy) * 180 / .pi
                    if degrees < 0 { degrees += 360 }
                    angleDegrees = degrees
                }
        )
        .focusable()
        .focused($isFocused)
        .onMoveCommand { direction in
            switch direction {
            case .up, .right:
                angleDegrees = GradientAngle.adjusted(angleDegrees, by: Self.adjustmentStep)
            case .down, .left:
                angleDegrees = GradientAngle.adjusted(angleDegrees, by: -Self.adjustmentStep)
            default:
                break
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gradient direction")
        .accessibilityValue("\(GradientAngle.announcedDegrees(angleDegrees)) degrees")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                angleDegrees = GradientAngle.adjusted(angleDegrees, by: Self.adjustmentStep)
            case .decrement:
                angleDegrees = GradientAngle.adjusted(angleDegrees, by: -Self.adjustmentStep)
            default:
                break
            }
        }
    }
}
