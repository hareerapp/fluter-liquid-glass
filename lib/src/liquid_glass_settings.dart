import 'package:flutter/widgets.dart';

import 'liquid_glass_shape.dart';

enum LiquidGlassStyle { regular, clear }

enum LiquidGlassBrightness { auto, system, light, dark }

enum LiquidGlassFallback { none, frosted }

enum LiquidGlassRenderer { auto, native, flutter }

@immutable
class LiquidGlassSettings {
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

  final bool enabled;

  final LiquidGlassStyle style;

  final double opacity;

  final Color? tintColor;

  final double tintOpacity;

  final bool interactive;

  final double interactionStrength;

  final LiquidGlassBrightness brightness;

  final LiquidGlassShape shape;

  final LiquidGlassFallback fallback;

  final double fallbackBlurSigma;

  final bool collapseOnScroll;

  final LiquidGlassRenderer renderer;

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
