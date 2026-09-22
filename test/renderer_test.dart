import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';
import 'package:liquid_design/src/glass_lens.dart';
import 'package:liquid_design/src/liquid_glass.dart' show FlutterGlass;
import 'package:liquid_design/src/native_glass_view.dart';

final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

const _box = SizedBox(width: 60, height: 60);

Finder nativeIn(Key key) => find.descendant(
  of: find.byKey(key),
  matching: find.byType(NativePlatformGlass),
);

Finder flutterIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(FlutterGlass));

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform_views,
          (_) async => null,
        );
  });
  tearDown(LiquidGlassService.instance.reset);

  const fixed = Key('fixed');
  const scrolled = Key('scrolled');

  Widget page({LiquidGlassRenderer? renderer}) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          LiquidGlass(key: fixed, renderer: renderer, child: _box),
          Expanded(
            child: ListView(
              children: [
                Center(
                  child: LiquidGlass(
                    key: scrolled,
                    renderer: renderer,
                    child: _box,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  testWidgets('default is native everywhere', (tester) async {
    await tester.pumpWidget(page());
    expect(nativeIn(fixed), findsOneWidget);
    expect(nativeIn(scrolled), findsOneWidget);
    expect(find.byType(FlutterGlass), findsNothing);
  }, variant: ios);

  testWidgets('auto: native outside lists, Flutter glass inside lists', (
    tester,
  ) async {
    LiquidGlassService.instance.setRenderer(LiquidGlassRenderer.auto);
    await tester.pumpWidget(page());
    expect(nativeIn(fixed), findsOneWidget);
    expect(flutterIn(fixed), findsNothing);
    expect(nativeIn(scrolled), findsNothing);
    expect(flutterIn(scrolled), findsOneWidget);
  }, variant: ios);

  testWidgets('per-widget renderer overrides auto', (tester) async {
    await tester.pumpWidget(page(renderer: LiquidGlassRenderer.native));
    expect(nativeIn(fixed), findsOneWidget);
    expect(nativeIn(scrolled), findsOneWidget);

    await tester.pumpWidget(page(renderer: LiquidGlassRenderer.flutter));
    expect(flutterIn(fixed), findsOneWidget);
    expect(flutterIn(scrolled), findsOneWidget);
    expect(find.byType(NativePlatformGlass), findsNothing);
  }, variant: ios);

  testWidgets('global renderer switches every glass at runtime', (
    tester,
  ) async {
    await tester.pumpWidget(page());
    LiquidGlassService.instance.setRenderer(LiquidGlassRenderer.native);
    await tester.pump();
    expect(find.byType(NativePlatformGlass), findsNWidgets(2));

    LiquidGlassService.instance.setRenderer(LiquidGlassRenderer.flutter);
    await tester.pump();
    expect(find.byType(NativePlatformGlass), findsNothing);
    expect(find.byType(FlutterGlass), findsNWidgets(2));
  }, variant: ios);

  testWidgets('a PageView page is not scrolling content', (tester) async {
    LiquidGlassService.instance.setRenderer(LiquidGlassRenderer.auto);
    await tester.pumpWidget(
      MaterialApp(
        home: PageView(
          children: const [
            Center(
              child: LiquidGlass(key: fixed, child: _box),
            ),
          ],
        ),
      ),
    );
    expect(nativeIn(fixed), findsOneWidget);
  }, variant: ios);

  testWidgets('glass in a group stays native inside a list', (tester) async {
    LiquidGlassService.instance.setRenderer(LiquidGlassRenderer.auto);
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: const [
            LiquidGlassGroup(
              child: Row(
                children: [LiquidGlass(key: scrolled, child: _box)],
              ),
            ),
          ],
        ),
      ),
    );
    expect(flutterIn(scrolled), findsNothing);
    expect(find.byType(UiKitView), findsOneWidget);
  }, variant: ios);

  testWidgets('Flutter renderer: groups create no native view', (tester) async {
    LiquidGlassService.instance.setRenderer(LiquidGlassRenderer.flutter);
    await tester.pumpWidget(
      const MaterialApp(
        home: LiquidGlassGroup(
          child: Row(
            children: [LiquidGlass(key: fixed, child: _box)],
          ),
        ),
      ),
    );
    expect(find.byType(UiKitView), findsNothing);
    expect(flutterIn(fixed), findsOneWidget);
  }, variant: ios);

  testWidgets('the native lens leaves the scene after the touch ends', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: LiquidGlassNavigationBar(
                currentIndex: 0,
                onTap: (_) {},
                items: const [
                  LiquidGlassNavItem(icon: Icon(Icons.home), label: 'Home'),
                  LiquidGlassNavItem(icon: Icon(Icons.search), label: 'Find'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Offstage lensOffstage() => tester.widget<Offstage>(
      find
          .ancestor(
            of: find.byType(GlassLensHost, skipOffstage: false),
            matching: find.byType(Offstage, skipOffstage: false),
          )
          .first,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Find')),
    );
    await tester.pump();
    expect(lensOffstage().offstage, isFalse);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(lensOffstage().offstage, isFalse);
    await tester.pump(const Duration(milliseconds: 800));
    expect(lensOffstage().offstage, isTrue);
    await tester.pumpAndSettle();
  }, variant: ios);

  testWidgets('first touch on the iOS tab bar selects (lens insert safe)', (
    tester,
  ) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: LiquidGlassNavigationBar(
                currentIndex: 0,
                onTap: taps.add,
                items: const [
                  LiquidGlassNavItem(icon: Icon(Icons.home), label: 'Home'),
                  LiquidGlassNavItem(icon: Icon(Icons.search), label: 'Find'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Find')),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, [1]);
  }, variant: ios);

  testWidgets('switch lens: native in lists, Flutter with flutter renderer', (
    tester,
  ) async {
    var value = false;
    Widget app() => MaterialApp(
      home: ListView(
        children: [
          StatefulBuilder(
            builder: (context, setState) => LiquidGlassSwitch(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ],
      ),
    );
    await tester.pumpWidget(app());
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LiquidGlassSwitch)),
    );
    await tester.pump();
    expect(find.byType(GlassLensHost), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(value, isTrue);

    LiquidGlassService.instance.setRenderer(LiquidGlassRenderer.flutter);
    await tester.pumpWidget(app());
    final second = await tester.startGesture(
      tester.getCenter(find.byType(LiquidGlassSwitch)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GlassLensHost), findsNothing);
    expect(find.byType(FlutterGlass), findsOneWidget);
    await second.up();
    await tester.pumpAndSettle();
    expect(value, isFalse);
  }, variant: ios);
}
