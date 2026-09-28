import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

abstract final class SvgOp {
  static const int move = 0;
  static const int line = 1;
  static const int cubic = 2;
  static const int quad = 3;
  static const int close = 4;

  static int argCount(int op) => switch (op) {
    move || line => 2,
    cubic => 6,
    quad => 4,
    _ => 0,
  };
}

class SvgMatrix {
  const SvgMatrix(this.a, this.b, this.c, this.d, this.e, this.f);

  static const identity = SvgMatrix(1, 0, 0, 1, 0, 0);

  factory SvgMatrix.translate(double x, double y) =>
      SvgMatrix(1, 0, 0, 1, x, y);

  factory SvgMatrix.scale(double x, double y) => SvgMatrix(x, 0, 0, y, 0, 0);

  factory SvgMatrix.rotate(double degrees, [double cx = 0, double cy = 0]) {
    final r = degrees * math.pi / 180;
    final cos = math.cos(r), sin = math.sin(r);
    final rotation = SvgMatrix(cos, sin, -sin, cos, 0, 0);
    if (cx == 0 && cy == 0) return rotation;
    return SvgMatrix.translate(
      cx,
      cy,
    ).multiply(rotation).multiply(SvgMatrix.translate(-cx, -cy));
  }

  factory SvgMatrix.skewX(double degrees) =>
      SvgMatrix(1, 0, math.tan(degrees * math.pi / 180), 1, 0, 0);

  factory SvgMatrix.skewY(double degrees) =>
      SvgMatrix(1, math.tan(degrees * math.pi / 180), 0, 1, 0, 0);

  final double a, b, c, d, e, f;

  bool get isIdentity =>
      a == 1 && b == 0 && c == 0 && d == 1 && e == 0 && f == 0;

  double get scaleFactor => math.sqrt((a * d - b * c).abs());

  SvgMatrix multiply(SvgMatrix o) => SvgMatrix(
    a * o.a + c * o.b,
    b * o.a + d * o.b,
    a * o.c + c * o.d,
    b * o.c + d * o.d,
    a * o.e + c * o.f + e,
    b * o.e + d * o.f + f,
  );

  double mapX(double x, double y) => a * x + c * y + e;

  double mapY(double x, double y) => b * x + d * y + f;

  Float64List toMatrix4() => Float64List.fromList(<double>[
    a, b, 0, 0, //
    c, d, 0, 0, //
    0, 0, 1, 0, //
    e, f, 0, 1, //
  ]);
}

class SvgPathCommands {
  SvgPathCommands([List<double>? data]) : data = data ?? <double>[];

  final List<double> data;

  bool get isEmpty => data.isEmpty;

  void moveTo(double x, double y) => data.addAll([0, x, y]);

  void lineTo(double x, double y) => data.addAll([1, x, y]);

  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  ) => data.addAll([2, x1, y1, x2, y2, x, y]);

  void quadTo(double x1, double y1, double x, double y) =>
      data.addAll([3, x1, y1, x, y]);

  void close() => data.add(4);

  void addAll(SvgPathCommands other) => data.addAll(other.data);

  void forEach(void Function(int op, List<double> args) visit) {
    var i = 0;
    while (i < data.length) {
      final op = data[i].toInt();
      final count = SvgOp.argCount(op);
      visit(op, data.sublist(i + 1, i + 1 + count));
      i += 1 + count;
    }
  }

  SvgPathCommands mapPoints(
    double Function(double x, double y) mx,
    double Function(double x, double y) my,
  ) {
    final out = <double>[];
    var i = 0;
    while (i < data.length) {
      final op = data[i].toInt();
      out.add(op.toDouble());
      final count = SvgOp.argCount(op);
      for (var p = 0; p < count; p += 2) {
        final x = data[i + 1 + p], y = data[i + 2 + p];
        out
          ..add(mx(x, y))
          ..add(my(x, y));
      }
      i += 1 + count;
    }
    return SvgPathCommands(out);
  }

  SvgPathCommands transformed(SvgMatrix m) =>
      m.isIdentity ? SvgPathCommands(List.of(data)) : mapPoints(m.mapX, m.mapY);

  SvgPathCommands normalized(Rect viewBox) {
    final w = viewBox.width == 0 ? 1.0 : viewBox.width;
    final h = viewBox.height == 0 ? 1.0 : viewBox.height;
    double round(double v) => (v * 1e6).roundToDouble() / 1e6;
    return mapPoints(
      (x, _) => round((x - viewBox.left) / w),
      (_, y) => round((y - viewBox.top) / h),
    );
  }

  Path toPath({PathFillType fillType = PathFillType.nonZero}) {
    final path = Path()..fillType = fillType;
    forEach((op, p) {
      switch (op) {
        case SvgOp.move:
          path.moveTo(p[0], p[1]);
        case SvgOp.line:
          path.lineTo(p[0], p[1]);
        case SvgOp.cubic:
          path.cubicTo(p[0], p[1], p[2], p[3], p[4], p[5]);
        case SvgOp.quad:
          path.quadraticBezierTo(p[0], p[1], p[2], p[3]);
        case SvgOp.close:
          path.close();
      }
    });
    return path;
  }

  void addEllipse(double cx, double cy, double rx, double ry) {
    const k = 0.5522847498307936;
    final ox = rx * k, oy = ry * k;
    moveTo(cx + rx, cy);
    cubicTo(cx + rx, cy + oy, cx + ox, cy + ry, cx, cy + ry);
    cubicTo(cx - ox, cy + ry, cx - rx, cy + oy, cx - rx, cy);
    cubicTo(cx - rx, cy - oy, cx - ox, cy - ry, cx, cy - ry);
    cubicTo(cx + ox, cy - ry, cx + rx, cy - oy, cx + rx, cy);
    close();
  }

  void addRect(double x, double y, double w, double h, double rx, double ry) {
    if (w <= 0 || h <= 0) return;
    rx = math.min(rx, w / 2);
    ry = math.min(ry, h / 2);
    if (rx <= 0 || ry <= 0) {
      moveTo(x, y);
      lineTo(x + w, y);
      lineTo(x + w, y + h);
      lineTo(x, y + h);
      close();
      return;
    }
    const k = 0.5522847498307936;
    final ox = rx * k, oy = ry * k;
    moveTo(x + rx, y);
    lineTo(x + w - rx, y);
    cubicTo(x + w - rx + ox, y, x + w, y + ry - oy, x + w, y + ry);
    lineTo(x + w, y + h - ry);
    cubicTo(x + w, y + h - ry + oy, x + w - rx + ox, y + h, x + w - rx, y + h);
    lineTo(x + rx, y + h);
    cubicTo(x + rx - ox, y + h, x, y + h - ry + oy, x, y + h - ry);
    lineTo(x, y + ry);
    cubicTo(x, y + ry - oy, x + rx - ox, y, x + rx, y);
    close();
  }

  void arcTo(
    double x1,
    double y1,
    double rx,
    double ry,
    double angle,
    bool largeArc,
    bool sweep,
    double x2,
    double y2,
  ) {
    if (x1 == x2 && y1 == y2) return;
    rx = rx.abs();
    ry = ry.abs();
    if (rx == 0 || ry == 0) {
      lineTo(x2, y2);
      return;
    }
    final phi = angle * math.pi / 180;
    final cos = math.cos(phi), sin = math.sin(phi);
    final dx2 = (x1 - x2) / 2, dy2 = (y1 - y2) / 2;
    final x1p = cos * dx2 + sin * dy2;
    final y1p = -sin * dx2 + cos * dy2;
    final lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry);
    if (lambda > 1) {
      final s = math.sqrt(lambda);
      rx *= s;
      ry *= s;
    }
    final rx2 = rx * rx, ry2 = ry * ry;
    final num = rx2 * ry2 - rx2 * y1p * y1p - ry2 * x1p * x1p;
    final den = rx2 * y1p * y1p + ry2 * x1p * x1p;
    final coef =
        (largeArc != sweep ? 1 : -1) *
        (den == 0 ? 0 : math.sqrt(math.max(0, num / den)));
    final cxp = coef * rx * y1p / ry;
    final cyp = coef * -ry * x1p / rx;
    final cx = cos * cxp - sin * cyp + (x1 + x2) / 2;
    final cy = sin * cxp + cos * cyp + (y1 + y2) / 2;

    double vectorAngle(double ux, double uy, double vx, double vy) =>
        math.atan2(ux * vy - uy * vx, ux * vx + uy * vy);

    final ux = (x1p - cxp) / rx, uy = (y1p - cyp) / ry;
    final vx = (-x1p - cxp) / rx, vy = (-y1p - cyp) / ry;
    final theta = vectorAngle(1, 0, ux, uy);
    var delta = vectorAngle(ux, uy, vx, vy);
    if (!sweep && delta > 0) delta -= 2 * math.pi;
    if (sweep && delta < 0) delta += 2 * math.pi;

    final segments = math.max(1, (delta.abs() / (math.pi / 2)).ceil());
    final step = delta / segments;
    final t = 4 / 3 * math.tan(step / 4);
    double mapX(double px, double py) => cx + rx * cos * px - ry * sin * py;
    double mapY(double px, double py) => cy + rx * sin * px + ry * cos * py;

    var a1 = theta;
    for (var i = 0; i < segments; i++) {
      final a2 = a1 + step;
      final c1 = math.cos(a1), s1 = math.sin(a1);
      final c2 = math.cos(a2), s2 = math.sin(a2);
      final p1x = c1 - t * s1, p1y = s1 + t * c1;
      final p2x = c2 + t * s2, p2y = s2 - t * c2;
      final ex = i == segments - 1 ? x2 : mapX(c2, s2);
      final ey = i == segments - 1 ? y2 : mapY(c2, s2);
      cubicTo(
        mapX(p1x, p1y),
        mapY(p1x, p1y),
        mapX(p2x, p2y),
        mapY(p2x, p2y),
        ex,
        ey,
      );
      a1 = a2;
    }
  }

  static SvgPathCommands fromPath(Path path, {double? tolerance}) {
    final out = SvgPathCommands();
    final bounds = path.getBounds();
    final extent = math.max(bounds.width, bounds.height);
    if (extent <= 0) return out;
    final step = tolerance ?? extent / 600;
    final epsilon = step / 8;
    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      if (length <= 0) continue;
      final count = math.max(4, (length / step).ceil());
      final points = <Offset>[];
      for (var i = 0; i <= count; i++) {
        final tangent = metric.getTangentForOffset(length * i / count);
        if (tangent != null) points.add(tangent.position);
      }
      final simplified = _simplify(points, epsilon);
      if (simplified.length < 2) continue;
      out.moveTo(simplified.first.dx, simplified.first.dy);
      for (final p in simplified.skip(1)) {
        out.lineTo(p.dx, p.dy);
      }
      if (metric.isClosed) out.close();
    }
    return out;
  }

  static List<Offset> _simplify(List<Offset> points, double epsilon) {
    if (points.length < 3) return points;
    final keep = List<bool>.filled(points.length, false);
    keep[0] = true;
    keep[points.length - 1] = true;
    final stack = <(int, int)>[(0, points.length - 1)];
    while (stack.isNotEmpty) {
      final (start, end) = stack.removeLast();
      final a = points[start], b = points[end];
      final dx = b.dx - a.dx, dy = b.dy - a.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      var maxDistance = 0.0;
      var index = -1;
      for (var i = start + 1; i < end; i++) {
        final p = points[i];
        final distance = length == 0
            ? (p - a).distance
            : ((p.dx - a.dx) * dy - (p.dy - a.dy) * dx).abs() / length;
        if (distance > maxDistance) {
          maxDistance = distance;
          index = i;
        }
      }
      if (index >= 0 && maxDistance > epsilon) {
        keep[index] = true;
        stack
          ..add((start, index))
          ..add((index, end));
      }
    }
    return [
      for (var i = 0; i < points.length; i++)
        if (keep[i]) points[i],
    ];
  }
}

SvgPathCommands parseSvgPathData(String source) {
  final scanner = _PathScanner(source);
  final out = SvgPathCommands();
  var x = 0.0, y = 0.0;
  var startX = 0.0, startY = 0.0;
  double? ctrlX, ctrlY;
  var lastWasCubic = false, lastWasQuad = false;
  String? command;

  while (!scanner.done) {
    final letter = scanner.command();
    if (letter != null) {
      command = letter;
    } else if (command == null || !scanner.atNumber) {
      scanner.skipChar();
      continue;
    }

    final cmd = command;
    final relative = cmd.toLowerCase() == cmd;
    final ox = relative ? x : 0.0, oy = relative ? y : 0.0;
    var cubic = false, quad = false;

    switch (cmd.toUpperCase()) {
      case 'M':
        x = ox + scanner.number();
        y = oy + scanner.number();
        startX = x;
        startY = y;
        out.moveTo(x, y);
        command = relative ? 'l' : 'L';
      case 'L':
        x = ox + scanner.number();
        y = oy + scanner.number();
        out.lineTo(x, y);
      case 'H':
        x = ox + scanner.number();
        out.lineTo(x, y);
      case 'V':
        y = oy + scanner.number();
        out.lineTo(x, y);
      case 'C':
        final x1 = ox + scanner.number(), y1 = oy + scanner.number();
        final x2 = ox + scanner.number(), y2 = oy + scanner.number();
        x = ox + scanner.number();
        y = oy + scanner.number();
        out.cubicTo(x1, y1, x2, y2, x, y);
        ctrlX = x2;
        ctrlY = y2;
        cubic = true;
      case 'S':
        final x1 = lastWasCubic ? 2 * x - ctrlX! : x;
        final y1 = lastWasCubic ? 2 * y - ctrlY! : y;
        final x2 = ox + scanner.number(), y2 = oy + scanner.number();
        x = ox + scanner.number();
        y = oy + scanner.number();
        out.cubicTo(x1, y1, x2, y2, x, y);
        ctrlX = x2;
        ctrlY = y2;
        cubic = true;
      case 'Q':
        final x1 = ox + scanner.number(), y1 = oy + scanner.number();
        x = ox + scanner.number();
        y = oy + scanner.number();
        out.quadTo(x1, y1, x, y);
        ctrlX = x1;
        ctrlY = y1;
        quad = true;
      case 'T':
        final x1 = lastWasQuad ? 2 * x - ctrlX! : x;
        final y1 = lastWasQuad ? 2 * y - ctrlY! : y;
        x = ox + scanner.number();
        y = oy + scanner.number();
        out.quadTo(x1, y1, x, y);
        ctrlX = x1;
        ctrlY = y1;
        quad = true;
      case 'A':
        final rx = scanner.number(), ry = scanner.number();
        final angle = scanner.number();
        final largeArc = scanner.flag();
        final sweep = scanner.flag();
        final ex = ox + scanner.number(), ey = oy + scanner.number();
        out.arcTo(x, y, rx, ry, angle, largeArc, sweep, ex, ey);
        x = ex;
        y = ey;
      case 'Z':
        out.close();
        x = startX;
        y = startY;
        command = null;
      default:
        command = null;
    }
    lastWasCubic = cubic;
    lastWasQuad = quad;
  }
  return out;
}

class _PathScanner {
  _PathScanner(this.source);

  final String source;
  int index = 0;

  static const _commands = 'MmZzLlHhVvCcSsQqTtAa';

  void _skipSeparators() {
    while (index < source.length) {
      final c = source.codeUnitAt(index);
      if (c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D || c == 0x2C) {
        index++;
      } else {
        break;
      }
    }
  }

  bool get done {
    _skipSeparators();
    return index >= source.length;
  }

  bool get atNumber {
    _skipSeparators();
    if (index >= source.length) return false;
    final c = source.codeUnitAt(index);
    return (c >= 0x30 && c <= 0x39) || c == 0x2D || c == 0x2B || c == 0x2E;
  }

  void skipChar() => index++;

  String? command() {
    _skipSeparators();
    if (index >= source.length) return null;
    final c = source[index];
    if (!_commands.contains(c)) return null;
    index++;
    return c;
  }

  bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  double number() {
    _skipSeparators();
    final start = index;
    if (index < source.length &&
        (source.codeUnitAt(index) == 0x2D ||
            source.codeUnitAt(index) == 0x2B)) {
      index++;
    }
    var digits = 0;
    while (index < source.length && _isDigit(source.codeUnitAt(index))) {
      index++;
      digits++;
    }
    if (index < source.length && source.codeUnitAt(index) == 0x2E) {
      index++;
      while (index < source.length && _isDigit(source.codeUnitAt(index))) {
        index++;
        digits++;
      }
    }
    if (digits == 0) {
      throw FormatException('Expected a number', source, start);
    }
    if (index < source.length &&
        (source.codeUnitAt(index) == 0x65 ||
            source.codeUnitAt(index) == 0x45)) {
      final mark = index;
      index++;
      if (index < source.length &&
          (source.codeUnitAt(index) == 0x2D ||
              source.codeUnitAt(index) == 0x2B)) {
        index++;
      }
      if (index < source.length && _isDigit(source.codeUnitAt(index))) {
        while (index < source.length && _isDigit(source.codeUnitAt(index))) {
          index++;
        }
      } else {
        index = mark;
      }
    }
    return double.parse(source.substring(start, index));
  }

  bool flag() {
    _skipSeparators();
    if (index >= source.length) {
      throw FormatException('Expected an arc flag', source, index);
    }
    final c = source.codeUnitAt(index);
    if (c != 0x30 && c != 0x31) {
      throw FormatException('Expected an arc flag', source, index);
    }
    index++;
    return c == 0x31;
  }
}
