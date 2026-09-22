import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show VelocityTracker;
import 'package:flutter/services.dart';

import 'glass_lens.dart';
import 'glass_spring.dart';
import 'glass_track.dart';
import 'liquid_glass.dart';
import 'liquid_glass_service.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_theme.dart';

const _thumbShadow = [
  BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x0F000000), blurRadius: 1, offset: Offset(0, 1)),
];

Color _inactiveTrack(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0x5C787880)
    : const Color(0x29787880);

class _LensThumb extends StatelessWidget {
  const _LensThumb({
    required this.center,
    required this.size,
    required this.lift,
    required this.stretch,
    required this.glassVisible,
    required this.lensReady,
    required this.lensShown,
    required this.settings,
    required this.nativeLens,
    required this.lensController,
  });

  final Offset center;
  final Size size;
  final double lift;
  final double stretch;
  final bool glassVisible;

  final bool lensReady;
  final bool lensShown;
  final LiquidGlassSettings settings;

  final bool nativeLens;
  final GlassLensController lensController;

  static const _margin = 24.0;

  @override
  Widget build(BuildContext context) {
    final l = lift.clamp(0.0, 1.0);
    final restW = size.width * (1 + stretch);
    final lensW = size.width * (1.1 + 0.4 * l) * (1 + stretch);
    final lensH = size.height * (1.1 + 0.5 * l);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: center.dx - restW / 2,
          top: center.dy - size.height / 2,
          width: restW,
          height: size.height,
          child: Opacity(
            opacity: glassVisible && lensReady ? 1 - l : 1,
            child: const DecoratedBox(
              decoration: ShapeDecoration(
                shape: StadiumBorder(),
                color: Colors.white,
                shadows: _thumbShadow,
              ),
            ),
          ),
        ),
        if (nativeLens && lensReady)
          Positioned(
            left: -_margin,
            top: -_margin,
            right: -_margin,
            bottom: -_margin,
            child: Offstage(
              offstage: !lensShown,
              child: GlassLensHost(
                controller: lensController,
                settings: settings,
                margin: _margin,
              ),
            ),
          ),
        if (glassVisible && !nativeLens && lensReady && l > 0.01)
          Positioned(
            left: center.dx - lensW / 2,
            top: center.dy - lensH / 2,
            width: lensW,
            height: lensH,
            child: FlutterGlass(
              settings: settings.copyWith(
                style: LiquidGlassStyle.clear,
                clearTintColor: true,
                opacity: settings.opacity * l,
              ),
              shape: const LiquidGlassShape.capsule(),
            ),
          ),
      ],
    );
  }
}

mixin _SpringMixin<T extends StatefulWidget> on TickerProviderStateMixin<T> {
  static const _calm = SpringDescription(mass: 1, stiffness: 300, damping: 35);
  bool reduceMotion = false;

  bool lensReady = false;

  bool lensShown = false;
  Timer? _hideLens;

  final lensController = GlassLensController();

  bool nativeLens = false;

  Rect _lensRect(
    Offset center,
    Size thumb, {
    required bool lifted,
    double stretch = 0,
  }) => Rect.fromCenter(
    center: center,
    width: thumb.width * (lifted ? 1.5 : 1.1) * (1 + stretch),
    height: thumb.height * (lifted ? 1.6 : 1.1) * (1 - stretch * 0.2),
  );

  void lensPress(Offset from, Offset to, Size thumb) {
    if (!nativeLens) return;
    lensController.move(
      _lensRect(from, thumb, lifted: false),
      alpha: 0,
      motion: LensMotion.instant,
    );
    lensController.move(
      _lensRect(to, thumb, lifted: true),
      duration: 0.35,
      damping: 0.8,
    );
  }

  void lensFollow(Offset center, Size thumb, {double stretch = 0}) {
    if (!nativeLens) return;
    lensController.move(
      _lensRect(center, thumb, lifted: true, stretch: stretch),
      motion: LensMotion.follow,
    );
  }

  void lensRelease(Offset center, Size thumb) {
    if (!nativeLens) return;
    lensController.move(_lensRect(center, thumb, lifted: false), alpha: 0);
    _hideLens?.cancel();
    _hideLens = Timer(const Duration(milliseconds: 700), () {
      if (mounted && lensShown) setState(() => lensShown = false);
    });
  }

  void prepareLens() {
    _hideLens?.cancel();
    if (lensReady && lensShown) return;
    setState(() {
      lensReady = true;
      lensShown = true;
    });
  }

  @override
  void dispose() {
    _hideLens?.cancel();
    super.dispose();
  }

  void spring(AnimationController c, double target, SpringDescription s) {
    if (reduceMotion) s = _calm;
    animateGlassSpring(c, target, s);
  }
}

class LiquidGlassSwitch extends StatefulWidget {
  const LiquidGlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.semanticLabel,
    this.settings,
  });

  final bool value;

  final ValueChanged<bool>? onChanged;

  final Color? activeColor;
  final String? semanticLabel;
  final LiquidGlassSettings? settings;

  @override
  State<LiquidGlassSwitch> createState() => _LiquidGlassSwitchState();
}

class _LiquidGlassSwitchState extends State<LiquidGlassSwitch>
    with TickerProviderStateMixin, _SpringMixin {
  static const _trackSize = Size(64, 28);
  static const _thumbSize = Size(38, 24);
  static const _move = SpringDescription(mass: 1, stiffness: 380, damping: 24);
  static const _follow = SpringDescription(
    mass: 1,
    stiffness: 4000,
    damping: 120,
  );
  static const _liftSpring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 30,
  );

  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );
  late final AnimationController _lift = AnimationController.unbounded(
    vsync: this,
  );

  int? _pointer;
  double _downX = 0;
  double _startPos = 0;
  double _dragTarget = 0;
  bool _moved = false;
  bool _rtl = false;

  static const _travel = 64.0 - 38 - 4;

  Offset _thumbCenter(double pos) {
    final visual = _rtl ? 1 - pos : pos;
    return Offset(
      2 + _thumbSize.width / 2 + visual * _travel,
      _trackSize.height / 2,
    );
  }

  @override
  void initState() {
    super.initState();
    LiquidGlassService.instance.ensureInitialized();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rtl = Directionality.of(context) == TextDirection.rtl;
    reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void didUpdateWidget(LiquidGlassSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _pointer == null) {
      spring(_pos, widget.value ? 1 : 0, _move);
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    _lift.dispose();
    super.dispose();
  }

  void _commit(bool value) {
    spring(_pos, value ? 1 : 0, _move);
    if (value != widget.value) {
      HapticFeedback.lightImpact();
      widget.onChanged?.call(value);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pointer == null && widget.value != value) {
        spring(_pos, widget.value ? 1 : 0, _move);
      }
    });
  }

  void _onDown(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    _downX = e.localPosition.dx;
    _startPos = _pos.value;
    _dragTarget = _startPos;
    _moved = false;
    prepareLens();
    spring(_lift, 1, _liftSpring);
    final here = _thumbCenter(_pos.value.clamp(0.0, 1.0));
    lensPress(here, here, _thumbSize);
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    var dx = e.localPosition.dx - _downX;
    if (dx.abs() > 3) _moved = true;
    if (_rtl) dx = -dx;
    final raw = _startPos + dx / _travel;
    _dragTarget = raw.clamp(0.0, 1.0);
    final visual = reduceMotion ? _dragTarget : _rubber(raw);
    spring(_pos, visual, _follow);
    lensFollow(_thumbCenter(visual), _thumbSize);
  }

  double _rubber(double raw) {
    if (raw >= 0 && raw <= 1) return raw;
    final over = raw < 0 ? -raw : raw - 1;
    const limit = 0.18;
    final band = (1 - 1 / (over * 0.55 / limit + 1)) * limit;
    return raw < 0 ? -band : 1 + band;
  }

  void _onCancel() {
    if (_pointer == null) return;
    _pointer = null;
    spring(_lift, 0, _move);
    spring(_pos, widget.value ? 1 : 0, _move);
    lensRelease(_thumbCenter(widget.value ? 1 : 0), _thumbSize);
  }

  void _onUp(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    spring(_lift, 0, _move);
    final value = _moved ? _dragTarget > 0.5 : !widget.value;
    lensRelease(_thumbCenter(value ? 1 : 0), _thumbSize);
    _commit(value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeColor ?? const Color(0xFF34C759);
    final inactive = _inactiveTrack(context);
    final enabled = widget.onChanged != null;

    return LiquidGlassSettingsBuilder(
      settings: widget.settings,
      builder: (context, settings) {
        final glassVisible = LiquidGlassService.isGlassVisible(settings);
        nativeLens =
            glassVisible && LiquidGlassService.usesNativeLens(settings);
        return Semantics(
          toggled: widget.value,
          enabled: enabled,
          label: widget.semanticLabel,
          onTap: enabled ? () => _commit(!widget.value) : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: GlassTrackDetector(
              enabled: enabled,
              onDown: _onDown,
              onMove: _onMove,
              onUp: _onUp,
              onCancel: _onCancel,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox.fromSize(
                  size: _trackSize,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pos, _lift]),
                    builder: (context, _) {
                      final p = _pos.value.clamp(0.0, 1.0);
                      final raw = _pos.value.clamp(-0.2, 1.2);
                      final visual = _rtl ? 1 - raw : raw;
                      final stretch = reduceMotion
                          ? 0.0
                          : (_pos.velocity.abs() * 0.02).clamp(0.0, 0.3);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                shape: const StadiumBorder(),
                                color: Color.lerp(inactive, active, p),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: _LensThumb(
                              center: Offset(
                                2 + _thumbSize.width / 2 + visual * _travel,
                                _trackSize.height / 2,
                              ),
                              size: _thumbSize,
                              lift: _lift.value,
                              stretch: stretch,
                              glassVisible: glassVisible,
                              lensReady: lensReady,
                              lensShown: lensShown,
                              settings: settings,
                              nativeLens: nativeLens,
                              lensController: lensController,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LiquidGlassSlider extends StatefulWidget {
  const LiquidGlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.activeColor,
    this.semanticFormatter,
    this.settings,
  }) : assert(min < max),
       assert(value >= min && value <= max);

  final double value;

  final ValueChanged<double>? onChanged;
  final double min;
  final double max;

  final int? divisions;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  final Color? activeColor;

  final String Function(double value)? semanticFormatter;
  final LiquidGlassSettings? settings;

  @override
  State<LiquidGlassSlider> createState() => _LiquidGlassSliderState();
}

class _LiquidGlassSliderState extends State<LiquidGlassSlider>
    with TickerProviderStateMixin, _SpringMixin {
  static const _thumbSize = Size(38, 24);
  static const _liftSpring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 30,
  );
  static const _drop = SpringDescription(mass: 1, stiffness: 320, damping: 24);

  late final AnimationController _lift = AnimationController.unbounded(
    vsync: this,
  );
  int? _pointer;
  double _width = 0;
  bool _rtl = false;
  double _lastValue = 0;
  double _pending = 0;
  bool _accepted = false;
  double _stretch = 0;
  VelocityTracker? _tracker;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    LiquidGlassService.instance.ensureInitialized();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rtl = Directionality.of(context) == TextDirection.rtl;
    reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void dispose() {
    _settle?.cancel();
    _lift.dispose();
    super.dispose();
  }

  double get _fraction =>
      (widget.value - widget.min) / (widget.max - widget.min);

  Offset _thumbCenter(double value) {
    final t = ((value - widget.min) / (widget.max - widget.min)).clamp(
      0.0,
      1.0,
    );
    final travel = _width - _thumbSize.width;
    return Offset(_thumbSize.width / 2 + (_rtl ? 1 - t : t) * travel, 22);
  }

  double _valueAt(double dx) {
    final travel = _width - _thumbSize.width;
    if (travel <= 0) return widget.value;
    var t = ((dx - _thumbSize.width / 2) / travel).clamp(0.0, 1.0);
    if (_rtl) t = 1 - t;
    final divisions = widget.divisions;
    if (divisions != null && divisions > 0) {
      t = (t * divisions).round() / divisions;
    }
    return widget.min + t * (widget.max - widget.min);
  }

  void _emit(double value) {
    if (value == _lastValue) return;
    if (widget.divisions != null) HapticFeedback.selectionClick();
    _lastValue = value;
    widget.onChanged?.call(value);
  }

  void _onDown(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    _accepted = false;
    _lastValue = widget.value;
    _pending = _valueAt(e.localPosition.dx);
    _tracker = VelocityTracker.withKind(e.kind)
      ..addPosition(e.timeStamp, e.localPosition);
    prepareLens();
    spring(_lift, 1, _liftSpring);
    lensPress(_thumbCenter(widget.value), _thumbCenter(_pending), _thumbSize);
  }

  void _onAccept() {
    if (_pointer == null || _accepted) return;
    _accepted = true;
    widget.onChangeStart?.call(widget.value);
    _emit(_pending);
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    _pending = _valueAt(e.localPosition.dx);
    _tracker?.addPosition(e.timeStamp, e.localPosition);
    final velocity =
        _tracker?.getVelocityEstimate()?.pixelsPerSecond.dx.abs() ?? 0;
    final stretch = reduceMotion
        ? 0.0
        : (velocity / 1000 * 0.3).clamp(0.0, 0.3);
    _setStretch(stretch);
    lensFollow(_thumbCenter(_pending), _thumbSize, stretch: stretch);
    _settle?.cancel();
    if (stretch > 0) {
      _settle = Timer(const Duration(milliseconds: 60), () {
        if (_pointer == null) return;
        _setStretch(0);
        lensFollow(_thumbCenter(_pending), _thumbSize);
      });
    }
    if (_accepted) _emit(_pending);
  }

  void _setStretch(double value) {
    if (value == _stretch || !mounted) return;
    setState(() => _stretch = value);
  }

  void _end() {
    _pointer = null;
    _tracker = null;
    _settle?.cancel();
    _setStretch(0);
    spring(_lift, 0, _drop);
  }

  void _onUp(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _end();
    lensRelease(_thumbCenter(_lastValue), _thumbSize);
    if (_accepted) widget.onChangeEnd?.call(_lastValue);
    _accepted = false;
  }

  void _onCancel() {
    if (_pointer == null) return;
    _end();
    lensRelease(_thumbCenter(widget.value), _thumbSize);
    if (_accepted) widget.onChangeEnd?.call(_lastValue);
    _accepted = false;
  }

  double _stepped(int direction) {
    final step = (widget.max - widget.min) / (widget.divisions ?? 10);
    return (widget.value + step * direction).clamp(widget.min, widget.max);
  }

  void _step(int direction) {
    final value = _stepped(direction);
    widget.onChangeStart?.call(widget.value);
    widget.onChanged?.call(value);
    widget.onChangeEnd?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeColor ?? Theme.of(context).colorScheme.primary;
    final inactive = _inactiveTrack(context);
    final enabled = widget.onChanged != null;
    String format(double v) =>
        widget.semanticFormatter?.call(v) ??
        '${((v - widget.min) / (widget.max - widget.min) * 100).round()}%';

    return LiquidGlassSettingsBuilder(
      settings: widget.settings,
      builder: (context, settings) {
        final glassVisible = LiquidGlassService.isGlassVisible(settings);
        nativeLens =
            glassVisible && LiquidGlassService.usesNativeLens(settings);
        return Semantics(
          slider: true,
          enabled: enabled,
          value: format(widget.value),
          increasedValue: format(_stepped(1)),
          decreasedValue: format(_stepped(-1)),
          onIncrease: enabled ? () => _step(1) : null,
          onDecrease: enabled ? () => _step(-1) : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: GlassTrackDetector(
              enabled: enabled,
              onDown: _onDown,
              onAccept: _onAccept,
              onMove: _onMove,
              onUp: _onUp,
              onCancel: _onCancel,
              child: SizedBox(
                height: 44,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _width = constraints.maxWidth;
                    return AnimatedBuilder(
                      animation: _lift,
                      builder: (context, _) {
                        final t = _fraction.clamp(0.0, 1.0);
                        final travel = _width - _thumbSize.width;
                        final x =
                            _thumbSize.width / 2 + (_rtl ? 1 - t : t) * travel;
                        final fillLeft = _rtl ? x : 0.0;
                        final fillWidth = _rtl ? _width - x : x;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 19,
                              height: 6,
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                  shape: const StadiumBorder(),
                                  color: inactive,
                                ),
                              ),
                            ),
                            Positioned(
                              left: fillLeft,
                              width: fillWidth,
                              top: 19,
                              height: 6,
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                  shape: const StadiumBorder(),
                                  color: active,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: _LensThumb(
                                center: Offset(x, 22),
                                size: _thumbSize,
                                lift: _lift.value,
                                stretch: _stretch,
                                glassVisible: glassVisible,
                                lensReady: lensReady,
                                lensShown: lensShown,
                                settings: settings,
                                nativeLens: nativeLens,
                                lensController: lensController,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
