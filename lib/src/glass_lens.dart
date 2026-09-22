import 'package:flutter/cupertino.dart' show CupertinoTheme;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'liquid_glass_settings.dart';

enum LensMotion { instant, follow, spring }

class GlassLensController {
  _GlassLensHostState? _host;
  final List<Map<String, Object?>> _pending = [];

  void move(
    Rect rect, {
    double alpha = 1,
    LensMotion motion = LensMotion.spring,
    double duration = 0.45,
    double damping = 0.72,
  }) {
    final command = <String, Object?>{
      'x': rect.left,
      'y': rect.top,
      'w': rect.width,
      'h': rect.height,
      'alpha': alpha,
      'motion': motion.name,
      'duration': duration,
      'damping': damping,
    };
    final host = _host;
    if (host == null) {
      _queue(command);
    } else {
      host._send(command);
    }
  }

  void _queue(Map<String, Object?> command) {
    if (_pending.length >= 2) _pending.removeLast();
    _pending.add(command);
  }
}

class GlassLensHost extends StatefulWidget {
  const GlassLensHost({
    super.key,
    required this.controller,
    required this.settings,
    required this.margin,
  });

  final GlassLensController controller;
  final LiquidGlassSettings settings;
  final double margin;

  static const viewType = 'liquid_design/lens';

  @override
  State<GlassLensHost> createState() => _GlassLensHostState();
}

class _GlassLensHostState extends State<GlassLensHost> {
  MethodChannel? _channel;
  Map<String, Object?> _config = const {};
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    widget.controller._host = this;
  }

  @override
  void didUpdateWidget(GlassLensHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._host = null;
      widget.controller._host = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._host == this) widget.controller._host = null;
    super.dispose();
  }

  Map<String, Object?> _configFor(BuildContext context) {
    final brightness = switch (widget.settings.brightness) {
      LiquidGlassBrightness.auto => CupertinoTheme.brightnessOf(context).name,
      LiquidGlassBrightness.system => 'system',
      LiquidGlassBrightness.light => 'light',
      LiquidGlassBrightness.dark => 'dark',
    };
    return {'style': 'clear', 'brightness': brightness};
  }

  void _send(Map<String, Object?> command) {
    final channel = _channel;
    if (channel == null) {
      widget.controller._queue(command);
      return;
    }
    final m = widget.margin;
    final shifted = {
      ..._config,
      ...command,
      'x': (command['x']! as double) + m,
      'y': (command['y']! as double) + m,
      if (_reduceMotion) 'damping': 1.0,
    };
    channel.invokeMethod<void>('update', shifted).catchError((_) {});
  }

  void _onCreated(int id) {
    _channel = MethodChannel('${GlassLensHost.viewType}_$id');
    final pending = [...widget.controller._pending];
    widget.controller._pending.clear();
    pending.forEach(_send);
  }

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final config = _configFor(context);
    if (!mapEquals(config, _config)) {
      if (_config.isNotEmpty) _channel = null;
      _config = config;
    }

    final Widget view = defaultTargetPlatform == TargetPlatform.macOS
        ? AppKitView(
            key: ValueKey(_config['brightness']),
            viewType: GlassLensHost.viewType,
            creationParams: _config,
            creationParamsCodec: const StandardMessageCodec(),
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            onPlatformViewCreated: _onCreated,
          )
        : UiKitView(
            key: ValueKey(_config['brightness']),
            viewType: GlassLensHost.viewType,
            creationParams: _config,
            creationParamsCodec: const StandardMessageCodec(),
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            onPlatformViewCreated: _onCreated,
          );
    return IgnorePointer(child: ExcludeSemantics(child: view));
  }
}
