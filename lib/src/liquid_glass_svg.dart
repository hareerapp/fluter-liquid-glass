import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'liquid_glass.dart';
import 'liquid_glass_service.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shape.dart';
import 'liquid_glass_theme.dart';
import 'svg/stroke_outliner.dart';
import 'svg/svg_document_parser.dart';
import 'svg/svg_fit.dart';

/// Liquid Glass in the exact shape of an SVG, such as a logo.
///
/// Native glass on iOS and macOS 26. Elsewhere the plain SVG is drawn, or
/// Flutter glass with [LiquidGlassFallback.frosted].
class LiquidGlassSvg extends StatelessWidget {
  /// Glass from an SVG document or raw path data in [svg].
  const LiquidGlassSvg({
    super.key,
    required String this.svg,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.tintColor,
    this.tintOpacity,
    this.rimColor,
    this.rimWidth = 1.0,
    this.strokeToFill = true,
    this.settings,
    this.interactive = false,
    this.onTap,
    this.semanticLabel,
    this.child,
  }) : assetName = null,
       bundle = null;

  /// Glass from an SVG asset. The file is loaded once and cached.
  const LiquidGlassSvg.asset(
    String this.assetName, {
    super.key,
    this.bundle,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.tintColor,
    this.tintOpacity,
    this.rimColor,
    this.rimWidth = 1.0,
    this.strokeToFill = true,
    this.settings,
    this.interactive = false,
    this.onTap,
    this.semanticLabel,
    this.child,
  }) : svg = null;

  /// SVG document or path data.
  final String? svg;

  /// Asset path of the SVG.
  final String? assetName;

  /// Bundle to load [assetName] from.
  final AssetBundle? bundle;

  /// Width. When only one side is given the other follows the SVG aspect ratio.
  final double? width;

  /// Height. When only one side is given the other follows the SVG aspect ratio.
  final double? height;

  /// How the artwork fits the box.
  final BoxFit fit;

  /// Where the artwork sits in the box.
  final Alignment alignment;

  /// Paints the plain SVG in one colour.
  final Color? color;

  /// Colour mixed into the glass.
  final Color? tintColor;

  /// Strength of [tintColor].
  final double? tintOpacity;

  /// Edge highlight colour of Flutter-drawn glass.
  final Color? rimColor;

  /// Edge highlight width of Flutter-drawn glass.
  final double rimWidth;

  /// Turns stroke-only artwork into a filled outline.
  final bool strokeToFill;

  /// Glass settings for this widget. Falls back to the nearest [LiquidGlassTheme], then [LiquidGlassService].
  final LiquidGlassSettings? settings;

  /// Whether the glass follows and stretches under the finger.
  final bool interactive;

  /// Called for taps inside the outline.
  final VoidCallback? onTap;

  /// Screen reader label.
  final String? semanticLabel;

  /// Content drawn inside the outline.
  final Widget? child;

  /// Whether glass or the plain SVG is shown with [settings].
  static bool usesGlass(LiquidGlassSettings settings) =>
      settings.enabled &&
      (LiquidGlassService.isNativePlatform ||
          settings.fallback == LiquidGlassFallback.frosted);

  /// Loads an SVG asset ahead of time.
  static Future<void> precache(String assetName, {AssetBundle? bundle}) =>
      _SvgAssetState._load(bundle ?? rootBundle, assetName);

  @override
  Widget build(BuildContext context) {
    final source = svg;
    if (source != null) return _SvgBody(config: this, source: source);
    return _SvgAsset(config: this);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('assetName', assetName, defaultValue: null))
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(DoubleProperty('height', height, defaultValue: null))
      ..add(EnumProperty('fit', fit, defaultValue: BoxFit.contain))
      ..add(ColorProperty('tintColor', tintColor, defaultValue: null))
      ..add(
        FlagProperty('interactive', value: interactive, ifTrue: 'interactive'),
      );
  }
}

class _SvgAsset extends StatefulWidget {
  const _SvgAsset({required this.config});

  final LiquidGlassSvg config;

  @override
  State<_SvgAsset> createState() => _SvgAssetState();
}

class _SvgAssetState extends State<_SvgAsset> {
  static final _sources = <String, String>{};
  static final _pending = <String, Future<String>>{};

  static String _key(AssetBundle bundle, String assetName) =>
      '${identityHashCode(bundle)}|$assetName';

  static Future<String> _load(AssetBundle bundle, String assetName) {
    final key = _key(bundle, assetName);
    final cached = _sources[key];
    if (cached != null) return SynchronousFuture(cached);
    return _pending[key] ??= bundle
        .loadString(assetName)
        .then((text) {
          _sources[key] = text;
          if (_sources.length > 64) _sources.remove(_sources.keys.first);
          return text;
        })
        .whenComplete(() {
          _pending.remove(key);
        });
  }

  String? _source;
  String? _requested;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_SvgAsset oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.assetName != widget.config.assetName ||
        oldWidget.config.bundle != widget.config.bundle) {
      _resolve();
    }
  }

  void _resolve() {
    final bundle = widget.config.bundle ?? DefaultAssetBundle.of(context);
    final assetName = widget.config.assetName!;
    final key = _key(bundle, assetName);
    if (key == _requested) return;
    _requested = key;
    final cached = _sources[key];
    if (cached != null) {
      _source = cached;
      return;
    }
    _load(bundle, assetName).then(
      (text) {
        if (!mounted || _requested != key) return;
        setState(() => _source = text);
      },
      onError: (Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'liquid_design',
            context: ErrorDescription('while loading the SVG asset $assetName'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    if (source == null) {
      return SizedBox(width: widget.config.width, height: widget.config.height);
    }
    return _SvgBody(config: widget.config, source: source);
  }
}

class _SvgBody extends StatelessWidget {
  const _SvgBody({required this.config, required this.source});

  final LiquidGlassSvg config;
  final String source;

  Size _size(Rect viewBox) {
    final aspect = viewBox.width > 0 && viewBox.height > 0
        ? viewBox.width / viewBox.height
        : 1.0;
    final width = config.width, height = config.height;
    if (width != null && height != null) return Size(width, height);
    if (width != null) return Size(width, width / aspect);
    if (height != null) return Size(height * aspect, height);
    return viewBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final SvgDocument document;
    final LiquidGlassShape shape;
    try {
      document = cachedSvgDocument(source);
      shape = LiquidGlassShape.svg(
        source,
        strokeToFill: config.strokeToFill,
        fit: config.fit,
        alignment: config.alignment,
      );
    } on FormatException catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'liquid_design',
          context: ErrorDescription('while parsing an SVG for LiquidGlassSvg'),
        ),
      );
      return SizedBox(width: config.width, height: config.height);
    }

    final size = _size(document.viewBox);
    return LiquidGlassSettingsBuilder(
      settings: config.settings,
      builder: (context, settings) {
        final child = config.child;
        final content = child == null
            ? const SizedBox.expand()
            : ClipPath(
                clipper: _ShapeClipper(shape),
                child: SizedBox.expand(child: child),
              );

        Widget result;
        if (LiquidGlassSvg.usesGlass(settings)) {
          result = LiquidGlass(
            shape: shape,
            settings: settings,
            tintColor: config.tintColor,
            tintOpacity: config.tintOpacity,
            interactive: config.interactive,
            rimColor: config.rimColor,
            rimWidth: config.rimWidth,
            child: content,
          );
        } else {
          result = Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _SvgPainter(
                  document: document,
                  fit: config.fit,
                  alignment: config.alignment,
                  color: config.color,
                ),
              ),
              if (child != null) content,
            ],
          );
        }

        result = SizedBox.fromSize(size: size, child: result);

        final onTap = config.onTap;
        if (onTap != null) {
          result = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: result,
          );
        }
        if (onTap != null || config.interactive) {
          result = _ShapeHitTest(shape: shape, child: result);
        }

        final label = config.semanticLabel;
        if (label != null || onTap != null) {
          result = Semantics(
            label: label,
            button: onTap != null,
            image: onTap == null,
            container: true,
            child: ExcludeSemantics(child: result),
          );
        }
        return result;
      },
    );
  }
}

class _ShapeClipper extends CustomClipper<Path> {
  const _ShapeClipper(this.shape);

  final LiquidGlassShape shape;

  @override
  Path getClip(Size size) => shape.toPath(Offset.zero & size);

  @override
  bool shouldReclip(_ShapeClipper old) => old.shape != shape;
}

class _SvgPainter extends CustomPainter {
  _SvgPainter({
    required this.document,
    required this.fit,
    required this.alignment,
    required this.color,
  });

  final SvgDocument document;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;

  void _applySource(Paint paint, SvgPaintSource source, double opacity) {
    final override = color;
    if (override != null) {
      paint.color = override.withValues(alpha: override.a * opacity);
      return;
    }
    final solid = source.color;
    if (solid != null) {
      paint.color = solid.withValues(alpha: solid.a * opacity);
      return;
    }
    paint.shader = source.gradient!.createShader(opacity);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = svgFitMatrix(document.viewBox, size, fit, alignment);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.transform(matrix.toMatrix4());
    for (final d in document.drawables) {
      if (d.hasFill) {
        final paint = Paint()..isAntiAlias = true;
        _applySource(paint, d.fill!, d.fillOpacity * d.opacity);
        canvas.drawPath(d.path, paint);
      }
      if (d.hasStroke) {
        final paint = Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = d.strokeWidth
          ..strokeMiterLimit = d.miterLimit
          ..strokeCap = switch (d.cap) {
            SvgLineCap.round => StrokeCap.round,
            SvgLineCap.square => StrokeCap.square,
            SvgLineCap.butt => StrokeCap.butt,
          }
          ..strokeJoin = switch (d.join) {
            SvgLineJoin.round => StrokeJoin.round,
            SvgLineJoin.bevel => StrokeJoin.bevel,
            SvgLineJoin.miter => StrokeJoin.miter,
          };
        _applySource(paint, d.stroke!, d.strokeOpacity * d.opacity);
        canvas.drawPath(d.path, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SvgPainter old) =>
      !identical(old.document, document) ||
      old.fit != fit ||
      old.alignment != alignment ||
      old.color != color;
}

class _ShapeHitTest extends SingleChildRenderObjectWidget {
  const _ShapeHitTest({required this.shape, super.child});

  final LiquidGlassShape shape;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderShapeHitTest(shape);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderShapeHitTest renderObject,
  ) {
    renderObject.shape = shape;
  }
}

class _RenderShapeHitTest extends RenderProxyBox {
  _RenderShapeHitTest(this._shape);

  LiquidGlassShape _shape;
  Path? _path;
  Size? _pathSize;

  set shape(LiquidGlassShape value) {
    if (value == _shape) return;
    _shape = value;
    _path = null;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (_path == null || _pathSize != size) {
      _path = _shape.toPath(Offset.zero & size);
      _pathSize = size;
    }
    if (!_path!.contains(position)) return false;
    return super.hitTest(result, position: position);
  }
}
