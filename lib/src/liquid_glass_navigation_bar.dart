import 'package:flutter/material.dart';

import 'glass_selection_bar.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_theme.dart';

/// One tab of a [LiquidGlassNavigationBar].
class LiquidGlassNavItem {
  /// Creates a tab.
  const LiquidGlassNavItem({required this.icon, this.activeIcon, this.label});

  /// Icon of the tab.
  final Widget icon;

  /// Icon shown while the tab is selected.
  final Widget? activeIcon;

  /// Text under the icon.
  final String? label;
}

/// An iOS 26 glass tab bar with a sliding, stretching selection.
class LiquidGlassNavigationBar extends StatelessWidget {
  /// Creates a navigation bar with at least two [items].
  const LiquidGlassNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.activeColor,
    this.inactiveColor,
    this.height,
    this.padding = 4,
    this.settings,
    this.collapsed = false,
    this.onExpand,
    this.onReselect,
  }) : assert(items.length >= 2),
       assert(currentIndex >= 0 && currentIndex < items.length);

  /// The tabs.
  final List<LiquidGlassNavItem> items;

  /// Index of the selected tab.
  final int currentIndex;

  /// Called when a tab is chosen.
  final ValueChanged<int> onTap;

  /// Colour of the selected tab.
  final Color? activeColor;

  /// Colour of the other tabs.
  final Color? inactiveColor;

  /// Height of the bar. 64 with labels, 56 without.
  final double? height;

  /// Space between the bar edge and the selection.
  final double padding;

  /// Glass settings for this widget. Falls back to the nearest [LiquidGlassTheme], then [LiquidGlassService].
  final LiquidGlassSettings? settings;

  /// Shrinks the bar to the selected tab.
  final bool collapsed;

  /// Called when a collapsed bar is tapped.
  final VoidCallback? onExpand;

  /// Called when the selected tab is tapped again.
  final ValueChanged<int>? onReselect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = activeColor ?? theme.colorScheme.primary;
    final inactive = inactiveColor ?? theme.colorScheme.onSurface;
    final hasLabels = items.any((item) => item.label != null);

    return LiquidGlassSettingsBuilder(
      settings: settings,
      builder: (context, glass) => GlassSelectionBar(
        count: items.length,
        currentIndex: currentIndex,
        onSelected: onTap,
        height: height ?? (hasLabels ? 64.0 : 56.0),
        padding: padding,
        pillColor: inactive.withValues(alpha: 0.1),
        semanticLabels: [for (final item in items) item.label],
        settings: settings,
        collapsed: collapsed && glass.collapseOnScroll,
        onExpand: onExpand,
        onReselected: onReselect,
        itemBuilder: (context, i, selection, lift, collapse) {
          final item = items[i];
          final color = Color.lerp(inactive, active, selection)!;
          final scale = 1 + 0.18 * lift.clamp(0.0, 1.0) * selection;
          final labelOpacity = (1 - collapse * 2).clamp(0.0, 1.0);

          return Transform.scale(
            scale: scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme.merge(
                  data: IconThemeData(color: color, size: 24),
                  child: selection > 0.5
                      ? (item.activeIcon ?? item.icon)
                      : item.icon,
                ),
                if (item.label != null && labelOpacity > 0) ...[
                  const SizedBox(height: 2),
                  Opacity(
                    opacity: labelOpacity,
                    child: ExcludeSemantics(
                      child: Text(
                        item.label!,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Reports when scrolling [child] should collapse a navigation bar.
class LiquidGlassScrollCollapse extends StatefulWidget {
  /// Creates a scroll listener for [child].
  const LiquidGlassScrollCollapse({
    super.key,
    required this.onChanged,
    required this.child,
    this.threshold = 24,
    this.collapsed,
    this.settings,
  });

  /// Called with true to collapse and false to expand.
  final ValueChanged<bool> onChanged;

  /// The scrolling content.
  final Widget child;

  /// The current collapsed state, when known.
  final bool? collapsed;

  /// Glass settings for this widget. Falls back to the nearest [LiquidGlassTheme], then [LiquidGlassService].
  final LiquidGlassSettings? settings;

  /// Distance to scroll before the state changes.
  final double threshold;

  @override
  State<LiquidGlassScrollCollapse> createState() =>
      _LiquidGlassScrollCollapseState();
}

class _LiquidGlassScrollCollapseState extends State<LiquidGlassScrollCollapse> {
  bool _collapsed = false;
  double _accumulated = 0;

  void _set(bool collapsed) {
    _accumulated = 0;
    if (collapsed == _collapsed) return;
    _collapsed = collapsed;
    widget.onChanged(collapsed);
  }

  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.collapsed ?? false;
  }

  @override
  void didUpdateWidget(LiquidGlassScrollCollapse oldWidget) {
    super.didUpdateWidget(oldWidget);
    final collapsed = widget.collapsed;
    if (collapsed != null && collapsed != _collapsed) {
      _collapsed = collapsed;
      _accumulated = 0;
    }
  }

  bool _onScroll(ScrollUpdateNotification n) {
    if (!_enabled) return false;
    if (n.metrics.axis != Axis.vertical) return false;
    final delta = n.scrollDelta ?? 0;
    if (delta == 0) return false;
    if (n.metrics.pixels <= n.metrics.minScrollExtent + 8) {
      _set(false);
      return false;
    }
    if (n.metrics.pixels > n.metrics.maxScrollExtent) return false;
    if (delta.sign != _accumulated.sign) _accumulated = 0;
    _accumulated += delta;
    if (_accumulated > widget.threshold) _set(true);
    if (_accumulated < -widget.threshold) _set(false);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSettingsBuilder(
      settings: widget.settings,
      builder: (context, glass) {
        _enabled = glass.collapseOnScroll;
        if (!_enabled && _collapsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_enabled) _set(false);
          });
        }
        return NotificationListener<ScrollUpdateNotification>(
          onNotification: _onScroll,
          child: widget.child,
        );
      },
    );
  }
}
