import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';
import 'package:liquid_design/src/liquid_glass.dart' show FlutterGlass;
import 'package:liquid_design/src/native_glass_view.dart';

final ios = TargetPlatformVariant.only(TargetPlatform.iOS);
final apple = TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.macOS});

final logo = File('test/fixtures/h_logo.svg').readAsStringSync();

Widget app(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

const box = SizedBox(width: 60, height: 60);

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform_views,
          (_) async => null,
        );
  });
  tearDown(() {
    LiquidGlassService.debugOsMajorVersion = null;
    LiquidGlassService.instance.debugSetCapabilities(null);
    LiquidGlassService.instance.reset();
  });

  testWidgets('iOS 26 and newer use native glass', (tester) async {
    LiquidGlassService.debugOsMajorVersion = 26;
    expect(LiquidGlassService.isNativePlatform, isTrue);
    await tester.pumpWidget(app(const LiquidGlass(child: box)));
    expect(find.byType(NativePlatformGlass), findsOneWidget);
  }, variant: apple);

  testWidgets('older versions behave like Android: child only', (tester) async {
    LiquidGlassService.debugOsMajorVersion = 18;
    expect(LiquidGlassService.isNativePlatform, isFalse);
    expect(LiquidGlassService.isApplePlatform, isTrue);
    await tester.pumpWidget(app(const LiquidGlass(child: box)));
    expect(find.byType(NativePlatformGlass), findsNothing);
    expect(find.byType(FlutterGlass), findsNothing);
    expect(find.byType(UiKitView), findsNothing);
  }, variant: apple);

  testWidgets('older versions honour the frosted fallback', (tester) async {
    LiquidGlassService.debugOsMajorVersion = 17;
    LiquidGlassService.instance.setFallback(LiquidGlassFallback.frosted);
    await tester.pumpWidget(app(const LiquidGlass(child: box)));
    expect(find.byType(NativePlatformGlass), findsNothing);
    expect(find.byType(FlutterGlass), findsOneWidget);
  }, variant: ios);

  testWidgets('older versions draw the plain SVG', (tester) async {
    LiquidGlassService.debugOsMajorVersion = 18;
    await tester.pumpWidget(app(LiquidGlassSvg(svg: logo, height: 40)));
    expect(find.byType(LiquidGlass), findsNothing);
    expect(find.byType(NativePlatformGlass), findsNothing);
  }, variant: ios);

  testWidgets('older versions keep groups and components working', (
    tester,
  ) async {
    LiquidGlassService.debugOsMajorVersion = 18;
    var tapped = 0;
    await tester.pumpWidget(
      app(
        LiquidGlassGroup(
          child: LiquidGlassButton(
            onPressed: () => tapped++,
            child: const Text('Tap'),
          ),
        ),
      ),
    );
    expect(find.byType(NativePlatformGlass), findsNothing);
    await tester.tap(find.text('Tap'));
    expect(tapped, 1);
  }, variant: ios);

  testWidgets('capabilities from the plugin win over the OS version', (
    tester,
  ) async {
    LiquidGlassService.debugOsMajorVersion = 26;
    LiquidGlassService.instance.debugSetCapabilities(
      const LiquidGlassCapabilities(liquidGlass: false),
    );
    expect(LiquidGlassService.isNativePlatform, isFalse);
    await tester.pumpWidget(app(const LiquidGlass(child: box)));
    expect(find.byType(NativePlatformGlass), findsNothing);

    LiquidGlassService.instance.debugSetCapabilities(
      const LiquidGlassCapabilities(liquidGlass: true),
    );
    await tester.pump();
    expect(find.byType(NativePlatformGlass), findsOneWidget);
  }, variant: ios);

  test('Android is never native', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    LiquidGlassService.debugOsMajorVersion = 30;
    expect(LiquidGlassService.isNativePlatform, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });
}
