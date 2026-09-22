import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'liquid_glass_settings.dart';

@immutable
class LiquidGlassCapabilities {
  const LiquidGlassCapabilities({
    required this.liquidGlass,
    this.osVersion,
    this.reduceTransparency = false,
  });

  static const none = LiquidGlassCapabilities(liquidGlass: false);

  final bool liquidGlass;

  final String? osVersion;

  final bool reduceTransparency;

  @override
  String toString() =>
      'LiquidGlassCapabilities(liquidGlass: $liquidGlass, '
      'osVersion: $osVersion, reduceTransparency: $reduceTransparency)';
}

class LiquidGlassService extends ChangeNotifier {
  LiquidGlassService._();

  static final LiquidGlassService instance = LiquidGlassService._();

  static const _channel = MethodChannel('liquid_design');

  static bool get isNativePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static bool isGlassVisible(LiquidGlassSettings settings) =>
      settings.enabled &&
      (isNativePlatform || settings.fallback == LiquidGlassFallback.frosted);

  static bool usesNativeGlass(
    BuildContext context,
    LiquidGlassSettings settings, {
    bool grouped = false,
  }) {
    if (!isNativePlatform || !settings.enabled) return false;
    return switch (settings.renderer) {
      LiquidGlassRenderer.native => true,
      LiquidGlassRenderer.flutter => false,
      LiquidGlassRenderer.auto => grouped || !isInScrollingContent(context),
    };
  }

  static bool usesNativeLens(LiquidGlassSettings settings) =>
      isNativePlatform &&
      settings.enabled &&
      settings.renderer != LiquidGlassRenderer.flutter;

  static bool isInScrollingContent(BuildContext context) {
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null && scrollable.position is PageMetrics) {
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    return scrollable != null;
  }

  LiquidGlassSettings _settings = const LiquidGlassSettings();
  LiquidGlassCapabilities _capabilities = LiquidGlassCapabilities.none;
  Future<LiquidGlassCapabilities>? _capabilitiesFuture;

  LiquidGlassCapabilities get capabilities => _capabilities;

  bool get isLiquidGlassSupported => _capabilities.liquidGlass;

  Future<LiquidGlassCapabilities> ensureInitialized() {
    return _capabilitiesFuture ??= () async {
      if (!isNativePlatform) return LiquidGlassCapabilities.none;
      try {
        final map = await _channel.invokeMapMethod<String, Object?>(
          'getCapabilities',
        );
        _capabilities = LiquidGlassCapabilities(
          liquidGlass: map?['liquidGlass'] == true,
          osVersion: map?['osVersion'] as String?,
          reduceTransparency: map?['reduceTransparency'] == true,
        );
        notifyListeners();
      } on MissingPluginException catch (_) {
      } on PlatformException catch (_) {}
      return _capabilities;
    }();
  }

  LiquidGlassSettings get settings => _settings;

  set settings(LiquidGlassSettings value) {
    if (value == _settings) return;
    _settings = value;
    notifyListeners();
  }

  void update(
    LiquidGlassSettings Function(LiquidGlassSettings current) updater,
  ) {
    settings = updater(_settings);
  }

  void reset() => settings = const LiquidGlassSettings();

  void setEnabled(bool enabled) => update((s) => s.copyWith(enabled: enabled));

  void setStyle(LiquidGlassStyle style) =>
      update((s) => s.copyWith(style: style));

  void setOpacity(double opacity) =>
      update((s) => s.copyWith(opacity: opacity.clamp(0.0, 1.0)));

  void setTint(Color? color, {double? opacity}) => update(
    (s) => s.copyWith(
      tintColor: color,
      clearTintColor: color == null,
      tintOpacity: opacity?.clamp(0.0, 1.0),
    ),
  );

  void setInteractive(bool interactive) =>
      update((s) => s.copyWith(interactive: interactive));

  void setInteractionStrength(double strength) => update(
    (s) => s.copyWith(interactionStrength: strength < 0 ? 0 : strength),
  );

  void setBrightness(LiquidGlassBrightness brightness) =>
      update((s) => s.copyWith(brightness: brightness));

  void setFallback(LiquidGlassFallback fallback) =>
      update((s) => s.copyWith(fallback: fallback));

  void setCollapseOnScroll(bool enabled) =>
      update((s) => s.copyWith(collapseOnScroll: enabled));

  void setRenderer(LiquidGlassRenderer renderer) =>
      update((s) => s.copyWith(renderer: renderer));
}
