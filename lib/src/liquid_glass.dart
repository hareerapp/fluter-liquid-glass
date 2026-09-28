import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' show CupertinoTheme;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'glass_spring.dart';
import 'liquid_glass_group.dart';
import 'liquid_glass_service.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_theme.dart';
import 'native_glass_view.dart';

class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.shape,
    this.settings,
    this.enabled,
    this.style,
    this.opacity,
    this.tintColor,
    this.tintOpacity,
    this.interactive,
    this.interactionStrength,
    this.brightness,
    this.fallback,
    this.fallbackBlurSigma,
    this.renderer,
    this.joinGroup = true,
    this.rimColor,
    this.rimWidth,
  });

  final Widget child;

  final LiquidGlassShape? shape;

  final LiquidGlassSettings? settings;

  final bool? enabled;
  final LiquidGlassStyle? style;
  final double? opacity;
  final Color? tintColor;
  final double? tintOpacity;
  final bool? interactive;
  final double? interactionStrength;
  final LiquidGlassBrightness? brightness;
  final LiquidGlassFallback? fallback;
  final double? fallbackBlurSigma;
  final LiquidGlassRenderer? renderer;

  final bool joinGroup;

  final Color? rimColor;

  final double? rimWidth;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass>
    with TickerProviderStateMixin {
  static const _calmSpring = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 35,
  );

  static const _pressSpring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 26,
  );
  static const _releaseSpring = SpringDescription(
    mass: 1,
    stiffness: 240,
    damping: 13,
  );
  static const _followSpring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 34,
  );
  static const _fadeSpring = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 27,
  );

  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _hover = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _glow = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _dx = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _dy = AnimationController.unbounded(
    vsync: this,
  );
  final ValueNotifier<Offset?> _pointer = ValueNotifier(null);
  late final Listenable _motion = Listenable.merge([_press, _hover, _dx, _dy]);

  int? _activePointer;
  Offset _downPosition = Offset.zero;
  Size _size = Size.zero;
  double _strength = 1;
  bool _reduceMotion = false;
  ScrollPosition? _scroll;
  double? _scrollAtDown;

  @override
  void initState() {
    super.initState();
    LiquidGlassService.instance.ensureInitialized();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context)?.position;
    if (scroll != _scroll) {
      _scroll?.removeListener(_onScroll);
      _scroll = scroll?..addListener(_onScroll);
    }
  }

  void _onScroll() {
    final start = _scrollAtDown;
    final scroll = _scroll;
    if (start == null || scroll == null || _activePointer == null) return;
    if (!scroll.hasPixels || (scroll.pixels - start).abs() > 0.5) _release();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_onScroll);
    for (final c in [_press, _hover, _glow, _dx, _dy]) {
      c.dispose();
    }
    _pointer.dispose();
    super.dispose();
  }

  LiquidGlassSettings _resolve(LiquidGlassSettings base) => base.copyWith(
    enabled: widget.enabled,
    style: widget.style,
    opacity: widget.opacity,
    tintColor: widget.tintColor,
    tintOpacity: widget.tintOpacity,
    interactive: widget.interactive,
    interactionStrength: widget.interactionStrength,
    brightness: widget.brightness,
    fallback: widget.fallback,
    fallbackBlurSigma: widget.fallbackBlurSigma,
    renderer: widget.renderer,
  );

  void _spring(AnimationController c, double target, SpringDescription spring) {
    if (_reduceMotion) spring = _calmSpring;
    animateGlassSpring(c, target, spring);
  }

  double _rubberBand(double delta, double dimension) {
    final limit = (dimension * 0.25).clamp(6.0, 28.0) * _strength;
    if (limit == 0) return 0;
    return (1 - 1 / (delta.abs() * 0.55 / limit + 1)) * limit * delta.sign;
  }

  void _measure() {
    final size = context.size;
    if (size != null) _size = size;
  }

  void _onDown(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    final scroll = _scroll;
    _scrollAtDown = scroll != null && scroll.hasPixels ? scroll.pixels : null;
    _measure();
    _downPosition = event.localPosition;
    _pointer.value = event.localPosition;
    _spring(_press, 1, _pressSpring);
    _spring(_glow, 1, _pressSpring);
  }

  void _onMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    final delta = event.localPosition - _downPosition;
    _pointer.value = event.localPosition;
    if (_reduceMotion) return;
    _spring(_dx, _rubberBand(delta.dx, _size.width), _followSpring);
    _spring(_dy, _rubberBand(delta.dy, _size.height), _followSpring);
  }

  void _onUp(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    _release();
  }

  void _release() {
    _activePointer = null;
    _scrollAtDown = null;
    _spring(_press, 0, _releaseSpring);
    _spring(_dx, 0, _releaseSpring);
    _spring(_dy, 0, _releaseSpring);
    _spring(_glow, _hover.value > 0.5 ? 0.35 : 0, _fadeSpring);
  }

  void _onHover(PointerHoverEvent event) {
    if (event.kind == PointerDeviceKind.touch) return;
    _pointer.value = event.localPosition;
  }

  void _onEnter(PointerEnterEvent event) {
    if (event.kind == PointerDeviceKind.touch) return;
    _measure();
    _pointer.value = event.localPosition;
    _spring(_hover, 1, _fadeSpring);
    if (_activePointer == null) _spring(_glow, 0.35, _fadeSpring);
  }

  void _onExit(PointerExitEvent event) {
    if (event.kind == PointerDeviceKind.touch) return;
    _spring(_hover, 0, _fadeSpring);
    if (_activePointer == null) _spring(_glow, 0, _fadeSpring);
  }

  Brightness? _nativeBrightness(LiquidGlassBrightness mode) => switch (mode) {
    LiquidGlassBrightness.auto => CupertinoTheme.brightnessOf(context),
    LiquidGlassBrightness.system => null,
    LiquidGlassBrightness.light => Brightness.light,
    LiquidGlassBrightness.dark => Brightness.dark,
  };

  Brightness _flutterBrightness(LiquidGlassBrightness mode) =>
      _nativeBrightness(mode) ??
      MediaQuery.maybePlatformBrightnessOf(context) ??
      Brightness.light;

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final group = widget.joinGroup ? LiquidGlassGroup.maybeOf(context) : null;
    return LiquidGlassSettingsBuilder(
      settings: widget.settings,
      builder: (context, base) => _build(_resolve(base), group),
    );
  }

  Widget _build(LiquidGlassSettings settings, GlassGroupHandle? group) {
    final shape =
        widget.shape ?? LiquidGlassShape.detect(widget.child) ?? settings.shape;
    if (shape.isPath) group = null;

    final native = LiquidGlassService.usesNativeGlass(
      context,
      settings,
      grouped: group != null,
    );
    final Widget? glass;
    if (!settings.enabled) {
      glass = null;
    } else if (native) {
      final brightness = _nativeBrightness(settings.brightness);
      final params = <String, Object?>{
        ...shape.toMap(),
        'style': settings.style.name,
        'opacity': settings.opacity,
        'tint': settings.tintColor?.toARGB32(),
        'tintOpacity': settings.tintOpacity,
        'brightness': brightness?.name ?? 'system',
      };
      glass = group != null
          ? GlassGroupSlot(group: group, shape: shape, params: params)
          : NativeGlassView(params: params);
    } else if (LiquidGlassService.isNativePlatform ||
        settings.fallback == LiquidGlassFallback.frosted) {
      glass = FlutterGlass(
        shape: shape,
        settings: settings,
        brightness: _flutterBrightness(settings.brightness),
        rimColor: widget.rimColor,
        rimWidth: widget.rimWidth ?? 1,
        solid:
            (MediaQuery.maybeHighContrastOf(context) ?? false) ||
            LiquidGlassService.instance.capabilities.reduceTransparency,
      );
    } else {
      glass = null;
    }

    Widget result;
    if (glass == null) {
      result = widget.child;
    } else {
      final interactive =
          settings.interactive && settings.interactionStrength > 0;
      _strength = settings.interactionStrength;
      final brightness = _flutterBrightness(settings.brightness);

      result = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: glass),
          if (interactive)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GlowPainter(
                    glow: _glow,
                    pointer: _pointer,
                    shape: shape,
                    strength: math.min(_strength, 1.5),
                    dark: brightness == Brightness.dark,
                  ),
                ),
              ),
            ),
          widget.child,
        ],
      );

      if (interactive) {
        result = AnimatedBuilder(
          animation: _motion,
          child: result,
          builder: (context, child) =>
              Transform(transform: _transform(), child: child),
        );
        result = MouseRegion(
          onEnter: _onEnter,
          onExit: _onExit,
          onHover: _onHover,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onDown,
            onPointerMove: _onMove,
            onPointerUp: _onUp,
            onPointerCancel: _onUp,
            child: result,
          ),
        );
      }
    }

    return result;
  }

  Matrix4 _transform() {
    final w = _size.width, h = _size.height;
    if (w <= 0 || h <= 0) return Matrix4.identity();

    var growth = (16 / math.max(w, h)).clamp(0.03, 0.2) * _strength;
    if (_reduceMotion) growth *= 0.25;
    final scale = 1 + _press.value * growth + _hover.value * 0.02 * _strength;

    final tx = _dx.value, ty = _dy.value;
    final stretchX = tx.abs() / w * 0.5;
    final stretchY = ty.abs() / h * 0.5;
    final sx = scale * (1 + stretchX - stretchY * 0.5);
    final sy = scale * (1 + stretchY - stretchX * 0.5);

    return Matrix4.identity()
      ..translateByDouble(w / 2 + tx, h / 2 + ty, 0, 1)
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-w / 2, -h / 2, 0, 1);
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({
    required this.glow,
    required this.pointer,
    required this.shape,
    required this.strength,
    required this.dark,
  }) : super(repaint: Listenable.merge([glow, pointer]));

  final Animation<double> glow;
  final ValueListenable<Offset?> pointer;
  final LiquidGlassShape shape;
  final double strength;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final amount = (glow.value * strength).clamp(0.0, 1.5);
    final center = pointer.value;
    if (amount <= 0.001 || center == null) return;

    final rect = Offset.zero & size;
    canvas.save();
    if (shape.isPath) {
      canvas.clipPath(shape.toPath(rect));
    } else {
      canvas.clipRRect(shape.toRRect(rect));
    }

    final white = const Color(0xFFFFFFFF);
    canvas.drawRect(
      rect,
      Paint()..color = white.withValues(alpha: (dark ? 0.05 : 0.08) * amount),
    );
    final radius = math.max(size.width, size.height) * 0.75;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            white.withValues(alpha: (dark ? 0.22 : 0.32) * amount),
            white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.glow != glow ||
      old.pointer != pointer ||
      old.shape != shape ||
      old.strength != strength ||
      old.dark != dark;
}

class FlutterGlass extends StatelessWidget {
  const FlutterGlass({
    super.key,
    required this.shape,
    required this.settings,
    this.brightness,
    this.solid = false,
    this.rimColor,
    this.rimWidth = 1,
  });

  final LiquidGlassShape shape;
  final LiquidGlassSettings settings;
  final Brightness? brightness;
  final Color? rimColor;
  final double rimWidth;

  final bool solid;

  static ImageFilter _filter(double sigma, double saturation) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final s = saturation, t = 1 - saturation;
    final color = ColorFilter.matrix(<double>[
      r * t + s, g * t, b * t, 0, 0, //
      r * t, g * t + s, b * t, 0, 0, //
      r * t, g * t, b * t + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
    if (sigma <= 0) return color;
    return ImageFilter.compose(
      outer: color,
      inner: ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.mirror,
      ),
    );
  }

  Brightness _brightnessOf(BuildContext context) =>
      brightness ??
      switch (settings.brightness) {
        LiquidGlassBrightness.auto => CupertinoTheme.brightnessOf(context),
        LiquidGlassBrightness.light => Brightness.light,
        LiquidGlassBrightness.dark => Brightness.dark,
        LiquidGlassBrightness.system =>
          MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light,
      };

  @override
  Widget build(BuildContext context) {
    final dark = _brightnessOf(context) == Brightness.dark;
    final clear = settings.style == LiquidGlassStyle.clear;
    final opacity = settings.opacity;
    final sigma = settings.fallbackBlurSigma * (clear ? 0.35 : 1) * opacity;

    var fill = (dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF))
        .withValues(
          alpha:
              (solid ? 0.88 : (clear ? 0.06 : (dark ? 0.32 : 0.28))) * opacity,
        );
    final tint = settings.tintColor;
    if (tint != null) {
      fill = Color.alphaBlend(
        tint.withValues(alpha: settings.tintOpacity * opacity),
        fill,
      );
    }

    final paint = CustomPaint(
      painter: _GlassPainter(
        shape: shape,
        fill: fill,
        sheen: (dark ? 0.07 : 0.22) * opacity,
        rim: (solid ? 0.9 : (dark ? 0.32 : 0.75)) * opacity,
        dark: dark,
        rimColor: rimColor,
        rimWidth: rimWidth,
      ),
    );
    if (sigma <= 0 || opacity <= 0) return paint;
    final blur = BackdropFilter(
      filter: _filter(sigma, 1 + 0.6 * opacity),
      child: paint,
    );
    if (shape.isPath) {
      return ClipPath(clipper: _PathClipper(shape), child: blur);
    }
    return ClipRRect(clipper: _ShapeClipper(shape), child: blur);
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({
    required this.shape,
    required this.fill,
    required this.sheen,
    required this.rim,
    required this.dark,
    this.rimColor,
    this.rimWidth = 1,
  });

  final LiquidGlassShape shape;
  final Color fill;
  final double sheen;
  final double rim;
  final bool dark;
  final Color? rimColor;
  final double rimWidth;

  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (shape.isPath) {
      _paintPath(canvas, rect);
      return;
    }
    final rrect = shape.toRRect(rect);
    canvas.drawRRect(rrect, Paint()..color = fill);

    if (sheen > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _white.withValues(alpha: sheen),
              _white.withValues(alpha: 0),
            ],
            stops: const [0, 0.55],
          ).createShader(rect),
      );
    }

    if (rim > 0) {
      canvas.drawRRect(
        rrect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _white.withValues(alpha: rim),
              _white.withValues(alpha: rim * (dark ? 0.2 : 0.25)),
              _white.withValues(alpha: rim * 0.55),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(rect),
      );
    }
  }

  void _paintPath(Canvas canvas, Rect rect) {
    final path = shape.toPath(rect);
    final bounds = path.getBounds();
    if (bounds.isEmpty) return;
    canvas.drawPath(path, Paint()..color = fill);

    if (sheen > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _white.withValues(alpha: sheen),
              _white.withValues(alpha: 0),
            ],
            stops: const [0, 0.55],
          ).createShader(bounds),
      );
    }

    if (rim > 0 && rimWidth > 0) {
      final base = rimColor ?? _white;
      final alpha = rimColor == null
          ? rim
          : base.a * (rim / 0.75).clamp(0.0, 1.0);
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rimWidth * 2
          ..strokeJoin = StrokeJoin.round
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              base.withValues(alpha: alpha),
              base.withValues(alpha: alpha * (dark ? 0.2 : 0.25)),
              base.withValues(alpha: alpha * 0.55),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(bounds),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.shape != shape ||
      old.fill != fill ||
      old.sheen != sheen ||
      old.rim != rim ||
      old.dark != dark ||
      old.rimColor != rimColor ||
      old.rimWidth != rimWidth;
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.shape);

  final LiquidGlassShape shape;

  @override
  Path getClip(Size size) => shape.toPath(Offset.zero & size);

  @override
  bool shouldReclip(_PathClipper old) => old.shape != shape;
}

class _ShapeClipper extends CustomClipper<RRect> {
  const _ShapeClipper(this.shape);

  final LiquidGlassShape shape;

  @override
  RRect getClip(Size size) => shape.toRRect(Offset.zero & size);

  @override
  bool shouldReclip(_ShapeClipper old) => old.shape != shape;
}

extension LiquidGlassExtension on Widget {
  Widget liquidGlass({
    Key? key,
    LiquidGlassShape? shape,
    LiquidGlassSettings? settings,
    bool? enabled,
    LiquidGlassStyle? style,
    double? opacity,
    Color? tintColor,
    double? tintOpacity,
    bool? interactive,
    double? interactionStrength,
    LiquidGlassBrightness? brightness,
    LiquidGlassFallback? fallback,
    double? fallbackBlurSigma,
    LiquidGlassRenderer? renderer,
    bool joinGroup = true,
    Color? rimColor,
    double? rimWidth,
  }) => LiquidGlass(
    key: key,
    shape: shape,
    settings: settings,
    enabled: enabled,
    style: style,
    opacity: opacity,
    tintColor: tintColor,
    tintOpacity: tintOpacity,
    interactive: interactive,
    interactionStrength: interactionStrength,
    brightness: brightness,
    fallback: fallback,
    fallbackBlurSigma: fallbackBlurSigma,
    renderer: renderer,
    joinGroup: joinGroup,
    rimColor: rimColor,
    rimWidth: rimWidth,
    child: this,
  );
}
