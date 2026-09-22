import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';
import 'package:liquid_design_example/main.dart';

void main() {
  testWidgets('every demo page builds', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    expect(find.byType(LiquidGlass), findsWidgets);

    for (final icon in [
      Icons.widgets_rounded,
      Icons.bubble_chart_rounded,
      Icons.category_rounded,
      Icons.settings_rounded,
    ]) {
      await tester.tap(find.byIcon(icon), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(LiquidGlass), findsWidgets);
    }

    // Quick sheet opens from the floating glass button.
    await tester.tap(find.byIcon(Icons.bolt_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Quick settings'), findsOneWidget);
  });
}
