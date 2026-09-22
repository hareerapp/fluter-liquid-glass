import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class GlassTrackRecognizer extends OneSequenceGestureRecognizer {
  GlassTrackRecognizer({super.debugOwner});

  static const double slop = 8;

  ValueChanged<PointerDownEvent>? onDown;
  VoidCallback? onAccept;
  ValueChanged<PointerMoveEvent>? onMove;
  ValueChanged<PointerUpEvent>? onUp;
  VoidCallback? onCancel;

  int? _pointer;
  Offset _origin = Offset.zero;
  bool _accepted = false;

  bool get accepted => _accepted;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _origin = event.position;
    _accepted = false;
    startTrackingPointer(event.pointer, event.transform);
    onDown?.call(event);
  }

  @override
  void acceptGesture(int pointer) {
    if (pointer != _pointer || _accepted) return;
    _accepted = true;
    onAccept?.call();
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer != _pointer) return;
    _pointer = null;
    stopTrackingPointer(pointer);
    onCancel?.call();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      if (!_accepted) {
        final delta = event.position - _origin;
        if (delta.dx.abs() > slop && delta.dx.abs() > delta.dy.abs()) {
          resolve(GestureDisposition.accepted);
        }
      }
      if (_pointer != null) onMove?.call(event);
    } else if (event is PointerUpEvent) {
      if (!_accepted) resolve(GestureDisposition.accepted);
      if (_pointer == null) return;
      _pointer = null;
      stopTrackingPointer(event.pointer);
      if (_accepted) {
        onUp?.call(event);
      } else {
        onCancel?.call();
      }
    } else if (event is PointerCancelEvent) {
      _pointer = null;
      resolve(GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
      onCancel?.call();
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'glass track';
}

class GlassTrackDetector extends StatelessWidget {
  const GlassTrackDetector({
    super.key,
    required this.child,
    this.enabled = true,
    this.onDown,
    this.onAccept,
    this.onMove,
    this.onUp,
    this.onCancel,
  });

  final Widget child;
  final bool enabled;
  final ValueChanged<PointerDownEvent>? onDown;
  final VoidCallback? onAccept;
  final ValueChanged<PointerMoveEvent>? onMove;
  final ValueChanged<PointerUpEvent>? onUp;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: enabled
          ? {
              GlassTrackRecognizer:
                  GestureRecognizerFactoryWithHandlers<GlassTrackRecognizer>(
                    () => GlassTrackRecognizer(debugOwner: this),
                    (r) => r
                      ..onDown = onDown
                      ..onAccept = onAccept
                      ..onMove = onMove
                      ..onUp = onUp
                      ..onCancel = onCancel,
                  ),
            }
          : const {},
      child: child,
    );
  }
}
