import 'package:flutter/painting.dart';

import 'stroke_outliner.dart';
import 'svg_document_parser.dart';
import 'svg_path_parser.dart';

SvgMatrix svgFitMatrix(
  Rect viewBox,
  Size size,
  BoxFit fit,
  Alignment alignment,
) {
  if (viewBox.isEmpty || size.isEmpty) return const SvgMatrix(0, 0, 0, 0, 0, 0);
  final fitted = applyBoxFit(fit, viewBox.size, size);
  if (fitted.source.isEmpty) return const SvgMatrix(0, 0, 0, 0, 0, 0);
  final sx = fitted.destination.width / fitted.source.width;
  final sy = fitted.destination.height / fitted.source.height;
  final scaled = Size(viewBox.width * sx, viewBox.height * sy);
  final dest = alignment.inscribe(scaled, Offset.zero & size);
  return SvgMatrix(
    sx,
    0,
    0,
    sy,
    dest.left - viewBox.left * sx,
    dest.top - viewBox.top * sy,
  );
}

final _documents = <String, SvgDocument>{};

SvgDocument cachedSvgDocument(String source) {
  final cached = _documents.remove(source);
  if (cached != null) {
    _documents[source] = cached;
    return cached;
  }
  final document = parseSvgSource(source);
  _documents[source] = document;
  if (_documents.length > 48) _documents.remove(_documents.keys.first);
  return document;
}

SvgDocument parseSvgSource(String source) {
  if (looksLikeSvgDocument(source)) return parseSvgDocument(source);
  final commands = parseSvgPathData(source);
  final drawable = SvgDrawable(
    commands: commands,
    fillType: PathFillType.nonZero,
    fill: const SvgPaintSource.color(Color(0xFF000000)),
    fillOpacity: 1,
    stroke: null,
    strokeOpacity: 1,
    strokeWidth: 0,
    cap: SvgLineCap.butt,
    join: SvgLineJoin.miter,
    miterLimit: 4,
    opacity: 1,
  );
  return SvgDocument(commands.isEmpty ? Rect.zero : drawable.path.getBounds(), [
    drawable,
  ]);
}
