import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'host_platform.dart';
import 'liquid_glass_settings.dart';

@immutable
/// What the device supports, reported by the plugin.
class LiquidGlassCapabilities {
  /// Creates a capabilities report.
  const LiquidGlassCapabilities({
    required this.liquidGlass,
    this.osVersion,
    this.reduceTransparency = false,
  });

  /// No native glass.
  static const none = LiquidGlassCapabilities(liquidGlass: false);

  /// Whether native Liquid Glass is available.
  final bool liquidGlass;

  /// The operating system version, when known.
  final String? osVersion;

  /// Whether the user turned on Reduce Transparency.
  final bool reduceTransparency;

  @override
  String toString() =>
      'LiquidGlassCapabilities(liquidGlass: $liquidGlass, '
      'osVersion: $osVersion, reduceTransparency: $reduceTransparency)';
}

/// App-wide glass settings and platform checks.
class LiquidGlassService extends ChangeNotifier {
  LiquidGlassService._();

  /// The shared service.
  static final LiquidGlassService instance = LiquidGlassService._();

  static const _channel = MethodChannel('liquid_design');

  /// Whether the app runs on iOS or macOS.
  static bool get isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// First iOS and macOS version with Liquid Glass.
  static const liquidGlassMajorVersion = 26;

  @visibleForTesting
  static int? debugOsMajorVersion;

  static final (String, int?)? _host = switch (kIsWeb ? null : hostPlatform()) {
    (final os, final version) => (os, _parseMajor(version)),
    null => null,
  };

  static int? _parseMajor(String version) {
    final match = RegExp(r'(\d+)(?:\.\d+)').firstMatch(version);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// The major iOS or macOS version, when known.
  static int? get osMajorVersion {
    final override = debugOsMajorVersion;
    if (override != null) return override;
    final host = _host;
    if (host == null) return null;
    final target = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      _ => null,
    };
    return host.$1 == target ? host.$2 : null;
  }

  /// Whether native Liquid Glass is used on this device.
  ///
  /// False on iOS and macOS before 26, which then behave like Android.
  static bool get isNativePlatform {
    if (!isApplePlatform) return false;
    final service = instance;
    if (service._capabilitiesLoaded) return service._capabilities.liquidGlass;
    final major = osMajorVersion;
    return major == null || major >= liquidGlassMajorVersion;
  }

  /// Whether any glass is drawn with [settings].
  static bool isGlassVisible(LiquidGlassSettings settings) =>
      settings.enabled &&
      (isNativePlatform || settings.fallback == LiquidGlassFallback.frosted);

  /// Whether glass at [context] is drawn natively.
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

  /// Whether control thumbs use the native lens.
  static bool usesNativeLens(LiquidGlassSettings settings) =>
      isNativePlatform &&
      settings.enabled &&
      settings.renderer != LiquidGlassRenderer.flutter;

  /// Whether [context] is inside scrolling content.
  static bool isInScrollingContent(BuildContext context) {
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null && scrollable.position is PageMetrics) {
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    return scrollable != null;
  }

  LiquidGlassSettings _settings = const LiquidGlassSettings();
  LiquidGlassCapabilities _capabilities = LiquidGlassCapabilities.none;
  bool _capabilitiesLoaded = false;
  Future<LiquidGlassCapabilities>? _capabilitiesFuture;

  /// What the device supports.
  LiquidGlassCapabilities get capabilities => _capabilities;

  /// Whether the plugin reported native Liquid Glass.
  bool get isLiquidGlassSupported => _capabilities.liquidGlass;

  @visibleForTesting
  void debugSetCapabilities(LiquidGlassCapabilities? capabilities) {
    _capabilities = capabilities ?? LiquidGlassCapabilities.none;
    _capabilitiesLoaded = capabilities != null;
    notifyListeners();
  }

  /// Asks the plugin for the device capabilities once.
  Future<LiquidGlassCapabilities> ensureInitialized() {
    return _capabilitiesFuture ??= () async {
      if (!isApplePlatform) return LiquidGlassCapabilities.none;
      try {
        final map = await _channel.invokeMapMethod<String, Object?>(
          'getCapabilities',
        );
        _capabilities = LiquidGlassCapabilities(
          liquidGlass: map?['liquidGlass'] == true,
          osVersion: map?['osVersion'] as String?,
          reduceTransparency: map?['reduceTransparency'] == true,
        );
        _capabilitiesLoaded = map != null;
        notifyListeners();
      } on MissingPluginException catch (_) {
      } on PlatformException catch (_) {}
      return _capabilities;
    }();
  }

  /// The app-wide settings.
  LiquidGlassSettings get settings => _settings;

  set settings(LiquidGlassSettings value) {
    if (value == _settings) return;
    _settings = value;
    notifyListeners();
  }

  /// Changes the settings with [updater].
  void update(
    LiquidGlassSettings Function(LiquidGlassSettings current) updater,
  ) {
    settings = updater(_settings);
  }

  /// Restores the default settings.
  void reset() => settings = const LiquidGlassSettings();

  /// Turns glass on or off.
  void setEnabled(bool enabled) => update((s) => s.copyWith(enabled: enabled));

  /// Sets regular or clear glass.
  void setStyle(LiquidGlassStyle style) =>
      update((s) => s.copyWith(style: style));

  /// Sets how visible the glass is.
  void setOpacity(double opacity) =>
      update((s) => s.copyWith(opacity: opacity.clamp(0.0, 1.0)));

  /// Sets or removes the tint.
  void setTint(Color? color, {double? opacity}) => update(
    (s) => s.copyWith(
      tintColor: color,
      clearTintColor: color == null,
      tintOpacity: opacity?.clamp(0.0, 1.0),
    ),
  );

  /// Turns press and drag motion on or off.
  void setInteractive(bool interactive) =>
      update((s) => s.copyWith(interactive: interactive));

  /// Sets the amount of motion.
  void setInteractionStrength(double strength) => update(
    (s) => s.copyWith(interactionStrength: strength < 0 ? 0 : strength),
  );

  /// Sets light, dark or automatic glass.
  void setBrightness(LiquidGlassBrightness brightness) =>
      update((s) => s.copyWith(brightness: brightness));

  /// Sets what platforms without native glass show.
  void setFallback(LiquidGlassFallback fallback) =>
      update((s) => s.copyWith(fallback: fallback));

  /// Lets navigation bars shrink while scrolling.
  void setCollapseOnScroll(bool enabled) =>
      update((s) => s.copyWith(collapseOnScroll: enabled));

  /// Sets native or Flutter-drawn glass.
  void setRenderer(LiquidGlassRenderer renderer) =>
      update((s) => s.copyWith(renderer: renderer));
}
