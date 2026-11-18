# Livery

Panel theming shared by Zap, Jetty and Invoque: hex colours, contrast maths, glass and gradient backgrounds, retro corner decorations, the CRT overlay and the gradient angle dial.

Livery is the single source for the pieces whose behaviour must be identical
across those apps. Each app keeps its own appearance model, presets, preference
keys and theme file format; Livery owns the colour grammar, the contrast maths,
the decoration and material types, the reader for each other's theme files, and
the views that draw the panel surfaces.

## Consumers

| App | Product | Uses |
|---|---|---|
| Zap | `LiveryKit` | colour helpers, `PanelDecoration`, `CRTScreenOverlay`, `BoingBallDecoration`, `AngleDial`, `VisualEffectBlur`, `AccessibilityDisplaySettings` |
| Jetty | `LiveryKit` | colour helpers, `PanelDecoration`, `CRTScreenOverlay`, `BoingBallDecoration`, `PanelBackground`, `AngleDial`, `VisualEffectBlur`, `AccessibilityDisplaySettings` |
| Invoque | `LiveryKit` | colour helpers, `PanelBackground`, `PanelDecoration`, `CRTScreenOverlay`, `BoingBallDecoration`, `VisualEffectBlur`, `AngleDial`, `AccessibilityDisplaySettings` |
| Top Drawer | `LiveryKit` | the `NSColor`/`Color` hex helpers and `VisualEffectBlur` |

## API overview

`LiveryCore` is Foundation only and builds and tests on Linux:

- `RGBA8`, the 8-bit sRGB colour and its `#RRGGBB[AA]` hex grammar.
- `Contrast`, WCAG 2.2 relative luminance, contrast ratio and the
  black-versus-white foreground choice.
- `DecorationStyle` and `DecorationKind`, the corner decoration styles.
- `DecorationPosition`, which top corner a decoration sits in.
- `PanelMaterial`, the panel background material.
- `GradientAngle`, angle normalisation, adjustment, VoiceOver announcement and
  gradient endpoints.
- `ThemeSnapshot`, the settings the three apps share, read from a theme file
  any of them exported. See "Theme files" below.

`LiveryKit` is AppKit and SwiftUI, macOS only, and re-exports `LiveryCore`:

- `NSColor(hex:)`, `NSColor.hexString`, `NSColor.composited(alpha:over:)`,
  `Color(hexString:)`, `Color.hexString` and `Color.readableForeground(on:)`.
- `DecorationStyle.colors`, the stripe palette as SwiftUI colors.
- The views `PanelDecoration`, `CRTScreenOverlay`, `BoingBallDecoration`,
  `AngleDial`, `VisualEffectBlur` and `PanelBackground`.
- `AccessibilityDisplaySettings`, the live Reduce Transparency and Reduce Motion
  mirror.

```swift
// Corner stripes.
PanelDecoration(style: .zxSpectrum, position: .topLeading,
                cornerRadius: 16, thickness: 3)

// CRT overlay.
CRTScreenOverlay(intensity: 0.4, cornerRadius: 16)

// Amiga boing ball.
BoingBallDecoration(position: .topTrailing, cornerRadius: 16,
                     diameter: 56, pixelated: false)

// Gradient angle dial, bound to a source of truth.
@State private var angle = 0.0
AngleDial(angleDegrees: $angle)

// Blurred background.
VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)

// Material background.
PanelBackground(material: .glassTinted, tint: tint, gradientColor: gradient,
                gradientAngle: angle, opacity: 0.8, cornerRadius: 16,
                reduceTransparency: settings.reduceTransparency)
```

## Theme files

Zap, Jetty and Invoque each export themes as JSON in their own format, and
older app versions must keep reading what newer ones write, so the formats
stay as they are. `ThemeSnapshot(themeData:)` reads any of the three and maps
it onto one set of fields; an app imports a sibling's theme by filling its own
preset from the snapshot and its own defaults:

```swift
if let theme = ThemeSnapshot(themeData: data) {
    preset.tintHex = theme.tintHex ?? Preferences.Default.tintHex
    preset.material = theme.material ?? Preferences.Default.material
    // ...
}
```

The format is chosen from keys only one app writes: Invoque's first, then
Zap's, then Jetty's. A file with none of those but with `material`, `tintHex`
or `gradientHex` reads as Jetty. Anything else, including JSON that is not an
object, is not a theme and returns nil.

| `ThemeSnapshot` | Zap | Jetty | Invoque |
|---|---|---|---|
| `name` (trimmed) | `name` | `name` | `name` |
| `material` | `useGradientBackground` (`.gradient`, else `.solid`) | `material` | `material` |
| `tintHex` | `backgroundColorHex` | `tintHex` | `tintHex` |
| `gradientHex` | `gradientColorHex` | `gradientHex` | `gradientHex` |
| `gradientAngle`, `backgroundOpacity`, `cornerRadius` | same names | same names | same names |
| `highlightHex` | `highlightColorHex` | none | `highlightHex` |
| `highlightOpacity`, `highlightCornerRadius` | same names | none | same names |
| `labelHex` | `labelColorHex` | none | `labelHex` |
| `iconSize` | `iconSize` | `iconSize` | none |
| `showsLabels` | `showAppName` | `showLabels` | none |
| `adaptiveAccent` | none | `accentGlow` | `adaptiveAccent` |
| `decorationStyle`, `decorationPosition`, `decorationOpacity`, `decorationSize`, `crtEnabled`, `crtIntensity` | same names | same names | same names |

Every field is optional and is nil when the file lacks it, holds the wrong JSON
type, names an unknown material or decoration, or holds a colour the hex grammar
rejects. Numbers pass through unclamped; each app clamps to its own ranges when
it applies a theme. Settings only one app has (Zap's `contentPadding`, Jetty's
dock layout, indicator and widget fields, Invoque's `typeface`) have no shared
field and keep the importing app's default.

`Tests/LiveryCoreTests/Fixtures` holds a built-in theme exported by each app.
When an app renames, adds or drops an exported field, update its fixture and
this table in the same release.

## Compatibility contracts

The hex grammar is a storage format shared with every consumer: `#RGB`,
`#RGBA`, `#RRGGBB` and `#RRGGBBAA` are accepted (optional `#`, surrounding
whitespace ignored, hex digits only), opaque colours are written as `#RRGGBB`
and translucent ones as `#RRGGBBAA`. Enum raw values are persisted, Reduce
Transparency makes translucent surfaces opaque and Reduce Motion removes
animation, and Liquid Glass stays behind `#if compiler(>=6.2)` and
`#available(macOS 26.0, *)` with the `NSVisualEffectView` fallback below. See
`AGENTS.md` for the full contracts and the versioning policy.

## Behaviour changes when an app adopts Livery

**Zap**

- Stored and imported colours accept `#RGB` and `#RGBA` shorthand, and exported
  hex keeps an explicit alpha instead of silently dropping it.
- Stripe decorations no longer show a faint background hairline between bands.
- The CRT overlay is completely invisible at intensity 0 instead of drawing
  faint scanlines and a vignette.
- The Memphis and Synthwave decoration styles become available.
- Strings such as `+ABCDE` are rejected as colours rather than decoding as a
  wrong colour.

**Jetty**

- Stripe decorations no longer show the band-boundary hairline.
- The Memphis and Synthwave decoration styles become available.
- With Reduce Transparency on, the background turns into an opaque fill
  (solid and gradient fills included) instead of keeping a blur, and follows
  the setting live once Jetty observes `AccessibilityDisplaySettings`.
- The angle dial gains keyboard control (focus ring and arrow keys) and
  VoiceOver increment/decrement at 5° steps.

**Invoque**

- The CRT overlay disappears completely at intensity 0.
- The angle dial gains keyboard control, and its VoiceOver steps change from
  15° to 5°.

**Top Drawer**

- Stored colours accept `#RGB` and `#RGBA` shorthand and keep alpha when
  written back.

Released into the public domain; see `LICENSE`.
