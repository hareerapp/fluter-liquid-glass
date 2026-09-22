// End-to-end walk through every feature of the example app.
//
// Run on a device / simulator:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/feature_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_design/liquid_design.dart';
import 'package:liquid_design_example/common.dart';
import 'package:liquid_design_example/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(String name) async {
    try {
      await binding.takeScreenshot(name);
    } catch (_) {
      // Screenshots need the extended driver; the checks still run.
    }
  }

  Future<void> settle(WidgetTester t) async {
    await t.pumpAndSettle();
    // Let native views be created.
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await t.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester t, IconData icon) async {
    // A collapsed bar needs one tap to expand first.
    final bar = find.byType(LiquidGlassNavigationBar);
    if (t.widget<LiquidGlassNavigationBar>(bar).collapsed) {
      await t.tapAt(t.getTopLeft(bar) + const Offset(30, 30));
      await settle(t);
    }
    await t.tap(find.byIcon(icon).last, warnIfMissed: false);
    await settle(t);
  }

  Finder title(String text) => find.descendant(
    of: find.byType(LiquidGlassAppBar),
    matching: find.text(text),
  );

  Future<void> scrollTo(WidgetTester t, Finder f) async {
    await t.scrollUntilVisible(
      f,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(t);
  }

  testWidgets('every feature', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await settle(tester);
    await binding.convertFlutterSurfaceToImage();
    await settle(tester);
    final service = LiquidGlassService.instance;

    // Capabilities.
    final caps = await tester.runAsync(service.ensureInitialized);
    debugPrint('FEATURE capabilities: $caps');
    expect(caps!.liquidGlass, isTrue);
    await shot('01_controls');

    // Controls: tappable children inside glass.
    for (final (finder, message) in [
      (find.byIcon(Icons.favorite_rounded), 'IconButton pressed'),
      (find.text('InkWell'), 'InkWell tap'),
      (find.text('TextButton'), 'TextButton pressed'),
    ]) {
      await scrollTo(tester, finder.first);
      await tester.tap(finder.first, warnIfMissed: false);
      await tester.pump();
      expect(title(message), findsOneWidget, reason: message);
      await settle(tester);
    }
    await scrollTo(tester, find.text('Hold me'));
    await tester.longPress(find.text('Hold me'), warnIfMissed: false);
    await tester.pump();
    expect(title('Long press'), findsOneWidget);
    await settle(tester);
    debugPrint('FEATURE controls: ok');

    // Components.
    await openTab(tester, Icons.widgets_rounded);
    await shot('02_components');
    for (final (label, message) in [
      ('Glass', 'Glass button'),
      ('Tinted', 'Tinted button'),
      ('Prominent', 'Prominent button'),
    ]) {
      await scrollTo(tester, find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
      expect(title(message), findsOneWidget, reason: label);
      await settle(tester);
    }
    // Let the previous message go (real-time timer in the demo).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1700)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disabled').first, warnIfMissed: false);
    await tester.pump();
    expect(title('Components'), findsOneWidget, reason: 'disabled button');

    await tester.tap(find.bySemanticsLabel('Add'), warnIfMissed: false);
    await tester.pump();
    expect(title('Add'), findsOneWidget);
    await settle(tester);

    // Segmented control.
    await scrollTo(tester, find.text('Year'));
    Finder segmented() => find.byType(LiquidGlassSegmentedControl<String>);
    await tester.tap(find.text('Year'), warnIfMissed: false);
    await settle(tester);
    expect(
      tester
          .widget<LiquidGlassSegmentedControl<String>>(segmented().first)
          .value,
      'year',
    );

    // Switch & slider.
    await scrollTo(tester, find.byType(LiquidGlassSwitch).first);
    final wifi = find.byType(LiquidGlassSwitch).first;
    final before = tester.widget<LiquidGlassSwitch>(wifi).value;
    await tester.tap(wifi);
    await settle(tester);
    expect(tester.widget<LiquidGlassSwitch>(wifi).value, !before);
    final slider = find.byType(LiquidGlassSlider).first;
    await scrollTo(tester, slider);
    final v0 = tester.widget<LiquidGlassSlider>(slider).value;
    await tester.drag(slider, const Offset(-80, 0));
    await settle(tester);
    expect(tester.widget<LiquidGlassSlider>(slider).value, lessThan(v0));
    await shot('03_controls_used');
    debugPrint('FEATURE components: ok');

    // Search bar: focus shows the close button, typing, closing.
    await scrollTo(tester, find.byType(LiquidGlassSearchBar));
    await tester.tap(find.byType(TextField));
    await settle(tester);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'sun');
    await settle(tester);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    await shot('04_search');
    await tester.tap(find.byIcon(Icons.close_rounded));
    await settle(tester);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('sun'), findsNothing);
    debugPrint('FEATURE search: ok');

    // Bottom sheet.
    await scrollTo(tester, find.text('Open sheet'));
    await tester.tap(find.text('Open sheet'));
    await settle(tester);
    expect(find.byType(LiquidGlassSheet), findsOneWidget);
    await shot('05_sheet');
    await tester.tap(find.text('Copy'));
    await settle(tester);
    expect(find.byType(LiquidGlassSheet), findsNothing);
    debugPrint('FEATURE sheet: ok');

    // App bar page: back button + scroll edge.
    await tester.tap(find.text('Push app bar page'));
    await settle(tester);
    expect(find.text('Photos'), findsOneWidget);
    await tester.drag(find.byType(GridView), const Offset(0, -400));
    await settle(tester);
    await shot('06_app_bar_page');
    await tester.tap(find.bySemanticsLabel('Back'), warnIfMissed: false);
    await settle(tester);
    expect(find.text('Photos'), findsNothing);
    debugPrint('FEATURE app bar: ok');

    // Groups: morph open / close.
    await openTab(tester, Icons.bubble_chart_rounded);
    await tester.tap(find.byIcon(Icons.add_rounded), warnIfMissed: false);
    await settle(tester);
    await shot('07_morph_open');
    await tester.tap(
      find.byIcon(Icons.photo_camera_rounded),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(title('Camera'), findsOneWidget);
    await settle(tester);
    debugPrint('FEATURE groups: ok');

    // Gallery tabs.
    await openTab(tester, Icons.category_rounded);
    for (final tab in ['Overrides', 'Theme', 'Shapes']) {
      await tester.tap(find.text(tab), warnIfMissed: false);
      await settle(tester);
      expect(tester.takeException(), isNull);
    }
    await shot('08_gallery');
    debugPrint('FEATURE gallery: ok');

    // Settings through the service.
    await openTab(tester, Icons.settings_rounded);
    service.setStyle(LiquidGlassStyle.clear);
    service.setTint(Colors.blue, opacity: 0.4);
    service.setOpacity(0.7);
    await settle(tester);
    await shot('09_settings_applied');
    service.setEnabled(false);
    await settle(tester);
    await shot('10_disabled');
    service.setEnabled(true);
    themeMode.value = ThemeMode.dark;
    await settle(tester);
    await shot('11_dark');
    themeMode.value = ThemeMode.light;
    rtlLayout.value = true;
    await settle(tester);
    await shot('12_rtl');
    rtlLayout.value = false;
    service.reset();
    await settle(tester);
    expect(service.settings, const LiquidGlassSettings());
    debugPrint('FEATURE settings: ok');

    // Collapse on scroll, and the setting that disables it.
    await openTab(tester, Icons.touch_app_rounded);
    final list = find.byType(Scrollable).first;
    // Back to the top, then a finger-like scroll down.
    await tester.fling(list, const Offset(0, 3000), 4000);
    await settle(tester);
    await tester.timedDrag(
      list,
      const Offset(0, -400),
      const Duration(milliseconds: 500),
    );
    await settle(tester);
    expect(
      tester
          .widget<LiquidGlassNavigationBar>(
            find.byType(LiquidGlassNavigationBar),
          )
          .collapsed,
      isTrue,
    );
    await shot('13_collapsed');
    service.setCollapseOnScroll(false);
    await settle(tester);
    await tester.timedDrag(
      list,
      const Offset(0, -300),
      const Duration(milliseconds: 500),
    );
    await settle(tester);
    expect(find.text('Components'), findsWidgets);
    service.reset();
    await settle(tester);
    debugPrint('FEATURE collapse: ok');
    expect(tester.takeException(), isNull);
  });
}
