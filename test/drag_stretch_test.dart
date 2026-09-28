import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';

final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

Widget fixed(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Matrix4 glassTransform(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(LiquidGlass),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform;

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform_views,
          (_) async => null,
        );
  });
  tearDown(LiquidGlassService.instance.reset);

  testWidgets('a small drag still counts as a tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      fixed(
        LiquidGlassButton(onPressed: () => taps++, child: const Text('Go')),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Go')),
    );
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  }, variant: ios);

  testWidgets('dragging far away cancels the tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      fixed(
        LiquidGlassButton(onPressed: () => taps++, child: const Text('Go')),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Go')),
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 0);
  }, variant: ios);

  testWidgets('coming back inside restores the tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      fixed(
        LiquidGlassButton(onPressed: () => taps++, child: const Text('Go')),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Go')),
    );
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -190));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  }, variant: ios);

  testWidgets('glass follows and stretches toward the finger', (tester) async {
    await tester.pumpWidget(
      fixed(
        LiquidGlassButton.icon(onPressed: () {}, icon: const Icon(Icons.add)),
      ),
    );
    final start = tester.getCenter(find.byIcon(Icons.add));
    final gesture = await tester.startGesture(start);
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await frames(tester, 40);
    final m = glassTransform(tester);
    final sx = m.storage[0], sy = m.storage[5];
    final shift = m.storage[13] + (sy - 1) * 24;
    expect(sy, greaterThan(sx * 1.15));
    expect(shift, greaterThan(12));

    await gesture.moveBy(const Offset(0, 200));
    await frames(tester, 40);
    final away = glassTransform(tester);
    expect(away.storage[5], lessThan(sy));

    await gesture.up();
    await tester.pumpAndSettle();
    final rest = glassTransform(tester);
    expect(rest.storage[5], closeTo(1, 0.01));
    expect(rest.storage[0], closeTo(1, 0.01));
  }, variant: ios);

  testWidgets('a vertical drag in a list scrolls instead of tapping', (
    tester,
  ) async {
    var taps = 0;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: scroll,
            children: [
              const SizedBox(height: 200),
              Center(
                child: LiquidGlassButton(
                  onPressed: () => taps++,
                  child: const Text('Go'),
                ),
              ),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    await tester.drag(find.text('Go'), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(scroll.offset, greaterThan(0));
  }, variant: ios);
}
