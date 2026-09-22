import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class NativePlatformGlass extends StatefulWidget {
  const NativePlatformGlass({
    super.key,
    required this.viewType,
    required this.params,
  });

  final String viewType;

  final Map<String, Object?> params;

  @override
  State<NativePlatformGlass> createState() => _NativePlatformGlassState();
}

class _NativePlatformGlassState extends State<NativePlatformGlass> {
  MethodChannel? _channel;
  late Map<String, Object?> _sentParams = widget.params;

  int _generation = 0;

  @override
  void didUpdateWidget(NativePlatformGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params['brightness'] != widget.params['brightness']) {
      _generation++;
      _channel = null;
      _sentParams = widget.params;
      return;
    }
    _sync();
  }

  void _onCreated(int id) {
    _channel = MethodChannel('${widget.viewType}_$id');
    _sync();
  }

  void _sync() {
    final channel = _channel;
    if (channel == null || mapEquals(_sentParams, widget.params)) return;
    _sentParams = widget.params;
    channel.invokeMethod<void>('update', widget.params).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(child: _platformView());
  }

  Widget _platformView() {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return AppKitView(
        key: ValueKey(_generation),
        viewType: widget.viewType,
        creationParams: _sentParams,
        creationParamsCodec: const StandardMessageCodec(),
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        onPlatformViewCreated: _onCreated,
      );
    }
    return UiKitView(
      key: ValueKey(_generation),
      viewType: widget.viewType,
      creationParams: _sentParams,
      creationParamsCodec: const StandardMessageCodec(),
      hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      onPlatformViewCreated: _onCreated,
    );
  }
}

class NativeGlassView extends StatelessWidget {
  const NativeGlassView({super.key, required this.params});

  final Map<String, Object?> params;

  @override
  Widget build(BuildContext context) =>
      NativePlatformGlass(viewType: 'liquid_design/glass', params: params);
}
