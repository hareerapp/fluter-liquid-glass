import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';
import 'package:liquid_design/src/native_glass_view.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform_views,
          (_) async => null,
        );
  });
  tearDown(LiquidGlassService.instance.reset);

  Map<String, Object?> paramsOf(WidgetTester tester, Key key) => tester
      .widget<NativePlatformGlass>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(NativePlatformGlass),
        ),
      )
      .params;

  testWidgets('one LiquidGlass overrides settings, others follow global', (
    tester,
  ) async {
    const plain = Key('plain');
    const custom = Key('custom');
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            LiquidGlass(key: plain, child: SizedBox(width: 50, height: 50)),
            LiquidGlass(
              key: custom,
              style: LiquidGlassStyle.clear,
              opacity: 0.4,
              tintColor: Colors.red,
              tintOpacity: 0.8,
              brightness: LiquidGlassBrightness.dark,
              shape: LiquidGlassShape.roundedRect(9),
              child: SizedBox(width: 50, height: 50),
            ),
          ],
        ),
      ),
    );
    var p = paramsOf(tester, plain);
    var c = paramsOf(tester, custom);
    expect(p['style'], 'regular');
    expect(p['opacity'], 1.0);
    expect(p['tint'], isNull);
    expect(c['style'], 'clear');
    expect(c['opacity'], 0.4);
    expect(c['tint'], Colors.red.toARGB32());
    expect(c['tintOpacity'], 0.8);
    expect(c['brightness'], 'dark');
    expect(c['shape'], 'roundedRect');
    expect(c['radius'], 9.0);

    LiquidGlassService.instance.update(
      (s) => s.copyWith(
        style: LiquidGlassStyle.clear,
        opacity: 0.7,
        tintColor: Colors.blue,
        brightness: LiquidGlassBrightness.light,
      ),
    );
    await tester.pump();
    p = paramsOf(tester, plain);
    c = paramsOf(tester, custom);
    expect(p['style'], 'clear');
    expect(p['opacity'], 0.7);
    expect(p['tint'], Colors.blue.toARGB32());
    expect(p['brightness'], 'light');
    expect(c['opacity'], 0.4);
    expect(c['tint'], Colors.red.toARGB32());
    expect(c['brightness'], 'dark');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('per-widget enabled and fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            LiquidGlass(child: SizedBox(width: 50, height: 50)),
            LiquidGlass(
              fallback: LiquidGlassFallback.frosted,
              fallbackBlurSigma: 30,
              child: SizedBox(width: 50, height: 50),
            ),
          ],
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);

    LiquidGlassService.instance.setEnabled(false);
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: LiquidGlass(
          enabled: true,
          fallback: LiquidGlassFallback.frosted,
          child: SizedBox(width: 50, height: 50),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
