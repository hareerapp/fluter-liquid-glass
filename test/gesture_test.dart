import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';

Widget inList(Widget child, {ScrollController? controller}) => MaterialApp(
  home: Scaffold(
    body: ListView(
      controller: controller,
      children: [
        const SizedBox(height: 200),
        Center(child: SizedBox(width: 300, child: child)),
        const SizedBox(height: 2000),
      ],
    ),
  ),
);

Widget navBar({
  required int index,
  required ValueChanged<int> onTap,
  ValueChanged<int>? onReselect,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 300,
        child: LiquidGlassNavigationBar(
          currentIndex: index,
          onTap: onTap,
          onReselect: onReselect,
          items: const [
            LiquidGlassNavItem(icon: Icon(Icons.home), label: 'Home'),
            LiquidGlassNavItem(icon: Icon(Icons.search), label: 'Search'),
            LiquidGlassNavItem(icon: Icon(Icons.person), label: 'Me'),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  tearDown(LiquidGlassService.instance.reset);

  group('inside a scroll view', () {
    testWidgets('scrolling over a switch does not toggle it', (tester) async {
      final scroll = ScrollController();
      var value = false;
      await tester.pumpWidget(
        inList(
          StatefulBuilder(
            builder: (context, setState) => LiquidGlassSwitch(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          controller: scroll,
        ),
      );
      await tester.drag(find.byType(LiquidGlassSwitch), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(value, isFalse);
      expect(scroll.offset, greaterThan(0));
    });

    testWidgets('tapping a switch in a list still toggles it', (tester) async {
      var value = false;
      await tester.pumpWidget(
        inList(
          StatefulBuilder(
            builder: (context, setState) => LiquidGlassSwitch(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(LiquidGlassSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets('scrolling over a slider does not change it', (tester) async {
      final changes = <double>[];
      var starts = 0;
      await tester.pumpWidget(
        inList(
          LiquidGlassSlider(
            value: 0.5,
            onChanged: changes.add,
            onChangeStart: (_) => starts++,
          ),
        ),
      );
      final slider = find.byType(LiquidGlassSlider);
      await tester.dragFrom(
        tester.getTopLeft(slider) + const Offset(40, 22),
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(starts, 0);
    });

    testWidgets('dragging a slider sideways in a list changes it', (
      tester,
    ) async {
      final changes = <double>[];
      await tester.pumpWidget(
        inList(LiquidGlassSlider(value: 0.5, onChanged: changes.add)),
      );
      await tester.drag(
        find.byType(LiquidGlassSlider),
        const Offset(100, 0),
        touchSlopX: 0,
      );
      await tester.pumpAndSettle();
      expect(changes, isNotEmpty);
      expect(changes.last, greaterThan(0.5));
    });

    testWidgets('scrolling over a segmented control does not select', (
      tester,
    ) async {
      var selected = 'a';
      await tester.pumpWidget(
        inList(
          LiquidGlassSegmentedControl<String>(
            value: selected,
            onValueChanged: (v) => selected = v,
            children: const {'a': Text('A'), 'b': Text('B'), 'c': Text('C')},
          ),
        ),
      );
      await tester.drag(
        find.text('C'),
        const Offset(0, -150),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(selected, 'a');

      await tester.tap(find.text('C'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, 'c');
    });
  });

  group('navigation bar swiping', () {
    testWidgets('tapping the current tab calls onReselect only', (
      tester,
    ) async {
      final taps = <int>[];
      final reselects = <int>[];
      await tester.pumpWidget(
        navBar(index: 1, onTap: taps.add, onReselect: reselects.add),
      );
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(taps, isEmpty);
      expect(reselects, [1]);

      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      expect(taps, [2]);
      expect(reselects, [1]);
    });

    testWidgets('dragging away and back to the current tab is not a reselect', (
      tester,
    ) async {
      final reselects = <int>[];
      await tester.pumpWidget(
        navBar(index: 0, onTap: (_) {}, onReselect: reselects.add),
      );
      final home = tester.getCenter(find.text('Home'));
      final me = tester.getCenter(find.text('Me'));
      final gesture = await tester.startGesture(home);
      await gesture.moveTo(me);
      await tester.pump();
      await gesture.moveTo(home);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(reselects, [0]);
    });

    testWidgets('dragging past the end still selects the last tab', (
      tester,
    ) async {
      int? tapped;
      await tester.pumpWidget(navBar(index: 0, onTap: (i) => tapped = i));
      final home = tester.getCenter(find.text('Home'));
      final gesture = await tester.startGesture(home);
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tapped, 2);
    });
  });

  testWidgets('.liquidGlass() wraps the widget with the given settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Text('x').liquidGlass(
          opacity: 0.4,
          style: LiquidGlassStyle.clear,
          shape: const LiquidGlassShape.circle(),
        ),
      ),
    );
    final glass = tester.widget<LiquidGlass>(find.byType(LiquidGlass));
    expect(glass.opacity, 0.4);
    expect(glass.style, LiquidGlassStyle.clear);
    expect(glass.shape, const LiquidGlassShape.circle());
    expect(find.text('x'), findsOneWidget);
  });

  testWidgets('glass press lets go when the list starts scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      inList(
        const SizedBox(
          height: 60,
          child: LiquidGlass(
            fallback: LiquidGlassFallback.frosted,
            child: Center(child: Text('card')),
          ),
        ),
      ),
    );
    Matrix4 transform() => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(LiquidGlass),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform;

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('card')),
    );
    await tester.pumpAndSettle();
    expect(transform().getMaxScaleOnAxis(), greaterThan(1.001));

    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(transform().getMaxScaleOnAxis(), closeTo(1, 0.001));
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
