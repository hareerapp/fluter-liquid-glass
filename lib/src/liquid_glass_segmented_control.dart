import 'package:flutter/material.dart';

import 'glass_selection_bar.dart';
import 'liquid_glass_settings.dart';

class LiquidGlassSegmentedControl<T> extends StatelessWidget {
  const LiquidGlassSegmentedControl({
    super.key,
    required this.children,
    required this.value,
    required this.onValueChanged,
    this.height = 40,
    this.padding = 4,
    this.activeColor,
    this.inactiveColor,
    this.semanticLabels,
    this.settings,
  }) : assert(children.length >= 2);

  final Map<T, Widget> children;
  final T value;
  final ValueChanged<T> onValueChanged;
  final double height;
  final double padding;

  final Color? activeColor;

  final Color? inactiveColor;

  final List<String>? semanticLabels;

  final LiquidGlassSettings? settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final active = activeColor ?? theme.colorScheme.onSurface;
    final inactive = inactiveColor ?? theme.colorScheme.onSurfaceVariant;
    final keys = children.keys.toList();
    final index = keys.indexOf(value);
    assert(index >= 0, 'value must be one of the children keys');

    return GlassSelectionBar(
      count: keys.length,
      currentIndex: index < 0 ? 0 : index,
      onSelected: (i) => onValueChanged(keys[i]),
      height: height,
      padding: padding,
      pillColor: dark ? const Color(0x33FFFFFF) : const Color(0xF2FFFFFF),
      pillShadow: false,
      semanticLabels: semanticLabels,
      settings: settings,
      lensOverflow: 10,
      itemBuilder: (context, i, selection, lift, collapse) {
        return Center(
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: Color.lerp(inactive, active, selection),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: Color.lerp(inactive, active, selection),
                size: 18,
              ),
              child: Transform.scale(
                scale: 1 + 0.12 * lift.clamp(0.0, 1.0) * selection,
                child: children[keys[i]]!,
              ),
            ),
          ),
        );
      },
    );
  }
}
