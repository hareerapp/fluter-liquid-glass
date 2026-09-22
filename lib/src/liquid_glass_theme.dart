import 'package:flutter/widgets.dart';

import 'liquid_glass_service.dart';
import 'liquid_glass_settings.dart';

class LiquidGlassTheme extends InheritedWidget {
  const LiquidGlassTheme({
    super.key,
    required this.settings,
    required super.child,
  });

  final LiquidGlassSettings settings;

  static LiquidGlassSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiquidGlassTheme>()?.settings;

  static LiquidGlassSettings of(BuildContext context) =>
      maybeOf(context) ?? LiquidGlassService.instance.settings;

  @override
  bool updateShouldNotify(LiquidGlassTheme oldWidget) =>
      oldWidget.settings != settings;
}

class LiquidGlassSettingsBuilder extends StatelessWidget {
  const LiquidGlassSettingsBuilder({
    super.key,
    this.settings,
    required this.builder,
  });

  final LiquidGlassSettings? settings;
  final Widget Function(BuildContext context, LiquidGlassSettings settings)
  builder;

  @override
  Widget build(BuildContext context) {
    final scoped = settings ?? LiquidGlassTheme.maybeOf(context);
    if (scoped != null) return builder(context, scoped);
    final service = LiquidGlassService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => builder(context, service.settings),
    );
  }
}
