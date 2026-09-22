import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_design_example/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> wait(WidgetTester t, int ms) =>
      t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));

  testWidgets('groups benchmark', (tester) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    await tester.pumpWidget(const DemoApp());
    await wait(tester, 1000);
    await tester.tap(
      find.byIcon(Icons.bubble_chart_rounded).last,
      warnIfMissed: false,
    );
    await wait(tester, 800);
    await tester.scrollUntilVisible(
      find.text('Run benchmark'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await wait(tester, 800);
    for (final (label, prefix) in [
      ('Grouped (1 view)', 'Grouped:'),
      ('Individual (40 views)', 'Individual:'),
      ('Grouped (1 view)', 'Grouped:'),
    ]) {
      await tester.tap(find.text(label), warnIfMissed: false);
      await wait(tester, 1000);
      await tester.tap(find.text('Run benchmark'), warnIfMissed: false);
      await wait(tester, 7500);
      await tester.pump();
      for (final t in tester.widgetList<Text>(find.textContaining(prefix))) {
        debugPrint('BENCH ${t.data}');
      }
    }
  });
}
