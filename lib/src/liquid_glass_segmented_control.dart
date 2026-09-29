import 'package:flutter/material.dart';

import 'glass_selection_bar.dart';
import 'liquid_glass_settings.dart';

/// An iOS 26 segmented control whose selection lifts into a glass lens.
class LiquidGlassSegmentedControl<T> extends StatelessWidget {
  /// Creates a segmented control.
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

  /// The segments by value.
  final Map<T, Widget> children;

  /// The selected value.
  final T value;

  /// Called when a segment is chosen.
  final ValueChanged<T> onValueChanged;

  /// Height of the control.
  final double height;

  /// Space between the edge and the selection.
  final double padding;

  /// Colour of the selected segment.
  final Color? activeColor;

  /// Colour of the other segments.
  final Color? inactiveColor;

  /// Screen reader labels for the segments.
  final List<String>? semanticLabels;

  /// Glass settings for this widget. Falls back to the nearest [LiquidGlassTheme], then [LiquidGlassService].
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
