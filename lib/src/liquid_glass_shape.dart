import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart' show InkResponse;
import 'package:flutter/widgets.dart';

import 'svg/svg_fit.dart';
import 'svg/svg_path_parser.dart';

enum _ShapeKind { capsule, roundedRect, rect, path }

@immutable
/// The outline of a glass surface: capsule, circle, rounded rectangle,
/// rectangle, or any path or SVG.
class LiquidGlassShape {
  const LiquidGlassShape._(
    this._kind,
    this.radius, [
    this._geometry,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  ]);

  /// A pill shape with fully rounded ends. The default.
  const LiquidGlassShape.capsule() : this._(_ShapeKind.capsule, 0);

  /// A circle, for square children.
  const LiquidGlassShape.circle() : this._(_ShapeKind.capsule, 0);

  /// A rectangle with corners of [radius].
  const LiquidGlassShape.roundedRect(double radius)
    : this._(_ShapeKind.roundedRect, radius);

  /// A rectangle with square corners.
  const LiquidGlassShape.rect() : this._(_ShapeKind.rect, 0);

  /// A shape that follows [path], scaled into the box with [fit] and [alignment].
  factory LiquidGlassShape.path(
    Path path, {
    Rect? viewBox,
    PathFillType fillType = PathFillType.nonZero,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
  }) {
    final commands = SvgPathCommands.fromPath(path);
    final box = viewBox ?? path.getBounds();
    final geometry = _PathGeometry(
      commands: commands,
      viewBox: box,
      fillType: fillType,
      label: 'path',
    );
    return LiquidGlassShape._(_ShapeKind.path, 0, geometry, fit, alignment);
  }

  /// A shape that follows an SVG document or raw path data.
  ///
  /// Stroke-only artwork is turned into a filled outline when [strokeToFill] is true.
  factory LiquidGlassShape.svg(
    String svgOrPathData, {
    Rect? viewBox,
    PathFillType? fillType,
    bool strokeToFill = true,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
  }) {
    final key = '$strokeToFill|$viewBox|${fillType?.name}|$svgOrPathData';
    final geometry = _PathGeometry.cache.lookup(key, () {
      final document = cachedSvgDocument(svgOrPathData);
      final silhouette = document.silhouette(strokeToFill: strokeToFill);
      return _PathGeometry(
        commands: silhouette.commands,
        viewBox: viewBox ?? document.viewBox,
        fillType: fillType ?? silhouette.fillType,
        label: 'svg',
        source: key,
      );
    });
    return LiquidGlassShape._(_ShapeKind.path, 0, geometry, fit, alignment);
  }

  final _ShapeKind _kind;

  /// Corner radius of [LiquidGlassShape.roundedRect].
  final double radius;

  final _PathGeometry? _geometry;

  /// How a path or SVG shape fits its box.
  final BoxFit fit;

  /// Where a path or SVG shape sits in its box.
  final Alignment alignment;

  /// Whether this is a capsule or circle.
  bool get isCapsule => _kind == _ShapeKind.capsule;

  /// Whether this shape comes from a path or SVG.
  bool get isPath => _kind == _ShapeKind.path;

  /// The source coordinate box of a path or SVG shape.
  Rect get viewBox => _geometry?.viewBox ?? Rect.zero;

  /// Width divided by height of [viewBox].
  double get aspectRatio {
    final box = viewBox;
    return box.height <= 0 || box.width <= 0 ? 1 : box.width / box.height;
  }

  /// Fill rule of a path or SVG shape.
  PathFillType get fillType => _geometry?.fillType ?? PathFillType.nonZero;

  /// The outline scaled into a box of [size].
  Path resolvePath(Size size, {BoxFit? fit, Alignment? alignment}) {
    final geometry = _geometry;
    if (geometry == null) {
      return Path()..addRRect(toRRect(Offset.zero & size));
    }
    final matrix = svgFitMatrix(
      geometry.viewBox,
      size,
      fit ?? this.fit,
      alignment ?? this.alignment,
    );
    return geometry.path.transform(matrix.toMatrix4())
      ..fillType = geometry.fillType;
  }

  /// The outline placed in [rect].
  Path toPath(Rect rect) => isPath
      ? resolvePath(rect.size).shift(rect.topLeft)
      : (Path()..addRRect(toRRect(rect)));

  /// Corner radius used for a box of [size].
  double resolveRadius(Size size) {
    final maxRadius = math.min(size.width, size.height) / 2;
    return switch (_kind) {
      _ShapeKind.capsule => maxRadius,
      _ShapeKind.roundedRect => math.min(radius, maxRadius),
      _ShapeKind.rect || _ShapeKind.path => 0,
    };
  }

  /// The rounded rectangle for [rect].
  RRect toRRect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(resolveRadius(rect.size)));

  /// The shape encoded for the native side.
  Map<String, Object> toMap() {
    final geometry = _geometry;
    if (geometry == null) return {'shape': _kind.name, 'radius': radius};
    return {
      'shape': 'path',
      'radius': 0,
      'path': geometry.encoded,
      'fillRule': geometry.fillType == PathFillType.evenOdd
          ? 'evenOdd'
          : 'nonZero',
      'fit': fit.name,
      'alignX': alignment.x,
      'alignY': alignment.y,
      'viewBoxWidth': geometry.viewBox.width,
      'viewBoxHeight': geometry.viewBox.height,
    };
  }

  /// Reads a shape from a child's decoration or clip, or returns null.
  static LiquidGlassShape? detect(Widget child) {
    child = _unwrap(child);
    Decoration? decoration;
    if (child is Container) {
      decoration = child.decoration;
    } else if (child is DecoratedBox) {
      decoration = child.decoration;
    } else if (child is ClipOval) {
      return const LiquidGlassShape.circle();
    } else if (child is ClipRRect) {
      return _fromBorderRadius(child.borderRadius);
    }

    if (decoration is BoxDecoration) {
      if (decoration.shape == BoxShape.circle) {
        return const LiquidGlassShape.circle();
      }
      final borderRadius = decoration.borderRadius;
      return borderRadius == null
          ? const LiquidGlassShape.rect()
          : _fromBorderRadius(borderRadius);
    }
    if (decoration is ShapeDecoration) {
      final border = decoration.shape;
      if (border is CircleBorder) return const LiquidGlassShape.circle();
      if (border is StadiumBorder) return const LiquidGlassShape.capsule();
      if (border is RoundedRectangleBorder) {
        return _fromBorderRadius(border.borderRadius);
      }
      if (border is ContinuousRectangleBorder) {
        return _fromBorderRadius(border.borderRadius);
      }
    }
    return null;
  }

  static Widget _unwrap(Widget widget) {
    for (var depth = 0; depth < 8; depth++) {
      final Widget? inner = switch (widget) {
        GestureDetector(:final child) => child,
        InkResponse(:final child) => child,
        Semantics(:final child) => child,
        MouseRegion(:final child) => child,
        Listener(:final child) => child,
        _ => null,
      };
      if (inner == null) return widget;
      widget = inner;
    }
    return widget;
  }

  static LiquidGlassShape _fromBorderRadius(BorderRadiusGeometry radius) {
    final value = radius.resolve(TextDirection.ltr).topLeft.x;
    return value <= 0
        ? const LiquidGlassShape.rect()
        : LiquidGlassShape.roundedRect(value);
  }

  @override
  bool operator ==(Object other) =>
      other is LiquidGlassShape &&
      other._kind == _kind &&
      other.radius == radius &&
      other._geometry == _geometry &&
      other.fit == fit &&
      other.alignment == alignment;

  @override
  int get hashCode => _geometry == null
      ? Object.hash(_kind, radius)
      : Object.hash(_kind, _geometry, fit, alignment);

  @override
  String toString() => switch (_kind) {
    _ShapeKind.capsule => 'LiquidGlassShape.capsule()',
    _ShapeKind.roundedRect => 'LiquidGlassShape.roundedRect($radius)',
    _ShapeKind.rect => 'LiquidGlassShape.rect()',
    _ShapeKind.path =>
      'LiquidGlassShape.${_geometry!.label}('
          '#${_geometry.hashCode.toUnsigned(32).toRadixString(16)}, '
          'viewBox: ${_geometry.viewBox}, fillType: ${_geometry.fillType.name})',
  };
}

class _GeometryCache {
  final _entries = <String, _PathGeometry>{};

  _PathGeometry lookup(String key, _PathGeometry Function() create) {
    final cached = _entries.remove(key);
    if (cached != null) {
      _entries[key] = cached;
      return cached;
    }
    final geometry = create();
    _entries[key] = geometry;
    if (_entries.length > 64) _entries.remove(_entries.keys.first);
    return geometry;
  }
}

class _PathGeometry {
  _PathGeometry({
    required this.commands,
    required this.viewBox,
    required this.fillType,
    required this.label,
    this.source,
  });

  static final cache = _GeometryCache();

  final SvgPathCommands commands;
  final Rect viewBox;
  final PathFillType fillType;
  final String label;
  final String? source;

  late final List<double> encoded = List.unmodifiable(
    commands.normalized(viewBox).data,
  );

  late final Path path = commands.toPath(fillType: fillType);

  late final int _hash = source != null
      ? Object.hash(source, fillType, viewBox)
      : Object.hash(Object.hashAll(encoded), fillType, viewBox);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _PathGeometry ||
        other.fillType != fillType ||
        other.viewBox != viewBox ||
        other._hash != _hash) {
      return false;
    }
    if (source != null && other.source != null) return source == other.source;
    return listEquals(encoded, other.encoded);
  }

  @override
  int get hashCode => _hash;
}
