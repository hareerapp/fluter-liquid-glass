import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_design/liquid_design.dart';
import 'package:liquid_design_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Frame by frame, like a device (glass springs never jump ahead).
  Future<void> frames(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('native glass builds and reacts to touch', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();
    // Native glass views: UiKitView on iOS, AppKitView on macOS.
    expect(
      find.byWidgetPredicate((w) => w is UiKitView || w is AppKitView),
      findsWidgets,
    );
    final caps = await LiquidGlassService.instance.ensureInitialized();
    debugPrint('CAPS $caps');
    expect(caps.osVersion, isNotNull);

    final button = find.ancestor(
      of: find.byIcon(Icons.bolt_rounded),
      matching: find.byType(LiquidGlass),
    );
    Matrix4 transform() => tester
        .widget<Transform>(
          find.descendant(of: button, matching: find.byType(Transform)).first,
        )
        .transform;

    // Hold: the glass grows.
    final gesture = await tester.startGesture(tester.getCenter(button));
    await frames(tester, 25);
    final held = transform();
    expect(held.getMaxScaleOnAxis(), greaterThan(1.1));

    // Drag: it follows the finger with resistance.
    await gesture.moveBy(const Offset(-60, 0));
    await frames(tester, 25);
    expect(transform().getTranslation().x, lessThan(held.getTranslation().x));

    // Release: springs back to rest (the drag cancels the tap, as on iOS).
    await gesture.up();
    await tester.pumpAndSettle();
    // Back to rest (on desktop a real mouse over it may keep a slight hover).
    expect(transform().getMaxScaleOnAxis(), lessThan(1.03));

    // The child's own IconButton handles the tap.
    await tester.ensureVisible(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pump();
    expect(find.text('IconButton pressed'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Scrolling back up expands the collapsed tab bar again.
    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, 1500),
      3000,
    );
    await tester.pumpAndSettle();

    // Every page builds.
    for (final icon in [
      Icons.widgets_rounded,
      Icons.bubble_chart_rounded,
      Icons.category_rounded,
      Icons.settings_rounded,
    ]) {
      await tester.tap(find.byIcon(icon), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
