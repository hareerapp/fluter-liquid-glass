import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart' show VelocityTracker;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'glass_lens.dart';
import 'glass_spring.dart';
import 'glass_track.dart';
import 'liquid_glass.dart';
import 'liquid_glass_service.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_theme.dart';

typedef GlassSelectionItemBuilder = Widget Function(
  BuildContext context,
  int index,
  double selection,
  double lift,
  double collapse,
);

class GlassSelectionBar extends StatefulWidget {
  const GlassSelectionBar({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.onSelected,
    required this.itemBuilder,
    required this.height,
    required this.padding,
    required this.pillColor,
    this.pillShadow = false,
    this.semanticLabels,
    this.settings,
    this.collapsed = false,
    this.onExpand,
    this.onReselected,
    this.lensOverflow = 14,
  }) : assert(count >= 1);

  final int count;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final GlassSelectionItemBuilder itemBuilder;
  final double height;
  final double padding;
  final Color pillColor;
  final bool pillShadow;
  final List<String?>? semanticLabels;
  final LiquidGlassSettings? settings;

  final bool collapsed;

  final VoidCallback? onExpand;

  final ValueChanged<int>? onReselected;

  final double lensOverflow;

  @override
  State<GlassSelectionBar> createState() => _GlassSelectionBarState();
}

class _GlassSelectionBarState extends State<GlassSelectionBar>
    with TickerProviderStateMixin {
  static const _moveSpring = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 22,
  );
  static const _followSpring = SpringDescription(
    mass: 1,
    stiffness: 4000,
    damping: 120,
  );
  static const _liftSpring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 30,
  );
  static const _dropSpring = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 24,
  );
  static const _collapseSpring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 26,
  );
  static const _calmSpring = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 35,
  );

  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
  );

  late final AnimationController _lift = AnimationController.unbounded(
    vsync: this,
  );

  late final AnimationController _collapse = AnimationController.unbounded(
    vsync: this,
    value: widget.collapsed ? 1 : 0,
  );

  bool _initialized = false;
  bool _rtl = false;
  bool _reduceMotion = false;
  int? _pointer;
  int _hovered = -1;
  double _itemWidth = 0;

  bool _lensReady = false;
  bool _lensShown = false;
  Timer? _hideLens;

  final _lensCtl = GlassLensController();
  bool _nativeLens = false;
  VelocityTracker? _tracker;
  int _downSlot = -1;
  Timer? _settle;

  late Widget _barGlass = _makeBarGlass();

  Widget _makeBarGlass() => LiquidGlass(
    settings: widget.settings,
    interactive: false,
    shape: const LiquidGlassShape.capsule(),
    child: const SizedBox.expand(),
  );
  double _glassLeft = 0;

  int _slot(int index) => _rtl ? widget.count - 1 - index : index;

  @override
  void initState() {
    super.initState();
    LiquidGlassService.instance.ensureInitialized();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_initialized || rtl != _rtl) {
      _rtl = rtl;
      _initialized = true;
      _pos.value = _slot(widget.currentIndex).toDouble();
    }
  }

  @override
  void didUpdateWidget(GlassSelectionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _pos.value = _slot(widget.currentIndex).toDouble();
    } else if (oldWidget.currentIndex != widget.currentIndex &&
        _pointer == null) {
      _spring(_pos, _slot(widget.currentIndex).toDouble(), _moveSpring);
    }
    if (oldWidget.settings != widget.settings) _barGlass = _makeBarGlass();
    if (oldWidget.collapsed != widget.collapsed) {
      _spring(_collapse, widget.collapsed ? 1 : 0, _collapseSpring);
      if (widget.collapsed) {
        _pointer = null;
        _settle?.cancel();
        _spring(_lift, 0, _dropSpring);
        _spring(_pos, _slot(widget.currentIndex).toDouble(), _moveSpring);
        if (_nativeLens && _lensReady) {
          _lensCtl.move(_lensRect(_pos.value, 0.8, 0), alpha: 0);
        }
      }
    }
  }

  @override
  void dispose() {
    _hideLens?.cancel();
    _settle?.cancel();
    _pos.dispose();
    _lift.dispose();
    _collapse.dispose();
    super.dispose();
  }

  void _spring(AnimationController c, double target, SpringDescription s) {
    if (_reduceMotion) s = _calmSpring;
    animateGlassSpring(c, target, s);
  }

  Rect _lensRect(double slot, double scale, double stretch) {
    final h = widget.height;
    final overflow = widget.lensOverflow;
    return Rect.fromCenter(
      center: Offset(widget.padding + (slot + 0.5) * _itemWidth, h / 2),
      width: (_itemWidth + overflow) * (1 + stretch) * scale,
      height: (h + overflow) * (1 - stretch * 0.2) * scale,
    );
  }

  void _lensDown(PointerDownEvent event) {
    final slot = _trackSlot(event.localPosition);
    _lensCtl.move(
      _lensRect(_pos.value, 0.8, 0),
      alpha: 0,
      motion: LensMotion.instant,
    );
    _lensCtl.move(_lensRect(slot, 1, 0), duration: 0.35, damping: 0.8);
  }

  void _lensMove(PointerMoveEvent event) {
    final slot = _trackSlot(event.localPosition);
    final velocity = _itemWidth > 0 ? _velocityX / _itemWidth : 0.0;
    final stretch = _reduceMotion
        ? 0.0
        : math.min(velocity.abs() * 0.035, 0.45);
    _lensCtl.move(_lensRect(slot, 1, stretch), motion: LensMotion.follow);
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 60), () {
      if (_pointer != null) {
        _lensCtl.move(_lensRect(slot, 1, 0), duration: 0.3, damping: 0.8);
      }
    });
  }

  void _lensUp(double slot) {
    _settle?.cancel();
    _lensCtl.move(_lensRect(slot, 0.8, 0), alpha: 0, duration: 0.45);
    _scheduleLensHide();
  }

  void _showLens() {
    _hideLens?.cancel();
    if (_lensReady && _lensShown) return;
    setState(() {
      _lensReady = true;
      _lensShown = true;
    });
  }

  void _scheduleLensHide() {
    _hideLens?.cancel();
    _hideLens = Timer(const Duration(milliseconds: 700), () {
      if (mounted && _pointer == null && _lensShown) {
        setState(() => _lensShown = false);
      }
    });
  }

  void _select(int index) {
    if (index != widget.currentIndex) widget.onSelected(index);
  }

  double _rawSlot(Offset local) {
    if (_itemWidth <= 0) return _pos.value;
    final x = local.dx + _glassLeft;
    return (x - widget.padding) / _itemWidth - 0.5;
  }

  double _slotAt(Offset local) =>
      _rawSlot(local).clamp(0.0, widget.count - 1.0);

  double _trackSlot(Offset local) {
    final raw = _rawSlot(local);
    final last = widget.count - 1.0;
    final over = raw < 0 ? raw : (raw > last ? raw - last : 0.0);
    if (over == 0 || _itemWidth <= 0 || _reduceMotion) {
      return raw.clamp(0.0, last);
    }
    final limit = math.min(0.2, 12 / _itemWidth);
    final band = (1 - 1 / (over.abs() * 0.55 / limit + 1)) * limit;
    return raw < 0 ? -band : last + band;
  }

  double get _velocityX =>
      _tracker?.getVelocityEstimate()?.pixelsPerSecond.dx ?? 0;

  void _track(Offset local, SpringDescription spring) {
    final target = _trackSlot(local);
    _spring(_pos, target, spring);
    final nearest = target.round().clamp(0, widget.count - 1);
    if (nearest != _hovered) {
      if (_hovered != -1) HapticFeedback.selectionClick();
      _hovered = nearest;
    }
  }

  void _onDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    if (widget.collapsed) return;
    _hovered = -1;
    _downSlot = _slotAt(event.localPosition).round();
    _tracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.localPosition);
    _showLens();
    _spring(_lift, 1, _liftSpring);
    _track(event.localPosition, _moveSpring);
    if (_nativeLens) _lensDown(event);
  }

  void _onMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || widget.collapsed) return;
    _tracker?.addPosition(event.timeStamp, event.localPosition);
    _track(event.localPosition, _followSpring);
    if (_nativeLens) _lensMove(event);
  }

  void _onUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    if (widget.collapsed) {
      widget.onExpand?.call();
      return;
    }
    _tracker = null;
    final slot = _slotAt(event.localPosition).round();
    final index = _slot(slot);
    if (_nativeLens) _lensUp(slot.toDouble());
    _spring(_lift, 0, _dropSpring);
    _spring(_pos, slot.toDouble(), _moveSpring);
    if (index == widget.currentIndex && slot == _downSlot) {
      widget.onReselected?.call(index);
    }
    _select(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pointer == null && widget.currentIndex != index) {
        _spring(_pos, _slot(widget.currentIndex).toDouble(), _moveSpring);
      }
    });
  }

  void _onCancel() {
    if (_pointer == null) return;
    _pointer = null;
    _tracker = null;
    _settle?.cancel();
    if (_nativeLens) _lensUp(_slot(widget.currentIndex).toDouble());
    _spring(_lift, 0, _dropSpring);
    _spring(_pos, _slot(widget.currentIndex).toDouble(), _moveSpring);
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSettingsBuilder(
      settings: widget.settings,
      builder: (context, settings) {
        final glassVisible = LiquidGlassService.isGlassVisible(settings);
        _nativeLens =
            glassVisible && LiquidGlassService.usesNativeLens(settings);
        return SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              _itemWidth = (width - widget.padding * 2) / widget.count;
              return AnimatedBuilder(
                animation: Listenable.merge([_pos, _lift, _collapse]),
                builder: (context, _) =>
                    _buildBar(context, width, settings, glassVisible),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBar(
    BuildContext context,
    double fullWidth,
    LiquidGlassSettings settings,
    bool glassVisible,
  ) {
    final height = widget.height;
    final pad = widget.padding;
    final pos = _pos.value;
    final collapse = _collapse.value.clamp(0.0, 1.0);
    final lift = (_lift.value * (1 - collapse)).clamp(0.0, 1.2);

    final glassWidth = lerpDouble(fullWidth, height, collapse)!;
    _glassLeft = _rtl ? fullWidth - glassWidth : 0;
    final collapsedCenter = _glassLeft + glassWidth / 2;

    final stretch = _reduceMotion
        ? 0.0
        : math.min(_pos.velocity.abs() * 0.035, 0.45);

    double slotCenter(double slot) => pad + (slot + 0.5) * _itemWidth;
    final pillCenter = lerpDouble(slotCenter(pos), collapsedCenter, collapse)!;
    final pillWidth = _itemWidth * (1 + stretch);
    final pillHeight = (height - pad * 2) * (1 - stretch * 0.25);

    final overflow = widget.lensOverflow;
    final lensScale = 0.8 + 0.2 * lift.clamp(0.0, 1.0);
    final lensWidth = _itemWidth + overflow;
    final lensHeight = height + overflow;
    final lensScaleX = (1 + stretch) * lensScale;
    final lensScaleY = (1 - stretch * 0.2) * lensScale;

    final pillOpacity =
        (glassVisible ? (1 - lift).clamp(0.0, 1.0) : 1.0) * (1 - collapse);

    final items = <Widget>[
      for (var i = 0; i < widget.count; i++)
        _positionedItem(
          context,
          i,
          pos,
          lift,
          collapse,
          slotCenter,
          collapsedCenter,
          height,
        ),
    ];

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: _glassLeft,
            width: glassWidth,
            top: 0,
            bottom: 0,
            child: _barGlass,
          ),
          Positioned(
            left: pillCenter - pillWidth / 2,
            top: (height - pillHeight) / 2,
            width: pillWidth,
            height: pillHeight,
            child: IgnorePointer(
              child: Opacity(
                opacity: pillOpacity,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: widget.pillColor,
                    shadows: widget.pillShadow
                        ? const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
          ...items,
          if (_nativeLens && _lensReady)
            Positioned(
              key: const ValueKey('native-lens'),
              left: -_lensMargin,
              top: -_lensMargin,
              right: -_lensMargin,
              bottom: -_lensMargin,
              child: Offstage(
                offstage: !_lensShown,
                child: GlassLensHost(
                  controller: _lensCtl,
                  settings: settings,
                  margin: _lensMargin,
                ),
              ),
            ),
          if (glassVisible && !_nativeLens && _lensReady && lift > 0.01)
            Positioned(
              key: const ValueKey('flutter-lens'),
              left: pillCenter - lensWidth / 2,
              top: (height - lensHeight) / 2,
              width: lensWidth,
              height: lensHeight,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(lensScaleX, lensScaleY, 1),
                  child: _lensFor(settings, lift.clamp(0.0, 1.0)),
                ),
              ),
            ),
          Positioned(
            key: const ValueKey('touch'),
            left: _glassLeft,
            width: glassWidth,
            top: 0,
            bottom: 0,
            child: GlassTrackDetector(
              onDown: _onDown,
              onMove: _onMove,
              onUp: _onUp,
              onCancel: _onCancel,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  double get _lensMargin => widget.lensOverflow + 24;

  Widget _lensFor(LiquidGlassSettings settings, double visibility) =>
      FlutterGlass(
        settings: settings.copyWith(
          style: LiquidGlassStyle.clear,
          clearTintColor: true,
          opacity: settings.opacity * visibility,
        ),
        shape: const LiquidGlassShape.capsule(),
      );

  Widget _positionedItem(
    BuildContext context,
    int index,
    double pos,
    double lift,
    double collapse,
    double Function(double) slotCenter,
    double collapsedCenter,
    double height,
  ) {
    final slot = _slot(index).toDouble();
    final selected = index == widget.currentIndex;
    final selection = (1 - (pos - slot).abs()).clamp(0.0, 1.0);
    final center = selected
        ? lerpDouble(slotCenter(slot), collapsedCenter, collapse)!
        : slotCenter(slot);
    final opacity = selected ? 1.0 : (1 - collapse * 2).clamp(0.0, 1.0);
    final labels = widget.semanticLabels;
    final label = labels != null && index < labels.length
        ? labels[index]
        : null;
    final hidden = !selected && collapse > 0.5;

    return Positioned(
      left: center - _itemWidth / 2,
      width: _itemWidth,
      top: 0,
      bottom: 0,
      child: ExcludeSemantics(
        excluding: hidden,
        child: Semantics(
          container: true,
          button: true,
          selected: selected,
          inMutuallyExclusiveGroup: true,
          label: label,
          onTap: () {
            if (widget.collapsed) {
              widget.onExpand?.call();
            } else if (selected) {
              widget.onReselected?.call(index);
            } else {
              _select(index);
            }
          },
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: widget.itemBuilder(
                context,
                index,
                selected && collapse > 0.5 ? 1.0 : selection,
                lift,
                collapse,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
