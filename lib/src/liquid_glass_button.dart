import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'liquid_glass.dart';
import 'liquid_glass_service.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_theme.dart';

/// Look of a [LiquidGlassButton]: clear glass, lightly tinted, or filled.
enum LiquidGlassButtonStyle { glass, tinted, prominent }

/// An iOS 26 glass button that grows, follows and stretches under the finger.
class LiquidGlassButton extends StatelessWidget {
  /// A button with a text or any [child].
  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.style = LiquidGlassButtonStyle.glass,
    this.color,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.minSize = 44,
    this.shape,
    this.semanticLabel,
    this.settings,
  }) : _circle = false;

  /// A round button with an [icon].
  const LiquidGlassButton.icon({
    super.key,
    required this.onPressed,
    required Widget icon,
    this.onLongPress,
    this.style = LiquidGlassButtonStyle.glass,
    this.color,
    this.foregroundColor,
    double size = 48,
    this.semanticLabel,
    this.settings,
  }) : child = icon,
       padding = EdgeInsets.zero,
       minSize = size,
       shape = const LiquidGlassShape.circle(),
       _circle = true;

  /// Called on tap. Null disables the button.
  final VoidCallback? onPressed;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// Content of the button.
  final Widget child;

  /// Glass, tinted or prominent.
  final LiquidGlassButtonStyle style;

  /// Accent colour for tinted and prominent buttons.
  final Color? color;

  /// Colour of the text and icon.
  final Color? foregroundColor;

  /// Space around [child].
  final EdgeInsetsGeometry padding;

  /// Minimum width and height.
  final double minSize;

  /// Outline. Capsule by default, circle for icon buttons.
  final LiquidGlassShape? shape;

  /// Screen reader label.
  final String? semanticLabel;

  /// Glass settings for this widget. Falls back to the nearest [LiquidGlassTheme], then [LiquidGlassService].
  final LiquidGlassSettings? settings;
  final bool _circle;

  bool get _enabled => onPressed != null || onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final fg =
        foregroundColor ??
        switch (style) {
          LiquidGlassButtonStyle.glass => theme.colorScheme.onSurface,
          LiquidGlassButtonStyle.tinted => accent,
          LiquidGlassButtonStyle.prominent => onAccent,
        };
    final (tint, tintOpacity) = switch (style) {
      LiquidGlassButtonStyle.glass => (null, null),
      LiquidGlassButtonStyle.tinted => (accent, 0.25),
      LiquidGlassButtonStyle.prominent => (accent, 0.9),
    };
    final effectiveShape = shape ?? const LiquidGlassShape.capsule();

    return LiquidGlassSettingsBuilder(
      settings: settings,
      builder: (context, settings) {
        final glassVisible = LiquidGlassService.isGlassVisible(settings);

        Widget content = ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minSize,
            minHeight: minSize,
            maxWidth: _circle ? minSize : double.infinity,
            maxHeight: _circle ? minSize : double.infinity,
          ),
          child: Padding(
            padding: padding,
            child: Center(
              widthFactor: _circle ? null : 1,
              heightFactor: _circle ? null : 1,
              child: IconTheme.merge(
                data: IconThemeData(color: fg, size: 22),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );

        if (!glassVisible) {
          content = DecoratedBox(
            decoration: ShapeDecoration(
              shape: _circle ? const CircleBorder() : const StadiumBorder(),
              color: switch (style) {
                LiquidGlassButtonStyle.glass => fg.withValues(alpha: 0.08),
                LiquidGlassButtonStyle.tinted => accent.withValues(alpha: 0.15),
                LiquidGlassButtonStyle.prominent => accent,
              },
            ),
            child: content,
          );
        }

        return Semantics(
          button: true,
          enabled: _enabled,
          label: semanticLabel,
          child: Opacity(
            opacity: _enabled ? 1 : 0.45,
            child: IgnorePointer(
              ignoring: !_enabled,
              child: LiquidGlass(
                settings: settings,
                shape: effectiveShape,
                interactive: _enabled,
                tintColor: tint,
                tintOpacity: tintOpacity,
                child: _DragTolerantTap(
                  onTap: onPressed,
                  onLongPress: onLongPress,
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DragTolerantTap extends StatelessWidget {
  const _DragTolerantTap({
    required this.onTap,
    required this.onLongPress,
    required this.child,
  });

  static const exitDistance = 70.0;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    final onLongPress = this.onLongPress;
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        if (onTap != null)
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                () => TapGestureRecognizer(
                  preAcceptSlopTolerance: null,
                  postAcceptSlopTolerance: null,
                ),
                (recognizer) => recognizer.onTapUp = (details) {
                  final size = context.size;
                  if (size == null) return;
                  final zone = (Offset.zero & size).inflate(exitDistance);
                  if (zone.contains(details.localPosition)) onTap();
                },
              ),
        if (onLongPress != null)
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                LongPressGestureRecognizer.new,
                (recognizer) => recognizer.onLongPress = onLongPress,
              ),
      },
      child: child,
    );
  }
}
