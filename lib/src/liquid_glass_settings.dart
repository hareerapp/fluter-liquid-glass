import 'package:flutter/widgets.dart';

import 'liquid_glass_shape.dart';

/// Glass material style.
enum LiquidGlassStyle { regular, clear }

/// Whether glass is light or dark.
///
/// `auto` follows the app theme, `system` follows the device.
enum LiquidGlassBrightness { auto, system, light, dark }

/// What platforms without native glass show.
///
/// `none` shows the child as-is, `frosted` draws Flutter glass.
enum LiquidGlassFallback { none, frosted }

/// Who draws glass on iOS and macOS.
///
/// `auto` uses Flutter glass inside scrolling content and native glass elsewhere.
enum LiquidGlassRenderer { auto, native, flutter }

@immutable
/// Every glass setting in one immutable object.
class LiquidGlassSettings {
  /// Creates settings. Every value has an iOS-like default.
  const LiquidGlassSettings({
    this.enabled = true,
    this.style = LiquidGlassStyle.regular,
    this.opacity = 1.0,
    this.tintColor,
    this.tintOpacity = 0.3,
    this.interactive = true,
    this.interactionStrength = 1.0,
    this.brightness = LiquidGlassBrightness.auto,
    this.shape = const LiquidGlassShape.capsule(),
    this.fallback = LiquidGlassFallback.none,
    this.fallbackBlurSigma = 18,
    this.collapseOnScroll = true,
    this.renderer = LiquidGlassRenderer.native,
  }) : assert(opacity >= 0 && opacity <= 1),
       assert(tintOpacity >= 0 && tintOpacity <= 1),
       assert(interactionStrength >= 0);

  /// Turns glass on or off.
  final bool enabled;

  /// Regular or clear glass.
  final LiquidGlassStyle style;

  /// How visible the glass material is, from 0 to 1.
  final double opacity;

  /// Colour mixed into the glass.
  final Color? tintColor;

  /// Strength of [tintColor], from 0 to 1.
  final double tintOpacity;

  /// Press, drag and hover motion.
  final bool interactive;

  /// Amount of motion. 0 is none, 1 matches iOS.
  final double interactionStrength;

  /// Light or dark glass.
  final LiquidGlassBrightness brightness;

  /// Shape used when none is given or detected.
  final LiquidGlassShape shape;

  /// What platforms without native glass show.
  final LiquidGlassFallback fallback;

  /// Blur of Flutter-drawn glass. 0 turns the blur off.
  final double fallbackBlurSigma;

  /// Whether navigation bars shrink while scrolling down.
  final bool collapseOnScroll;

  /// Native or Flutter-drawn glass on iOS and macOS.
  final LiquidGlassRenderer renderer;

  /// A copy with the given values replaced. Use [clearTintColor] to remove the tint.
  LiquidGlassSettings copyWith({
    bool? enabled,
    LiquidGlassStyle? style,
    double? opacity,
    Color? tintColor,
    bool clearTintColor = false,
    double? tintOpacity,
    bool? interactive,
    double? interactionStrength,
    LiquidGlassBrightness? brightness,
    LiquidGlassShape? shape,
    LiquidGlassFallback? fallback,
    double? fallbackBlurSigma,
    bool? collapseOnScroll,
    LiquidGlassRenderer? renderer,
  }) {
    return LiquidGlassSettings(
      enabled: enabled ?? this.enabled,
      style: style ?? this.style,
      opacity: opacity ?? this.opacity,
      tintColor: clearTintColor ? null : (tintColor ?? this.tintColor),
      tintOpacity: tintOpacity ?? this.tintOpacity,
      interactive: interactive ?? this.interactive,
      interactionStrength: interactionStrength ?? this.interactionStrength,
      brightness: brightness ?? this.brightness,
      shape: shape ?? this.shape,
      fallback: fallback ?? this.fallback,
      fallbackBlurSigma: fallbackBlurSigma ?? this.fallbackBlurSigma,
      collapseOnScroll: collapseOnScroll ?? this.collapseOnScroll,
      renderer: renderer ?? this.renderer,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LiquidGlassSettings &&
      other.enabled == enabled &&
      other.style == style &&
      other.opacity == opacity &&
      other.tintColor == tintColor &&
      other.tintOpacity == tintOpacity &&
      other.interactive == interactive &&
      other.interactionStrength == interactionStrength &&
      other.brightness == brightness &&
      other.shape == shape &&
      other.fallback == fallback &&
      other.fallbackBlurSigma == fallbackBlurSigma &&
      other.collapseOnScroll == collapseOnScroll &&
      other.renderer == renderer;

  @override
  int get hashCode => Object.hash(
    enabled,
    style,
    opacity,
    tintColor,
    tintOpacity,
    interactive,
    interactionStrength,
    brightness,
    shape,
    fallback,
    fallbackBlurSigma,
    collapseOnScroll,
    renderer,
  );
}
