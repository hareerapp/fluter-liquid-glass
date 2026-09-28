import 'dart:math' as math;
import 'dart:ui';

import 'svg_path_parser.dart';

enum SvgLineCap { butt, round, square }

enum SvgLineJoin { miter, round, bevel }

class _Polyline {
  _Polyline(this.points, this.closed);

  final List<Offset> points;
  final bool closed;
}

List<_Polyline> _flatten(SvgPathCommands commands, double step) {
  final lines = <_Polyline>[];
  var current = <Offset>[];
  var start = Offset.zero;
  var pen = Offset.zero;

  void finish(bool closed) {
    if (current.isNotEmpty) lines.add(_Polyline(current, closed));
    current = <Offset>[];
  }

  int segmentsFor(double length) =>
      (length / step).ceil().clamp(4, 256).toInt();

  commands.forEach((op, p) {
    switch (op) {
      case SvgOp.move:
        finish(false);
        pen = start = Offset(p[0], p[1]);
        current.add(pen);
      case SvgOp.line:
        if (current.isEmpty) current.add(pen);
        pen = Offset(p[0], p[1]);
        current.add(pen);
      case SvgOp.cubic:
        if (current.isEmpty) current.add(pen);
        final p0 = pen;
        final p1 = Offset(p[0], p[1]);
        final p2 = Offset(p[2], p[3]);
        final p3 = Offset(p[4], p[5]);
        final n = segmentsFor(
          (p1 - p0).distance + (p2 - p1).distance + (p3 - p2).distance,
        );
        for (var i = 1; i <= n; i++) {
          final t = i / n, u = 1 - t;
          current.add(
            p0 * (u * u * u) +
                p1 * (3 * u * u * t) +
                p2 * (3 * u * t * t) +
                p3 * (t * t * t),
          );
        }
        pen = p3;
      case SvgOp.quad:
        if (current.isEmpty) current.add(pen);
        final p0 = pen;
        final p1 = Offset(p[0], p[1]);
        final p2 = Offset(p[2], p[3]);
        final n = segmentsFor((p1 - p0).distance + (p2 - p1).distance);
        for (var i = 1; i <= n; i++) {
          final t = i / n, u = 1 - t;
          current.add(p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t));
        }
        pen = p2;
      case SvgOp.close:
        finish(true);
        pen = start;
    }
  });
  finish(false);

  return [
    for (final line in lines)
      _Polyline(_dedupe(line.points, line.closed), line.closed),
  ];
}

List<Offset> _dedupe(List<Offset> points, bool closed) {
  final out = <Offset>[];
  for (final p in points) {
    if (out.isEmpty || (out.last - p).distanceSquared > 1e-12) out.add(p);
  }
  if (closed &&
      out.length > 1 &&
      (out.first - out.last).distanceSquared < 1e-12) {
    out.removeLast();
  }
  return out;
}

void _addPolygon(SvgPathCommands out, List<Offset> points) {
  if (points.length < 3) return;
  var area = 0.0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i], b = points[(i + 1) % points.length];
    area += a.dx * b.dy - b.dx * a.dy;
  }
  if (area.abs() < 1e-12) return;
  final ordered = area > 0 ? points : points.reversed.toList();
  out.moveTo(ordered.first.dx, ordered.first.dy);
  for (final p in ordered.skip(1)) {
    out.lineTo(p.dx, p.dy);
  }
  out.close();
}

Offset _normal(Offset d) {
  final length = d.distance;
  return length == 0 ? Offset.zero : Offset(-d.dy / length, d.dx / length);
}

SvgPathCommands outlineStrokePieces(
  SvgPathCommands commands, {
  required double width,
  SvgLineCap cap = SvgLineCap.butt,
  SvgLineJoin join = SvgLineJoin.miter,
  double miterLimit = 4,
}) {
  final out = SvgPathCommands();
  if (width <= 0) return out;
  final h = width / 2;
  final step = math.max(width / 3, 1e-3);

  for (final line in _flatten(commands, step)) {
    final pts = line.points;
    if (pts.length == 1) {
      if (cap == SvgLineCap.round) {
        out.addEllipse(pts.first.dx, pts.first.dy, h, h);
      } else if (cap == SvgLineCap.square) {
        out.addRect(pts.first.dx - h, pts.first.dy - h, width, width, 0, 0);
      }
      continue;
    }

    final closed = line.closed && pts.length > 2;
    final count = closed ? pts.length : pts.length - 1;
    for (var i = 0; i < count; i++) {
      var a = pts[i];
      var b = pts[(i + 1) % pts.length];
      final d = b - a;
      final length = d.distance;
      if (length == 0) continue;
      final dir = d / length;
      if (!closed && cap == SvgLineCap.square) {
        if (i == 0) a -= dir * h;
        if (i == count - 1) b += dir * h;
      }
      final n = _normal(d) * h;
      _addPolygon(out, [a + n, b + n, b - n, a - n]);
    }

    final firstJoin = closed ? 0 : 1;
    final lastJoin = closed ? pts.length - 1 : pts.length - 2;
    for (var i = firstJoin; i <= lastJoin; i++) {
      final p = pts[i];
      final prev = pts[(i - 1 + pts.length) % pts.length];
      final next = pts[(i + 1) % pts.length];
      final d0 = p - prev, d1 = next - p;
      if (d0.distance == 0 || d1.distance == 0) continue;
      final cross = d0.dx * d1.dy - d0.dy * d1.dx;
      final dot = d0.dx * d1.dx + d0.dy * d1.dy;
      final turn = math.atan2(cross, dot).abs();
      if (turn < 1e-4) continue;
      final side = cross > 0 ? -1.0 : 1.0;
      final n0 = _normal(d0) * (h * side);
      final n1 = _normal(d1) * (h * side);
      final sharp = turn > math.pi / 18;
      if (sharp && join == SvgLineJoin.round) {
        out.addEllipse(p.dx, p.dy, h, h);
        continue;
      }
      if (sharp && join == SvgLineJoin.miter) {
        final ratio = 1 / math.cos(turn / 2);
        if (ratio <= miterLimit) {
          final bisector = n0 + n1;
          final length = bisector.distance;
          if (length > 0) {
            final tip = p + bisector / length * (h * ratio);
            _addPolygon(out, [p, p + n0, tip, p + n1]);
            continue;
          }
        }
      }
      _addPolygon(out, [p, p + n0, p + n1]);
    }

    if (!closed && cap == SvgLineCap.round) {
      out.addEllipse(pts.first.dx, pts.first.dy, h, h);
      out.addEllipse(pts.last.dx, pts.last.dy, h, h);
    }
  }
  return out;
}

Path outlineStroke(
  SvgPathCommands commands, {
  required double width,
  SvgLineCap cap = SvgLineCap.butt,
  SvgLineJoin join = SvgLineJoin.miter,
  double miterLimit = 4,
}) {
  final pieces = outlineStrokePieces(
    commands,
    width: width,
    cap: cap,
    join: join,
    miterLimit: miterLimit,
  ).toPath();
  try {
    return Path.combine(PathOperation.union, pieces, Path());
  } catch (_) {
    return pieces;
  }
}
