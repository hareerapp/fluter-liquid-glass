import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';

void main() {
  tearDown(LiquidGlassService.instance.reset);

  group('LiquidGlassShape.detect', () {
    test('circle container', () {
      expect(
        LiquidGlassShape.detect(
          Container(decoration: const BoxDecoration(shape: BoxShape.circle)),
        ),
        const LiquidGlassShape.circle(),
      );
    });

    test('rounded container', () {
      expect(
        LiquidGlassShape.detect(
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const LiquidGlassShape.roundedRect(12),
      );
    });

    test('looks through tap wrappers', () {
      expect(
        LiquidGlassShape.detect(
          GestureDetector(
            onTap: () {},
            child: InkWell(
              onTap: () {},
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle),
              ),
            ),
          ),
        ),
        const LiquidGlassShape.circle(),
      );
    });

    test('plain container has no shape', () {
      expect(LiquidGlassShape.detect(Container(width: 30)), isNull);
    });

    test('capsule radius is half the short side', () {
      expect(
        const LiquidGlassShape.capsule().resolveRadius(const Size(200, 50)),
        25,
      );
    });
  });

  group('LiquidGlassService', () {
    test('notifies on change only', () {
      var calls = 0;
      void listener() => calls++;
      final service = LiquidGlassService.instance..addListener(listener);
      service.setOpacity(0.5);
      service.setOpacity(0.5);
      service.setTint(Colors.blue, opacity: 0.4);
      service.setTint(null);
      service.removeListener(listener);

      expect(calls, 3);
      expect(service.settings.opacity, 0.5);
      expect(service.settings.tintColor, isNull);
      expect(service.settings.tintOpacity, 0.4);
    });
  });

  testWidgets('child taps work while the glass animates', (tester) async {
    LiquidGlassService.instance.setFallback(LiquidGlassFallback.frosted);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: LiquidGlass(
            child: IconButton(
              onPressed: () => taps++,
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  group('LiquidGlass off iOS', () {
    testWidgets('renders the child untouched by default', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: LiquidGlass(
              child: GestureDetector(
                onTap: () => taps++,
                child: const SizedBox(width: 40, height: 40, child: Text('x')),
              ),
            ),
          ),
        ),
      );
      expect(find.text('x'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);

      await tester.tap(find.text('x'));
      expect(taps, 1);
    });

    testWidgets('frosted fallback follows the service', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: LiquidGlass(child: SizedBox(width: 120, height: 44)),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);

      LiquidGlassService.instance.setFallback(LiquidGlassFallback.frosted);
      await tester.pump();
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(
        tester.widget<BackdropFilter>(find.byType(BackdropFilter)).filter,
        isA<ImageFilter>(),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(LiquidGlass)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(40, 10));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('disabled renders only the child', (tester) async {
      LiquidGlassService.instance
        ..setFallback(LiquidGlassFallback.frosted)
        ..setEnabled(false);
      await tester.pumpWidget(
        const MaterialApp(home: LiquidGlass(child: SizedBox(width: 10))),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });
}
