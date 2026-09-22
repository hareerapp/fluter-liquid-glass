import 'package:flutter/material.dart';

import 'liquid_glass.dart';
import 'liquid_glass_button.dart';
import 'liquid_glass_group.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';

class LiquidGlassAppBar extends StatefulWidget implements PreferredSizeWidget {
  const LiquidGlassAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.titleInGlass = false,
    this.scrollEdgeEffect = true,
    this.edgeColor,
    this.toolbarHeight = 56,
    this.groupGlass = true,
    this.settings,
  });

  final Widget? leading;
  final Widget? title;

  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool centerTitle;

  final bool titleInGlass;

  final bool scrollEdgeEffect;

  final Color? edgeColor;
  final double toolbarHeight;

  final bool groupGlass;
  final LiquidGlassSettings? settings;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  State<LiquidGlassAppBar> createState() => _LiquidGlassAppBarState();
}

class _LiquidGlassAppBarState extends State<LiquidGlassAppBar> {
  ScrollNotificationObserverState? _observer;
  bool _scrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_onScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return;
    }
    final scrolled = notification.metrics.extentBefore > 0;
    if (scrolled != _scrolledUnder) setState(() => _scrolledUnder = scrolled);
  }

  Widget _grouped(Widget toolbar) => widget.groupGlass
      ? LiquidGlassGroup(spacing: 0, child: toolbar)
      : toolbar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final fg = theme.colorScheme.onSurface;
    final edge = widget.edgeColor ?? theme.scaffoldBackgroundColor;
    final settings = widget.settings;

    Widget? leading = widget.leading;
    if (leading == null && widget.automaticallyImplyLeading) {
      final route = ModalRoute.of(context);
      if (route?.impliesAppBarDismissal ?? false) {
        leading = LiquidGlassButton.icon(
          settings: settings,
          semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        );
      }
    } else if (leading != null && leading is! LiquidGlassButton) {
      leading = LiquidGlass(
        settings: settings,
        shape: const LiquidGlassShape.circle(),
        child: SizedBox.square(dimension: 48, child: Center(child: leading)),
      );
    }

    Widget? title = widget.title;
    if (title != null) {
      title = DefaultTextStyle.merge(
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: fg,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: title,
      );
      if (widget.titleInGlass) {
        title = LiquidGlass(
          settings: settings,
          interactive: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: title,
          ),
        );
      }
      title = Semantics(header: true, child: title);
    }

    final actions = widget.actions;
    Widget? trailing;
    if (actions != null && actions.isNotEmpty) {
      trailing = LiquidGlass(
        settings: settings,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: actions.length > 1 ? 2 : 0),
          child: Row(mainAxisSize: MainAxisSize.min, children: actions),
        ),
      );
    }

    return IconTheme.merge(
      data: IconThemeData(color: fg),
      child: SizedBox(
        height: top + widget.toolbarHeight,
        child: Stack(
          children: [
            if (widget.scrollEdgeEffect)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: top + widget.toolbarHeight + 24,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _scrolledUnder ? 1 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            edge.withValues(alpha: 0.92),
                            edge.withValues(alpha: 0.6),
                            edge.withValues(alpha: 0),
                          ],
                          stops: const [0, 0.55, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              top: top,
              height: widget.toolbarHeight,
              child: _grouped(
                NavigationToolbar(
                  leading: leading,
                  middle: title,
                  trailing: trailing,
                  centerMiddle: widget.centerTitle,
                  middleSpacing: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
