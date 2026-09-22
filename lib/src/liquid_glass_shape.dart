import 'dart:math' as math;

import 'package:flutter/material.dart' show InkResponse;
import 'package:flutter/widgets.dart';

enum _ShapeKind { capsule, roundedRect, rect }

@immutable
class LiquidGlassShape {
  const LiquidGlassShape._(this._kind, this.radius);

  const LiquidGlassShape.capsule() : this._(_ShapeKind.capsule, 0);

  const LiquidGlassShape.circle() : this._(_ShapeKind.capsule, 0);

  const LiquidGlassShape.roundedRect(double radius)
    : this._(_ShapeKind.roundedRect, radius);

  const LiquidGlassShape.rect() : this._(_ShapeKind.rect, 0);

  final _ShapeKind _kind;

  final double radius;

  bool get isCapsule => _kind == _ShapeKind.capsule;

  double resolveRadius(Size size) {
    final maxRadius = math.min(size.width, size.height) / 2;
    return switch (_kind) {
      _ShapeKind.capsule => maxRadius,
      _ShapeKind.roundedRect => math.min(radius, maxRadius),
      _ShapeKind.rect => 0,
    };
  }

  RRect toRRect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(resolveRadius(rect.size)));

  Map<String, Object> toMap() => {'shape': _kind.name, 'radius': radius};

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
      other.radius == radius;

  @override
  int get hashCode => Object.hash(_kind, radius);

  @override
  String toString() => switch (_kind) {
    _ShapeKind.capsule => 'LiquidGlassShape.capsule()',
    _ShapeKind.roundedRect => 'LiquidGlassShape.roundedRect($radius)',
    _ShapeKind.rect => 'LiquidGlassShape.rect()',
  };
}
