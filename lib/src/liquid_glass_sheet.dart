import 'package:flutter/material.dart';

import 'liquid_glass.dart';
import 'liquid_glass_button.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';

/// A glass panel for bottom sheets.
class LiquidGlassSheet extends StatelessWidget {
  /// Creates a sheet around [child].
  const LiquidGlassSheet({
    super.key,
    required this.child,
    this.showDragHandle = true,
    this.radius = 36,
    this.settings,
  });

  /// Content of the sheet.
  final Widget child;

  /// Whether to show the drag handle.
  final bool showDragHandle;

  /// Corner radius.
  final double radius;

  /// Glass settings for this widget. Falls back to the nearest [LiquidGlassTheme], then [LiquidGlassService].
  final LiquidGlassSettings? settings;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return LiquidGlass(
      settings: settings,
      interactive: false,
      shape: LiquidGlassShape.roundedRect(radius),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 36,
                height: 5,
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: fg.withValues(alpha: 0.25),
                ),
              ),
            ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// Shows a modal bottom sheet built by [builder] on a [LiquidGlassSheet].
Future<T?> showLiquidGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool showDragHandle = true,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  EdgeInsets margin = const EdgeInsets.all(8),
  LiquidGlassSettings? settings,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: true,
    barrierColor: dark ? const Color(0x52000000) : const Color(0x1F000000),
    builder: (context) {
      final insets = MediaQuery.viewInsetsOf(context);
      return SafeArea(
        top: false,
        minimum: margin,
        child: Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: LiquidGlassSheet(
            showDragHandle: showDragHandle,
            settings: settings,
            child: Builder(builder: builder),
          ),
        ),
      );
    },
  );
}

/// An iOS 26 glass search field.
class LiquidGlassSearchBar extends StatefulWidget {
  /// Creates a search bar.
  const LiquidGlassSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.autofocus = false,
    this.height = 48,
    this.settings,
  });

  /// Controls the text.
  final TextEditingController? controller;

  /// Controls the focus.
  final FocusNode? focusNode;

  /// Placeholder text.
  final String hintText;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits.
  final ValueChanged<String>? onSubmitted;

  /// Widget after the text field.
  final Widget? trailing;

  /// Whether to focus on start.
  final bool autofocus;

  /// Height of the field.
  final double height;
  final LiquidGlassSettings? settings;

  @override
  State<LiquidGlassSearchBar> createState() => _LiquidGlassSearchBarState();
}

class _LiquidGlassSearchBarState extends State<LiquidGlassSearchBar> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(LiquidGlassSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_rebuild);
      if (widget.controller != null) {
        _ownController?.dispose();
        _ownController = null;
      }
      _controller.addListener(_rebuild);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_rebuild);
      if (widget.focusNode != null) {
        _ownFocus?.dispose();
        _ownFocus = null;
      }
      _focus.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _focus.removeListener(_rebuild);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _close() {
    _controller.clear();
    widget.onChanged?.call('');
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface;
    final hint = theme.colorScheme.onSurfaceVariant;
    final focused = _focus.hasFocus;
    final hasText = _controller.text.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: LiquidGlass(
            settings: widget.settings,
            interactive: false,
            child: SizedBox(
              height: widget.height,
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded, color: hint, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: widget.autofocus,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(color: fg, fontSize: 17),
                      cursorColor: theme.colorScheme.primary,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: TextStyle(color: hint, fontSize: 17),
                      ),
                    ),
                  ),
                  if (hasText)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: MaterialLocalizations.of(context)
                          .deleteButtonTooltip,
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged?.call('');
                      },
                      icon: Icon(Icons.cancel_rounded, color: hint, size: 20),
                    )
                  else if (widget.trailing != null)
                    IconTheme.merge(
                      data: IconThemeData(color: hint),
                      child: widget.trailing!,
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: focused
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: LiquidGlassButton.icon(
                    settings: widget.settings,
                    size: widget.height,
                    semanticLabel: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    onPressed: _close,
                    icon: const Icon(Icons.close_rounded),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
