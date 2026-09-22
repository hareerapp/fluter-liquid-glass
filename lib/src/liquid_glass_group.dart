import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'liquid_glass_service.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_theme.dart';

class LiquidGlassGroup extends StatefulWidget {
  const LiquidGlassGroup({
    super.key,
    this.spacing = 20,
    this.overflow = 24,
    required this.child,
  });

  final double spacing;

  final double overflow;

  final Widget child;

  static GlassGroupHandle? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_GroupScope>();
    return scope != null && scope.native ? scope.handle : null;
  }

  @override
  State<LiquidGlassGroup> createState() => _LiquidGlassGroupState();
}

abstract class GlassGroupHandle {
  void register(GlassGroupSlotState slot);
  void unregister(GlassGroupSlotState slot);
  void markDirty();
}

class _GroupScope extends InheritedWidget {
  const _GroupScope({
    required this.handle,
    required this.native,
    required super.child,
  });

  final GlassGroupHandle handle;
  final bool native;

  @override
  bool updateShouldNotify(_GroupScope oldWidget) =>
      handle != oldWidget.handle || native != oldWidget.native;
}

class _LiquidGlassGroupState extends State<LiquidGlassGroup>
    implements GlassGroupHandle {
  static const _viewType = 'liquid_design/glass_group';

  final _slots = <GlassGroupSlotState>{};
  final _boundaryKey = GlobalKey();
  MethodChannel? _channel;
  List<Map<String, Object?>>? _lastSent;
  double? _lastSpacing;

  int _generation = 0;
  Object? _brightness;
  bool _scheduled = false;
  bool _disposed = false;

  bool _active = true;

  @override
  void register(GlassGroupSlotState slot) {
    _slots.add(slot);
    markDirty();
  }

  @override
  void unregister(GlassGroupSlotState slot) {
    _slots.remove(slot);
    markDirty();
  }

  @override
  void markDirty() {
    _schedule();
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void didUpdateWidget(LiquidGlassGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spacing != widget.spacing ||
        oldWidget.overflow != widget.overflow) {
      markDirty();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _schedule() {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_disposed) return;
      _sync();
      _schedule();
    });
  }

  void _sync() {
    if (!_active) return;
    final channel = _channel;
    final groupBox =
        _boundaryKey.currentContext?.findRenderObject() as RenderBox?;
    if (channel == null || groupBox == null || !groupBox.hasSize) return;

    final members = <Map<String, Object?>>[];
    for (final slot in _slots) {
      final member = slot.describe(groupBox, widget.overflow);
      if (member != null) members.add(member);
    }
    final brightness = members.isEmpty ? null : members.first['brightness'];
    if (brightness != null && brightness != _brightness) {
      final changed = _brightness != null;
      _brightness = brightness;
      if (changed) {
        setState(() {
          _generation++;
          _channel = null;
          _lastSent = null;
        });
        return;
      }
    }
    final last = _lastSent;
    if (last != null &&
        _lastSpacing == widget.spacing &&
        last.length == members.length) {
      var same = true;
      for (var i = 0; i < members.length && same; i++) {
        same = mapEquals(last[i], members[i]);
      }
      if (same) return;
    }
    _lastSent = members;
    _lastSpacing = widget.spacing;
    channel
        .invokeMethod<void>('update', <String, Object?>{
          'spacing': widget.spacing,
          'members': members,
        })
        .catchError((_) {});
  }

  void _onCreated(int id) {
    _channel = MethodChannel('${_viewType}_$id');
    _lastSent = null;
    markDirty();
  }

  @override
  Widget build(BuildContext context) {
    if (!LiquidGlassService.isNativePlatform) return widget.child;
    return LiquidGlassSettingsBuilder(
      builder: (context, settings) => _buildGroup(
        context,
        settings.enabled && settings.renderer != LiquidGlassRenderer.flutter,
      ),
    );
  }

  Widget _buildGroup(BuildContext context, bool native) {
    if (!native) {
      _channel = null;
      _lastSent = null;
    }
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_active) markDirty();
    _active = active;

    final params = <String, Object?>{'spacing': widget.spacing};
    final Widget view = defaultTargetPlatform == TargetPlatform.macOS
        ? AppKitView(
            key: ValueKey(_generation),
            viewType: _viewType,
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            onPlatformViewCreated: _onCreated,
          )
        : UiKitView(
            key: ValueKey(_generation),
            viewType: _viewType,
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            onPlatformViewCreated: _onCreated,
          );

    return _GroupScope(
      handle: this,
      native: native,
      child: Stack(
        key: _boundaryKey,
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          if (native)
            Positioned(
              left: -widget.overflow,
              top: -widget.overflow,
              right: -widget.overflow,
              bottom: -widget.overflow,
              child: IgnorePointer(child: ExcludeSemantics(child: view)),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class GlassGroupSlot extends StatefulWidget {
  const GlassGroupSlot({
    super.key,
    required this.group,
    required this.shape,
    required this.params,
  });

  final GlassGroupHandle group;
  final LiquidGlassShape shape;
  final Map<String, Object?> params;

  @override
  State<GlassGroupSlot> createState() => GlassGroupSlotState();
}

class GlassGroupSlotState extends State<GlassGroupSlot> {
  static int _nextId = 0;
  final int id = _nextId++;

  @override
  void initState() {
    super.initState();
    widget.group.register(this);
  }

  @override
  void didUpdateWidget(GlassGroupSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group) {
      oldWidget.group.unregister(this);
      widget.group.register(this);
    } else if (!mapEquals(oldWidget.params, widget.params) ||
        oldWidget.shape != widget.shape) {
      widget.group.markDirty();
    }
  }

  @override
  void dispose() {
    widget.group.unregister(this);
    super.dispose();
  }

  Map<String, Object?>? describe(RenderBox groupBox, double overflow) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    final size = box.size;
    if (size.isEmpty) return null;

    final transform = box.getTransformTo(groupBox);
    final rect = MatrixUtils.transformRect(
      transform,
      Offset.zero & size,
    ).shift(Offset(overflow, overflow));
    final scale = math.min(rect.width / size.width, rect.height / size.height);
    final radius = widget.shape.isCapsule
        ? math.min(rect.width, rect.height) / 2
        : widget.shape.resolveRadius(size) * scale;

    double r(double v) => (v * 100).roundToDouble() / 100;
    return {
      ...widget.params,
      'id': id,
      'x': r(rect.left),
      'y': r(rect.top),
      'w': r(rect.width),
      'h': r(rect.height),
      'cornerRadius': r(radius),
    };
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
