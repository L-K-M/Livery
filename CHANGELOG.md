# Changelog

## Unreleased

- Create the repository.
- Add the Livery package manifest with the Foundation-only `LiveryCore` product
  and the macOS-only `LiveryKit` product, targets and test targets.
- Add `RGBA8` from Jetty's copy (byte-identical in Invoque), carrying the
  wide-gamut component clamp, CSS shorthand expansion, translucent alpha
  round-trip and rejection of signed hex; make it public and add black and
  white constants.
- Add `Contrast` from Invoque's `Color.readableForeground(on:)` maths: WCAG 2.2
  relative luminance, the order-independent ratio, and the black-versus-white
  foreground rule.
- Add `DecorationStyle` and `DecorationKind` from Invoque's copy, extended to
  the union of all three apps' cases (adding Memphis and Synthwave), with
  public `hexStrings`; the SwiftUI `colors` accessor moves to LiveryKit.
- Add `DecorationPosition` from the copies that are identical in all three
  apps.
- Add `PanelMaterial` from Invoque's copy, carrying the tint/opacity and
  theme-text rules.
- Add `GradientAngle` from Zap's `AngleDial` adjustment and announcement maths
  and the gradient endpoint maths, with normalisation and non-finite fallback.
- Add the `NSColor`/`Color` hex bridge from Invoque's `ColorHex.swift`, routed
  through `RGBA8` and `Contrast`, carrying the wide-gamut clamp and the
  composited alpha multiplication.
- Add `PanelDecoration` from Invoque's copy, carrying the overlapping-band fix
  that removes the stripe hairline Zap and Jetty still draw.
- Add `CRTScreenOverlay` from Jetty's copy, which draws nothing at intensity 0,
  plus clamping to 0...1 and non-finite handling.
- Add `BoingBallDecoration` from Jetty's copy with its four-entry
  per-pixel-diameter cache, plus Invoque's main-thread assert.
- Add `AngleDial` from Zap's copy, carrying keyboard focus and arrow keys, the
  5° step, and the normalised VoiceOver announcement.
- Add `VisualEffectBlur` from the copies identical in Zap, Jetty, Invoque and
  Top Drawer.
- Add `PanelBackground` from Invoque's copy, carrying the Liquid Glass guard,
  the opaque Reduce Transparency fill and alpha stripping, and a configurable
  fallback material for Jetty's `.hudWindow`.
- Add `AccessibilityDisplaySettings` from Invoque's copy, carrying the
  main-thread asserts and the pure opacity and animation rules.
- Add build and release scripts and CI workflows adapted from Rigi, without the
  gallery, and this README and changelog.
