import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';

void main() {
  tearDown(LiquidGlassService.instance.reset);

  testWidgets('glass keeps the child layout (stretching children stay full)', (
    tester,
  ) async {
    Future<Size> buttonSize(LiquidGlassFallback fallback) async {
      LiquidGlassService.instance.setFallback(fallback);
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 60,
              child: LiquidGlassButton(
                onPressed: () {},
                child: const Text('Buy'),
              ),
            ),
          ),
        ),
      );
      return tester.getSize(
        find
            .descendant(
              of: find.byType(LiquidGlassButton),
              matching: find.byType(RawGestureDetector),
            )
            .last,
      );
    }

    expect(await buttonSize(LiquidGlassFallback.frosted), const Size(300, 60));
    expect(await buttonSize(LiquidGlassFallback.none), const Size(300, 60));
  });

  testWidgets('search bar follows a new controller', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    Widget bar(TextEditingController? c) => MaterialApp(
      home: Scaffold(body: LiquidGlassSearchBar(controller: c)),
    );
    await tester.pumpWidget(bar(null));
    await tester.pumpWidget(bar(controller));
    controller.text = 'sun';
    await tester.pump();
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
  });

  testWidgets('scroll collapse re-collapses after the parent expands it', (
    tester,
  ) async {
    var collapsed = false;
    late StateSetter setOuter;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return LiquidGlassScrollCollapse(
              collapsed: collapsed,
              onChanged: (c) => setState(() => collapsed = c),
              child: ListView(
                children: [
                  for (var i = 0; i < 80; i++) const SizedBox(height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(collapsed, isTrue);

    setOuter(() => collapsed = false);
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(collapsed, isTrue);
  });

  testWidgets('collapsing mid-press cancels the press cleanly', (tester) async {
    var collapsed = false;
    int? tapped;
    late StateSetter setOuter;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return LiquidGlassNavigationBar(
                  currentIndex: 0,
                  collapsed: collapsed,
                  onTap: (i) => tapped = i,
                  items: const [
                    LiquidGlassNavItem(icon: Icon(Icons.home), label: 'A'),
                    LiquidGlassNavItem(icon: Icon(Icons.search), label: 'B'),
                    LiquidGlassNavItem(icon: Icon(Icons.person), label: 'C'),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    final g = await tester.startGesture(tester.getCenter(find.text('A')));
    await g.moveBy(const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 50));
    setOuter(() => collapsed = true);
    await tester.pumpAndSettle();
    await g.up();
    await tester.pumpAndSettle();
    expect(tapped, isNull);
    setOuter(() => collapsed = false);
    await tester.pumpAndSettle();
    final a = tester.widget<Text>(find.text('A')).style!.color!;
    final b = tester.widget<Text>(find.text('B')).style!.color!;
    expect(a, isNot(b));
  });

  testWidgets('bouncing past the end keeps the bar collapsed', (tester) async {
    var collapsed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => LiquidGlassScrollCollapse(
            collapsed: collapsed,
            onChanged: (c) => setState(() => collapsed = c),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                for (var i = 0; i < 20; i++) const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.timedDrag(
      find.byType(ListView),
      const Offset(0, -1500),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();
    expect(collapsed, isTrue);
  });
}
