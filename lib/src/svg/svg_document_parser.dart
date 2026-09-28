import 'dart:math' as math;
import 'dart:ui';

import 'stroke_outliner.dart';
import 'svg_path_parser.dart';

class SvgGradient {
  SvgGradient({
    required this.radial,
    required this.colors,
    required this.stops,
    required this.matrix,
    required this.tileMode,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.r,
    required this.fx,
    required this.fy,
  });

  final bool radial;
  final List<Color> colors;
  final List<double> stops;
  final SvgMatrix matrix;
  final TileMode tileMode;
  final double x1, y1, x2, y2, r, fx, fy;

  Shader createShader(double opacity) {
    final faded = [for (final c in colors) c.withValues(alpha: c.a * opacity)];
    final transform = matrix.toMatrix4();
    if (radial) {
      final focal = Offset(fx, fy);
      final center = Offset(x1, y1);
      return Gradient.radial(
        center,
        r,
        faded,
        stops,
        tileMode,
        transform,
        focal == center ? null : focal,
      );
    }
    return Gradient.linear(
      Offset(x1, y1),
      Offset(x2, y2),
      faded,
      stops,
      tileMode,
      transform,
    );
  }
}

class SvgPaintSource {
  const SvgPaintSource.color(Color this.color) : gradient = null;

  const SvgPaintSource.gradient(SvgGradient this.gradient) : color = null;

  final Color? color;
  final SvgGradient? gradient;
}

class SvgDrawable {
  SvgDrawable({
    required this.commands,
    required this.fillType,
    required this.fill,
    required this.fillOpacity,
    required this.stroke,
    required this.strokeOpacity,
    required this.strokeWidth,
    required this.cap,
    required this.join,
    required this.miterLimit,
    required this.opacity,
  });

  final SvgPathCommands commands;
  final PathFillType fillType;
  final SvgPaintSource? fill;
  final double fillOpacity;
  final SvgPaintSource? stroke;
  final double strokeOpacity;
  final double strokeWidth;
  final SvgLineCap cap;
  final SvgLineJoin join;
  final double miterLimit;
  final double opacity;

  bool get hasFill => fill != null && fillOpacity * opacity > 0;

  bool get hasStroke =>
      stroke != null && strokeWidth > 0 && strokeOpacity * opacity > 0;

  late final Path path = commands.toPath(fillType: fillType);
}

class SvgSilhouette {
  const SvgSilhouette(this.commands, this.fillType);

  final SvgPathCommands commands;
  final PathFillType fillType;
}

class SvgDocument {
  SvgDocument(this.viewBox, this.drawables);

  final Rect viewBox;
  final List<SvgDrawable> drawables;

  SvgSilhouette silhouette({bool strokeToFill = true}) {
    final fills = drawables.where((d) => d.hasFill).toList();
    final strokes = strokeToFill
        ? drawables.where((d) => d.hasStroke).toList()
        : const <SvgDrawable>[];

    if (strokes.isEmpty && fills.length == 1) {
      return SvgSilhouette(fills.first.commands, fills.first.fillType);
    }

    final regions = <Path>[
      for (final d in fills) d.path,
      for (final d in strokes)
        outlineStroke(
          d.commands,
          width: d.strokeWidth,
          cap: d.cap,
          join: d.join,
          miterLimit: d.miterLimit,
        ),
    ];
    if (regions.isEmpty) {
      final all = SvgPathCommands();
      for (final d in drawables) {
        all.addAll(d.commands);
      }
      return SvgSilhouette(all, PathFillType.nonZero);
    }
    if (regions.length == 1 && strokes.isEmpty) {
      return SvgSilhouette(fills.first.commands, fills.first.fillType);
    }

    var union = regions.first;
    for (final region in regions.skip(1)) {
      try {
        union = Path.combine(PathOperation.union, union, region);
      } catch (_) {
        union = Path.from(union)..addPath(region, Offset.zero);
      }
    }
    final extent = math.max(viewBox.width, viewBox.height);
    return SvgSilhouette(
      SvgPathCommands.fromPath(union, tolerance: extent / 800),
      union.fillType,
    );
  }
}

bool looksLikeSvgDocument(String source) {
  final text = source.trimLeft();
  return text.startsWith('<');
}

SvgDocument parseSvgDocument(String source) => _SvgReader(source).read();

class _Style {
  _Style();

  String? fill;
  String? fillOpacity;
  String? fillRule;
  String? stroke;
  String? strokeWidth;
  String? strokeOpacity;
  String? cap;
  String? join;
  String? miterLimit;
  String? color;
  String? visibility;

  _Style inherit() => _Style()
    ..fill = fill
    ..fillOpacity = fillOpacity
    ..fillRule = fillRule
    ..stroke = stroke
    ..strokeWidth = strokeWidth
    ..strokeOpacity = strokeOpacity
    ..cap = cap
    ..join = join
    ..miterLimit = miterLimit
    ..color = color
    ..visibility = visibility;

  void apply(String name, String value) {
    value = value.replaceAll(RegExp(r'\s*!important\s*$'), '').trim();
    if (value.isEmpty || value == 'inherit') return;
    switch (name) {
      case 'fill':
        fill = value;
      case 'fill-opacity':
        fillOpacity = value;
      case 'fill-rule':
        fillRule = value;
      case 'stroke':
        stroke = value;
      case 'stroke-width':
        strokeWidth = value;
      case 'stroke-opacity':
        strokeOpacity = value;
      case 'stroke-linecap':
        cap = value;
      case 'stroke-linejoin':
        join = value;
      case 'stroke-miterlimit':
        miterLimit = value;
      case 'color':
        color = value;
      case 'visibility':
        visibility = value;
    }
  }
}

class _Frame {
  _Frame({
    required this.name,
    required this.style,
    required this.matrix,
    required this.opacity,
    required this.hidden,
  });

  final String name;
  final _Style style;
  final SvgMatrix matrix;
  final double opacity;
  final bool hidden;
}

class _GradientDef {
  _GradientDef(this.radial, this.attrs);

  final bool radial;
  final Map<String, String> attrs;
  final stops = <(double, Color)>[];
}

class _SvgReader {
  _SvgReader(this.source);

  final String source;

  static const _hiddenContainers = {
    'defs',
    'clipPath',
    'mask',
    'symbol',
    'pattern',
    'marker',
    'metadata',
    'title',
    'desc',
    'style',
    'script',
    'filter',
  };

  final _rules = <String, Map<String, String>>{};
  final _gradients = <String, _GradientDef>{};
  final _drawables = <SvgDrawable>[];
  final _stack = <_Frame>[];
  Rect? _viewBox;
  double? _width, _height;
  _GradientDef? _openGradient;
  var _sawRoot = false;
  var _collecting = false;

  SvgDocument read() {
    _readStyles();
    _collecting = true;
    _walk();
    _stack.clear();
    _sawRoot = false;
    _collecting = false;
    _walk();
    final drawables = _drawables;
    var viewBox = _viewBox;
    if (viewBox == null && _width != null && _height != null) {
      viewBox = Rect.fromLTWH(0, 0, _width!, _height!);
    }
    if (viewBox == null || viewBox.isEmpty) {
      var bounds = Rect.zero;
      var first = true;
      for (final d in drawables) {
        final b = d.path.getBounds();
        bounds = first ? b : bounds.expandToInclude(b);
        first = false;
      }
      viewBox = bounds;
    }
    return SvgDocument(viewBox, drawables);
  }

  void _readStyles() {
    final pattern = RegExp(r'<style[^>]*>([\s\S]*?)</style>');
    for (final match in pattern.allMatches(source)) {
      var css = match.group(1) ?? '';
      css = css
          .replaceAll('<![CDATA[', '')
          .replaceAll(']]>', '')
          .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
      for (final block in css.split('}')) {
        final open = block.indexOf('{');
        if (open < 0) continue;
        final selectors = block.substring(0, open).split(',');
        final declarations = _parseDeclarations(block.substring(open + 1));
        for (var selector in selectors) {
          selector = selector.trim();
          if (selector.isEmpty) continue;
          (_rules[selector] ??= {}).addAll(declarations);
        }
      }
    }
  }

  static Map<String, String> _parseDeclarations(String text) {
    final out = <String, String>{};
    for (final part in text.split(';')) {
      final colon = part.indexOf(':');
      if (colon < 0) continue;
      final name = part.substring(0, colon).trim();
      final value = part.substring(colon + 1).trim();
      if (name.isNotEmpty) out[name] = value;
    }
    return out;
  }

  void _walk() {
    var i = 0;
    final s = source;
    while (i < s.length) {
      final lt = s.indexOf('<', i);
      if (lt < 0) break;
      if (s.startsWith('<!--', lt)) {
        final end = s.indexOf('-->', lt + 4);
        i = end < 0 ? s.length : end + 3;
        continue;
      }
      if (s.startsWith('<![CDATA[', lt)) {
        final end = s.indexOf(']]>', lt);
        i = end < 0 ? s.length : end + 3;
        continue;
      }
      if (s.startsWith('<?', lt)) {
        final end = s.indexOf('?>', lt);
        i = end < 0 ? s.length : end + 2;
        continue;
      }
      if (s.startsWith('<!', lt)) {
        i = _skipDeclaration(lt);
        continue;
      }
      final end = _tagEnd(lt);
      if (end < 0) break;
      final body = s.substring(lt + 1, end);
      i = end + 1;
      if (body.startsWith('/')) {
        _close(body.substring(1).trim());
        continue;
      }
      final selfClosing = body.endsWith('/');
      final content = selfClosing ? body.substring(0, body.length - 1) : body;
      final nameEnd = content.indexOf(RegExp(r'[\s/]'));
      final name = _localName(
        nameEnd < 0 ? content.trim() : content.substring(0, nameEnd),
      );
      final attrs = _parseAttributes(
        nameEnd < 0 ? '' : content.substring(nameEnd),
      );
      _open(name, attrs);
      if (selfClosing) _close(name);
    }
  }

  int _skipDeclaration(int start) {
    var depth = 0;
    for (var i = start; i < source.length; i++) {
      final c = source[i];
      if (c == '[') depth++;
      if (c == ']') depth--;
      if (c == '>' && depth <= 0) return i + 1;
    }
    return source.length;
  }

  int _tagEnd(int start) {
    String? quote;
    for (var i = start + 1; i < source.length; i++) {
      final c = source[i];
      if (quote != null) {
        if (c == quote) quote = null;
      } else if (c == '"' || c == "'") {
        quote = c;
      } else if (c == '>') {
        return i;
      }
    }
    return -1;
  }

  static String _localName(String name) {
    final colon = name.indexOf(':');
    return colon < 0 ? name : name.substring(colon + 1);
  }

  static final _attributePattern = RegExp(
    r'''([^\s=/]+)\s*=\s*(?:"([^"]*)"|'([^']*)')''',
  );

  static Map<String, String> _parseAttributes(String text) {
    final out = <String, String>{};
    for (final m in _attributePattern.allMatches(text)) {
      out[m.group(1)!] = _decodeEntities(m.group(2) ?? m.group(3) ?? '');
    }
    return out;
  }

  static String _decodeEntities(String value) => value
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');

  void _close(String name) {
    name = _localName(name);
    if (name == 'linearGradient' || name == 'radialGradient') {
      _openGradient = null;
    }
    for (var i = _stack.length - 1; i >= 0; i--) {
      if (_stack[i].name == name) {
        _stack.removeRange(i, _stack.length);
        return;
      }
    }
  }

  void _open(String name, Map<String, String> attrs) {
    if (name == 'linearGradient' || name == 'radialGradient') {
      final id = attrs['id'];
      final def = _collecting || id == null
          ? _GradientDef(name == 'radialGradient', attrs)
          : _gradients[id] ?? _GradientDef(name == 'radialGradient', attrs);
      if (id != null && _collecting) _gradients[id] = def;
      _openGradient = _collecting ? def : null;
      _stack.add(
        _Frame(
          name: name,
          style: _Style(),
          matrix: SvgMatrix.identity,
          opacity: 1,
          hidden: true,
        ),
      );
      return;
    }
    if (name == 'stop') {
      final def = _openGradient;
      if (def != null) _addStop(def, attrs);
      _stack.add(
        _Frame(
          name: name,
          style: _Style(),
          matrix: SvgMatrix.identity,
          opacity: 1,
          hidden: true,
        ),
      );
      return;
    }

    final parent = _stack.isEmpty ? null : _stack.last;
    final style = parent?.style.inherit() ?? _Style();
    final declarations = _declarationsFor(name, attrs);
    for (final entry in declarations.entries) {
      style.apply(entry.key, entry.value);
    }

    var matrix = parent?.matrix ?? SvgMatrix.identity;
    if (name == 'svg' && _sawRoot) {
      matrix = matrix.multiply(
        SvgMatrix.translate(_length(attrs['x']), _length(attrs['y'])),
      );
    }
    final transform = attrs['transform'];
    if (transform != null) matrix = matrix.multiply(_parseTransform(transform));

    final ownOpacity = _number(declarations['opacity'], 1).clamp(0.0, 1.0);
    final hidden =
        (parent?.hidden ?? false) ||
        _hiddenContainers.contains(name) ||
        declarations['display'] == 'none';
    final frame = _Frame(
      name: name,
      style: style,
      matrix: matrix,
      opacity: (parent?.opacity ?? 1) * ownOpacity,
      hidden: hidden,
    );
    _stack.add(frame);

    if (name == 'svg' && !_sawRoot) {
      _sawRoot = true;
      _viewBox = _parseViewBox(attrs['viewBox']);
      _width = _optionalLength(attrs['width']);
      _height = _optionalLength(attrs['height']);
      return;
    }
    if (_collecting || hidden || style.visibility == 'hidden') return;

    final geometry = _geometry(name, attrs);
    if (geometry == null || geometry.isEmpty) return;
    _emit(geometry, frame);
  }

  Map<String, String> _declarationsFor(String name, Map<String, String> attrs) {
    final out = <String, String>{};
    const presentation = {
      'fill',
      'fill-opacity',
      'fill-rule',
      'stroke',
      'stroke-width',
      'stroke-opacity',
      'stroke-linecap',
      'stroke-linejoin',
      'stroke-miterlimit',
      'opacity',
      'display',
      'visibility',
      'color',
    };
    for (final key in presentation) {
      final value = attrs[key];
      if (value != null) out[key] = value.trim();
    }
    final tagRule = _rules[name];
    if (tagRule != null) out.addAll(tagRule);
    final classes = attrs['class']?.split(RegExp(r'\s+')) ?? const [];
    for (final cls in classes) {
      if (cls.isEmpty) continue;
      final rule = _rules['.$cls'] ?? _rules['$name.$cls'];
      if (rule != null) out.addAll(rule);
    }
    final id = attrs['id'];
    if (id != null) {
      final rule = _rules['#$id'];
      if (rule != null) out.addAll(rule);
    }
    final inline = attrs['style'];
    if (inline != null) out.addAll(_parseDeclarations(inline));
    return out;
  }

  SvgPathCommands? _geometry(String name, Map<String, String> a) {
    switch (name) {
      case 'path':
        final d = a['d'];
        if (d == null || d.trim().isEmpty) return null;
        try {
          return parseSvgPathData(d);
        } on FormatException {
          return null;
        }
      case 'rect':
        final w = _length(a['width'], _viewBox?.width);
        final h = _length(a['height'], _viewBox?.height);
        var rx = _optionalLength(a['rx']);
        var ry = _optionalLength(a['ry']);
        rx ??= ry ?? 0;
        ry ??= rx;
        return SvgPathCommands()
          ..addRect(_length(a['x']), _length(a['y']), w, h, rx, ry);
      case 'circle':
        final r = _length(a['r']);
        if (r <= 0) return null;
        return SvgPathCommands()
          ..addEllipse(_length(a['cx']), _length(a['cy']), r, r);
      case 'ellipse':
        final rx = _length(a['rx']), ry = _length(a['ry']);
        if (rx <= 0 || ry <= 0) return null;
        return SvgPathCommands()
          ..addEllipse(_length(a['cx']), _length(a['cy']), rx, ry);
      case 'line':
        return SvgPathCommands()
          ..moveTo(_length(a['x1']), _length(a['y1']))
          ..lineTo(_length(a['x2']), _length(a['y2']));
      case 'polyline':
      case 'polygon':
        final values = _numbers(a['points'] ?? '');
        if (values.length < 4) return null;
        final out = SvgPathCommands()..moveTo(values[0], values[1]);
        for (var i = 2; i + 1 < values.length; i += 2) {
          out.lineTo(values[i], values[i + 1]);
        }
        if (name == 'polygon') out.close();
        return out;
    }
    return null;
  }

  void _emit(SvgPathCommands local, _Frame frame) {
    final style = frame.style;
    final commands = local.transformed(frame.matrix);
    final scale = frame.matrix.scaleFactor;
    SvgPaintSource? paint(String? value, String fallback) =>
        _paint(value ?? fallback, style, local, frame.matrix);

    _drawables.add(
      SvgDrawable(
        commands: commands,
        fillType: style.fillRule == 'evenodd'
            ? PathFillType.evenOdd
            : PathFillType.nonZero,
        fill: paint(style.fill, 'black'),
        fillOpacity: _number(style.fillOpacity, 1).clamp(0.0, 1.0),
        stroke: paint(style.stroke, 'none'),
        strokeOpacity: _number(style.strokeOpacity, 1).clamp(0.0, 1.0),
        strokeWidth: _length(style.strokeWidth, null, 1) * scale,
        cap: switch (style.cap) {
          'round' => SvgLineCap.round,
          'square' => SvgLineCap.square,
          _ => SvgLineCap.butt,
        },
        join: switch (style.join) {
          'round' => SvgLineJoin.round,
          'bevel' => SvgLineJoin.bevel,
          _ => SvgLineJoin.miter,
        },
        miterLimit: _number(style.miterLimit, 4),
        opacity: frame.opacity,
      ),
    );
  }

  SvgPaintSource? _paint(
    String value,
    _Style style,
    SvgPathCommands local,
    SvgMatrix matrix,
  ) {
    value = value.trim();
    if (value == 'none' || value == 'transparent') return null;
    if (value.startsWith('url(')) {
      final close = value.indexOf(')');
      final ref = value
          .substring(4, close < 0 ? value.length : close)
          .trim()
          .replaceAll(RegExp('''^["']|["']\$'''), '');
      final id = ref.startsWith('#') ? ref.substring(1) : ref;
      final gradient = _buildGradient(id, local, matrix);
      if (gradient != null) return SvgPaintSource.gradient(gradient);
      final fallback = close < 0 ? '' : value.substring(close + 1).trim();
      if (fallback.isNotEmpty) return _paint(fallback, style, local, matrix);
      return const SvgPaintSource.color(Color(0xFF000000));
    }
    if (value == 'currentColor') {
      final color = parseSvgColor(style.color ?? 'black');
      return color == null ? null : SvgPaintSource.color(color);
    }
    final color = parseSvgColor(value);
    return color == null ? null : SvgPaintSource.color(color);
  }

  String? _gradientAttr(_GradientDef def, String name, [int depth = 0]) {
    final value = def.attrs[name];
    if (value != null || depth > 8) return value;
    final parent = _gradientParent(def);
    return parent == null ? null : _gradientAttr(parent, name, depth + 1);
  }

  _GradientDef? _gradientParent(_GradientDef def) {
    final href = def.attrs['href'] ?? def.attrs['xlink:href'];
    if (href == null || !href.startsWith('#')) return null;
    return _gradients[href.substring(1)];
  }

  List<(double, Color)> _gradientStops(_GradientDef def) {
    var current = def;
    for (var depth = 0; depth < 8; depth++) {
      if (current.stops.isNotEmpty) return current.stops;
      final parent = _gradientParent(current);
      if (parent == null) break;
      current = parent;
    }
    return current.stops;
  }

  SvgGradient? _buildGradient(
    String id,
    SvgPathCommands local,
    SvgMatrix matrix,
  ) {
    final def = _gradients[id];
    if (def == null) return null;
    final stops = _gradientStops(def);
    if (stops.isEmpty) return null;

    final bbox = _gradientAttr(def, 'gradientUnits') != 'userSpaceOnUse';
    double coordinate(String name, double fallback, double extent) {
      final raw = _gradientAttr(def, name);
      if (raw == null) return fallback;
      final text = raw.trim();
      if (text.endsWith('%')) {
        final v = double.tryParse(text.substring(0, text.length - 1)) ?? 0;
        return bbox ? v / 100 : v / 100 * extent;
      }
      return double.tryParse(text.replaceAll(RegExp(r'[a-z]+$'), '')) ??
          fallback;
    }

    final vb = _viewBox ?? Rect.zero;
    final w = bbox ? 1.0 : vb.width, h = bbox ? 1.0 : vb.height;
    var toUser = matrix;
    if (bbox) {
      final bounds = local.toPath().getBounds();
      toUser = toUser.multiply(
        SvgMatrix(bounds.width, 0, 0, bounds.height, bounds.left, bounds.top),
      );
    }
    final gradientTransform = _gradientAttr(def, 'gradientTransform');
    if (gradientTransform != null) {
      toUser = toUser.multiply(_parseTransform(gradientTransform));
    }

    final colors = <Color>[];
    final offsets = <double>[];
    var last = 0.0;
    for (final (offset, color) in stops) {
      last = math.max(last, offset.clamp(0.0, 1.0));
      offsets.add(last);
      colors.add(color);
    }
    if (colors.length == 1) {
      colors.add(colors.first);
      offsets
        ..clear()
        ..addAll([0, 1]);
    }
    final tileMode = switch (_gradientAttr(def, 'spreadMethod')) {
      'reflect' => TileMode.mirror,
      'repeat' => TileMode.repeated,
      _ => TileMode.clamp,
    };

    if (def.radial) {
      final cx = coordinate('cx', bbox ? 0.5 : w / 2, w);
      final cy = coordinate('cy', bbox ? 0.5 : h / 2, h);
      return SvgGradient(
        radial: true,
        colors: colors,
        stops: offsets,
        matrix: toUser,
        tileMode: tileMode,
        x1: cx,
        y1: cy,
        x2: 0,
        y2: 0,
        r: coordinate('r', bbox ? 0.5 : math.max(w, h) / 2, math.max(w, h)),
        fx: coordinate('fx', cx, w),
        fy: coordinate('fy', cy, h),
      );
    }
    return SvgGradient(
      radial: false,
      colors: colors,
      stops: offsets,
      matrix: toUser,
      tileMode: tileMode,
      x1: coordinate('x1', 0, w),
      y1: coordinate('y1', 0, h),
      x2: coordinate('x2', bbox ? 1 : w, w),
      y2: coordinate('y2', 0, h),
      r: 0,
      fx: 0,
      fy: 0,
    );
  }

  void _addStop(_GradientDef def, Map<String, String> attrs) {
    final declarations = <String, String>{
      if (attrs['stop-color'] != null) 'stop-color': attrs['stop-color']!,
      if (attrs['stop-opacity'] != null) 'stop-opacity': attrs['stop-opacity']!,
      ..._parseDeclarations(attrs['style'] ?? ''),
    };
    final raw = attrs['offset']?.trim() ?? '0';
    final offset = raw.endsWith('%')
        ? (double.tryParse(raw.substring(0, raw.length - 1)) ?? 0) / 100
        : double.tryParse(raw) ?? 0;
    var color =
        parseSvgColor(declarations['stop-color'] ?? 'black') ??
        const Color(0xFF000000);
    final alpha = _number(declarations['stop-opacity'], 1).clamp(0.0, 1.0);
    color = color.withValues(alpha: color.a * alpha);
    def.stops.add((offset, color));
  }

  static Rect? _parseViewBox(String? value) {
    if (value == null) return null;
    final n = _numbers(value);
    if (n.length != 4 || n[2] <= 0 || n[3] <= 0) return null;
    return Rect.fromLTWH(n[0], n[1], n[2], n[3]);
  }

  static final _numberPattern = RegExp(
    r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
  );

  static List<double> _numbers(String text) => [
    for (final m in _numberPattern.allMatches(text)) double.parse(m.group(0)!),
  ];

  static double _number(String? value, double fallback) {
    if (value == null) return fallback;
    final text = value.trim();
    if (text.endsWith('%')) {
      final v = double.tryParse(text.substring(0, text.length - 1));
      return v == null ? fallback : v / 100;
    }
    return double.tryParse(text) ?? fallback;
  }

  static double? _optionalLength(String? value, [double? extent]) {
    if (value == null) return null;
    final text = value.trim();
    if (text.endsWith('%')) {
      final v = double.tryParse(text.substring(0, text.length - 1));
      if (v == null || extent == null) return null;
      return v / 100 * extent;
    }
    final match = _numberPattern.matchAsPrefix(text);
    return match == null ? null : double.parse(match.group(0)!);
  }

  static double _length(String? value, [double? extent, double fallback = 0]) =>
      _optionalLength(value, extent) ?? fallback;

  static SvgMatrix _parseTransform(String text) {
    var matrix = SvgMatrix.identity;
    final pattern = RegExp(
      r'(matrix|translate|scale|rotate|skewX|skewY)\s*\(([^)]*)\)',
    );
    for (final m in pattern.allMatches(text)) {
      final v = _numbers(m.group(2)!);
      double at(int i, [double fallback = 0]) => i < v.length ? v[i] : fallback;
      final next = switch (m.group(1)) {
        'matrix' when v.length >= 6 => SvgMatrix(
          v[0],
          v[1],
          v[2],
          v[3],
          v[4],
          v[5],
        ),
        'translate' => SvgMatrix.translate(at(0), at(1)),
        'scale' => SvgMatrix.scale(at(0, 1), at(1, at(0, 1))),
        'rotate' => SvgMatrix.rotate(at(0), at(1), at(2)),
        'skewX' => SvgMatrix.skewX(at(0)),
        'skewY' => SvgMatrix.skewY(at(0)),
        _ => SvgMatrix.identity,
      };
      matrix = matrix.multiply(next);
    }
    return matrix;
  }
}

const _namedColors = <String, int>{
  'black': 0xFF000000,
  'white': 0xFFFFFFFF,
  'red': 0xFFFF0000,
  'green': 0xFF008000,
  'lime': 0xFF00FF00,
  'blue': 0xFF0000FF,
  'yellow': 0xFFFFFF00,
  'cyan': 0xFF00FFFF,
  'aqua': 0xFF00FFFF,
  'magenta': 0xFFFF00FF,
  'fuchsia': 0xFFFF00FF,
  'gray': 0xFF808080,
  'grey': 0xFF808080,
  'silver': 0xFFC0C0C0,
  'maroon': 0xFF800000,
  'olive': 0xFF808000,
  'navy': 0xFF000080,
  'purple': 0xFF800080,
  'teal': 0xFF008080,
  'orange': 0xFFFFA500,
  'pink': 0xFFFFC0CB,
  'brown': 0xFFA52A2A,
  'gold': 0xFFFFD700,
  'indigo': 0xFF4B0082,
  'violet': 0xFFEE82EE,
  'transparent': 0x00000000,
};

Color? parseSvgColor(String value) {
  final text = value.trim().toLowerCase();
  if (text.isEmpty || text == 'none') return null;
  if (text.startsWith('#')) {
    var hex = text.substring(1);
    if (hex.length == 3 || hex.length == 4) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;
    if (hex.length == 6) return Color(0xFF000000 | parsed);
    if (hex.length == 8) {
      return Color(((parsed & 0xFF) << 24) | (parsed >> 8));
    }
    return null;
  }
  final functional = RegExp(r'^(rgba?|hsla?)\(([^)]*)\)$').firstMatch(text);
  if (functional != null) {
    final parts = functional
        .group(2)!
        .split(RegExp(r'[\s,/]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 3) return null;
    double channel(String p, double scale) => p.endsWith('%')
        ? (double.tryParse(p.substring(0, p.length - 1)) ?? 0) / 100
        : (double.tryParse(p) ?? 0) / scale;
    final alpha = parts.length > 3 ? channel(parts[3], 1).clamp(0.0, 1.0) : 1.0;
    if (functional.group(1)!.startsWith('rgb')) {
      return Color.from(
        alpha: alpha,
        red: channel(parts[0], 255).clamp(0.0, 1.0),
        green: channel(parts[1], 255).clamp(0.0, 1.0),
        blue: channel(parts[2], 255).clamp(0.0, 1.0),
      );
    }
    final hue = (double.tryParse(parts[0].replaceAll('deg', '')) ?? 0) % 360;
    final s = channel(parts[1], 100).clamp(0.0, 1.0);
    final l = channel(parts[2], 100).clamp(0.0, 1.0);
    final c = (1 - (2 * l - 1).abs()) * s;
    final x = c * (1 - ((hue / 60) % 2 - 1).abs());
    final m = l - c / 2;
    final (r, g, b) = switch (hue ~/ 60) {
      0 => (c, x, 0.0),
      1 => (x, c, 0.0),
      2 => (0.0, c, x),
      3 => (0.0, x, c),
      4 => (x, 0.0, c),
      _ => (c, 0.0, x),
    };
    return Color.from(alpha: alpha, red: r + m, green: g + m, blue: b + m);
  }
  final named = _namedColors[text];
  return named == null ? null : Color(named);
}
