import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';

void main() {
  tearDown(LiquidGlassService.instance.reset);

  Widget bar(int index, ValueChanged<int> onTap) => MaterialApp(
    home: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 400,
        child: LiquidGlassNavigationBar(
          currentIndex: index,
          onTap: onTap,
          items: const [
            LiquidGlassNavItem(icon: Icon(Icons.home), label: 'Home'),
            LiquidGlassNavItem(icon: Icon(Icons.search), label: 'Search'),
            LiquidGlassNavItem(icon: Icon(Icons.person), label: 'Me'),
            LiquidGlassNavItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    ),
  );

  testWidgets('tapping a tab selects it', (tester) async {
    int? tapped;
    await tester.pumpWidget(bar(0, (i) => tapped = i));
    await tester.tap(find.text('Me'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tapped, 2);
  });

  testWidgets('dragging across the bar snaps to the tab under the finger', (
    tester,
  ) async {
    int? tapped;
    for (final fallback in LiquidGlassFallback.values) {
      LiquidGlassService.instance.setFallback(fallback);
      tapped = null;
      await tester.pumpWidget(bar(0, (i) => tapped = i));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Home')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(tester.getCenter(find.text('Search')));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(tester.getCenter(find.text('Settings')));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tapped, 3, reason: 'fallback: $fallback');
    }
  });

  testWidgets('tapping the selected tab does not fire onTap', (tester) async {
    var calls = 0;
    await tester.pumpWidget(bar(1, (_) => calls++));
    await tester.tap(find.text('Search'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(calls, 0);
  });
}
