import 'package:flutter/material.dart';

import 'liquid_glass.dart';
import 'liquid_glass_service.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_theme.dart';

enum LiquidGlassButtonStyle { glass, tinted, prominent }

class LiquidGlassButton extends StatelessWidget {
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

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final LiquidGlassButtonStyle style;

  final Color? color;

  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;

  final double minSize;

  final LiquidGlassShape? shape;

  final String? semanticLabel;
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
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
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
