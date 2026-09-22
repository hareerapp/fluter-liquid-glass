import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';

Widget app(Widget child, {TextDirection dir = TextDirection.ltr}) =>
    MaterialApp(
      home: Directionality(
        textDirection: dir,
        child: Scaffold(body: Center(child: child)),
      ),
    );

Widget navBar(int index, ValueChanged<int> onTap) => SizedBox(
  width: 400,
  child: LiquidGlassNavigationBar(
    currentIndex: index,
    onTap: onTap,
    items: const [
      LiquidGlassNavItem(icon: Icon(Icons.home), label: 'Home'),
      LiquidGlassNavItem(icon: Icon(Icons.search), label: 'Search'),
      LiquidGlassNavItem(icon: Icon(Icons.person), label: 'Me'),
    ],
  ),
);

void main() {
  tearDown(LiquidGlassService.instance.reset);

  group('navigation bar', () {
    testWidgets('RTL: first item sits on the right and taps map correctly', (
      tester,
    ) async {
      int? tapped;
      await tester.pumpWidget(
        app(navBar(0, (i) => tapped = i), dir: TextDirection.rtl),
      );
      final home = tester.getCenter(find.text('Home'));
      final me = tester.getCenter(find.text('Me'));
      expect(home.dx, greaterThan(me.dx));

      await tester.tap(find.text('Me'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tapped, 2);
    });

    testWidgets('RTL: dragging selects the item under the finger', (
      tester,
    ) async {
      int? tapped;
      await tester.pumpWidget(
        app(navBar(0, (i) => tapped = i), dir: TextDirection.rtl),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Home')),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(-25, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.moveTo(tester.getCenter(find.text('Search')));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('exposes selectable buttons to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      int? tapped;
      await tester.pumpWidget(app(navBar(0, (i) => tapped = i)));
      expect(
        tester.getSemantics(find.text('Home')),
        matchesSemantics(
          label: 'Home',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Me'));
      expect(tapped, 2);
      handle.dispose();
    });

    testWidgets('collapsed bar shrinks and expands on tap', (tester) async {
      var expanded = false;
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 400,
            child: LiquidGlassNavigationBar(
              currentIndex: 1,
              collapsed: true,
              onExpand: () => expanded = true,
              onTap: (_) {},
              items: const [
                LiquidGlassNavItem(icon: Icon(Icons.home), label: 'Home'),
                LiquidGlassNavItem(icon: Icon(Icons.search), label: 'Search'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getTopLeft(find.byType(SizedBox).first) + const Offset(20, 30),
      );
      expect(expanded, isTrue);
    });
  });

  testWidgets('segmented control selects by tap', (tester) async {
    String? value;
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 300,
          child: LiquidGlassSegmentedControl<String>(
            value: 'a',
            onValueChanged: (v) => value = v,
            children: const {'a': Text('A'), 'b': Text('B'), 'c': Text('C')},
          ),
        ),
      ),
    );
    await tester.tap(find.text('C'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(value, 'c');
  });

  group('button', () {
    testWidgets('taps, and is disabled without onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LiquidGlassButton(
                onPressed: () => taps++,
                child: const Text('Go'),
              ),
              const LiquidGlassButton(onPressed: null, child: Text('No')),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.tap(find.text('No'), warnIfMissed: false);
      expect(taps, 1);
    });

    testWidgets('meets the 44pt minimum touch target', (tester) async {
      await tester.pumpWidget(
        app(
          LiquidGlassButton.icon(
            onPressed: () {},
            size: 30,
            icon: const Icon(Icons.add),
          ),
        ),
      );
      final size = tester.getSize(find.byType(LiquidGlassButton));
      expect(size.width, 30);
      await tester.pumpWidget(
        app(LiquidGlassButton(onPressed: () {}, child: const Text('x'))),
      );
      expect(
        tester.getSize(find.byType(LiquidGlassButton)).height,
        greaterThanOrEqualTo(44),
      );
    });
  });

  group('switch', () {
    testWidgets('tap toggles, drag sets', (tester) async {
      bool? value;
      await tester.pumpWidget(
        app(LiquidGlassSwitch(value: false, onChanged: (v) => value = v)),
      );
      await tester.tap(find.byType(LiquidGlassSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);

      value = null;
      await tester.drag(find.byType(LiquidGlassSwitch), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets('RTL: dragging towards the start turns it on', (tester) async {
      bool? value;
      await tester.pumpWidget(
        app(
          LiquidGlassSwitch(value: false, onChanged: (v) => value = v),
          dir: TextDirection.rtl,
        ),
      );
      await tester.drag(find.byType(LiquidGlassSwitch), const Offset(-40, 0));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets('semantics toggled state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          LiquidGlassSwitch(
            value: true,
            semanticLabel: 'Wi-Fi',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(LiquidGlassSwitch)),
        matchesSemantics(
          label: 'Wi-Fi',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('slider', () {
    testWidgets('drag changes value, divisions snap, RTL mirrors', (
      tester,
    ) async {
      double? value;
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: LiquidGlassSlider(
              value: 0,
              divisions: 4,
              onChanged: (v) => value = v,
            ),
          ),
        ),
      );
      final box = find.byType(LiquidGlassSlider);
      await tester.tapAt(tester.getCenter(box));
      expect(value, 0.5);

      await tester.pumpWidget(
        app(
          SizedBox(
            width: 300,
            child: LiquidGlassSlider(value: 0.5, onChanged: (v) => value = v),
          ),
          dir: TextDirection.rtl,
        ),
      );
      await tester.tapAt(tester.getTopRight(box) + const Offset(-19, 22));
      expect(value, closeTo(0, 0.01));
    });

    testWidgets('semantics increase / decrease', (tester) async {
      final handle = tester.ensureSemantics();
      double value = 0.5;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => app(
            SizedBox(
              width: 300,
              child: LiquidGlassSlider(
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(LiquidGlassSlider));
      expect(node.value, '50%');
      node.owner!.performAction(node.id, SemanticsAction.increase);
      await tester.pump();
      expect(value, closeTo(0.6, 0.001));
      handle.dispose();
    });
  });

  testWidgets('LiquidGlassTheme overrides the service for a subtree', (
    tester,
  ) async {
    LiquidGlassService.instance.setFallback(LiquidGlassFallback.none);
    await tester.pumpWidget(
      app(
        const LiquidGlassTheme(
          settings: LiquidGlassSettings(fallback: LiquidGlassFallback.frosted),
          child: LiquidGlass(child: SizedBox(width: 50, height: 50)),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('Reduce Motion: no stretch while dragging', (tester) async {
    LiquidGlassService.instance.setFallback(LiquidGlassFallback.frosted);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Center(
            child: LiquidGlass(child: const SizedBox(width: 60, height: 60)),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LiquidGlass)),
    );
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final transform = tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(LiquidGlass),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform;
    expect(transform.getTranslation().x.abs(), lessThan(4));
    await gesture.up();
  });

  testWidgets('collapseOnScroll off keeps the bar open', (tester) async {
    var collapsed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Stack(
              children: [
                LiquidGlassScrollCollapse(
                  onChanged: (c) => setState(() => collapsed = c),
                  child: ListView(
                    children: [
                      for (var i = 0; i < 50; i++) const SizedBox(height: 60),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  width: 400,
                  child: LiquidGlassNavigationBar(
                    currentIndex: 0,
                    collapsed: collapsed,
                    onTap: (_) {},
                    items: const [
                      LiquidGlassNavItem(icon: Icon(Icons.home), label: 'Home'),
                      LiquidGlassNavItem(
                        icon: Icon(Icons.search),
                        label: 'Find',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Finder label(String text) => find.text(text);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(collapsed, isTrue);
    expect(label('Find'), findsNothing);

    LiquidGlassService.instance.setCollapseOnScroll(false);
    await tester.pumpAndSettle();
    expect(collapsed, isFalse);
    expect(label('Find'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(collapsed, isFalse);
    expect(label('Find'), findsOneWidget);
  });

  testWidgets('scroll collapse reports direction changes', (tester) async {
    final states = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassScrollCollapse(
          onChanged: states.add,
          child: ListView(
            children: [for (var i = 0; i < 50; i++) SizedBox(height: 60)],
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, 100));
    await tester.pump();
    expect(states, [true, false]);
  });

  testWidgets('LiquidGlassGroup is transparent off Apple platforms', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const LiquidGlassGroup(
          child: LiquidGlass(child: SizedBox(width: 50, height: 50)),
        ),
      ),
    );
    expect(find.byType(UiKitView), findsNothing);
    expect(find.byType(LiquidGlass), findsOneWidget);
  });

  test('capabilities default to none off Apple platforms', () {
    expect(LiquidGlassService.isNativePlatform, isFalse);
    expect(LiquidGlassService.instance.capabilities.liquidGlass, isFalse);
    expect(LiquidGlassService.instance.isLiquidGlassSupported, isFalse);
  });
}
