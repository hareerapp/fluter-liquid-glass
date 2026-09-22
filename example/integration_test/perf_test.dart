import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_design/liquid_design.dart';
import 'package:liquid_design_example/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester t, int ms) =>
      t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));

  Future<void> measure(
    WidgetTester t,
    String name,
    Future<void> Function() action,
  ) async {
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> f) => timings.addAll(f);
    SchedulerBinding.instance.addTimingsCallback(collect);
    await action();
    await wait(t, 300);
    SchedulerBinding.instance.removeTimingsCallback(collect);
    if (timings.isEmpty) {
      debugPrint('PERF $name: no frames');
      return;
    }
    double avg(Duration Function(FrameTiming) f) =>
        timings.map((x) => f(x).inMicroseconds).reduce((a, b) => a + b) /
        timings.length /
        1000;
    double worst(Duration Function(FrameTiming) f) =>
        timings
            .map((x) => f(x).inMicroseconds)
            .reduce((a, b) => a > b ? a : b) /
        1000;
    debugPrint(
      'PERF $name: ${timings.length} frames | '
      'build avg ${avg((x) => x.buildDuration).toStringAsFixed(1)} '
      'max ${worst((x) => x.buildDuration).toStringAsFixed(1)} ms | '
      'raster avg ${avg((x) => x.rasterDuration).toStringAsFixed(1)} '
      'max ${worst((x) => x.rasterDuration).toStringAsFixed(1)} ms | '
      'missed120 ${timings.where((x) => x.buildDuration.inMicroseconds > 8333 || x.rasterDuration.inMicroseconds > 8333).length} | '
      'slow(>16ms) ${timings.where((x) => x.buildDuration.inMicroseconds > 16700 || x.rasterDuration.inMicroseconds > 16700).length}',
    );
  }

  testWidgets('perf', (tester) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    // --dart-define=PERF_RENDERER=native|flutter|auto to compare renderers.
    const renderer = String.fromEnvironment('PERF_RENDERER');
    if (renderer.isNotEmpty) {
      LiquidGlassService.instance.setRenderer(
        LiquidGlassRenderer.values.byName(renderer),
      );
    }
    debugPrint(
      'PERF renderer: ${LiquidGlassService.instance.settings.renderer.name}',
    );
    await tester.pumpWidget(const DemoApp());
    await wait(tester, 1500);

    // First visits build each page once (one-time cost), measured apart.
    await measure(tester, 'first visits (one-time)', () async {
      for (final icon in [
        Icons.widgets_rounded,
        Icons.bubble_chart_rounded,
        Icons.category_rounded,
        Icons.settings_rounded,
        Icons.touch_app_rounded,
      ]) {
        await tester.tap(find.byIcon(icon).last, warnIfMissed: false);
        await wait(tester, 800);
      }
    });

    for (var round = 0; round < 3; round++) {
      await measure(tester, 'glass press+hold+release #$round', () async {
        final g = await tester.startGesture(
          tester.getCenter(find.text('Press, hold & drag me')),
        );
        await wait(tester, 500);
        await g.up();
        await wait(tester, 700);
      });
    }

    await measure(tester, 'tab switch x4', () async {
      for (final icon in [
        Icons.widgets_rounded,
        Icons.touch_app_rounded,
        Icons.widgets_rounded,
        Icons.touch_app_rounded,
      ]) {
        await tester.tap(find.byIcon(icon).last, warnIfMissed: false);
        await wait(tester, 700);
      }
    });

    await measure(tester, 'bar press+drag', () async {
      final g = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.touch_app_rounded).last),
      );
      await wait(tester, 300);
      for (var i = 0; i < 30; i++) {
        await g.moveBy(const Offset(8, 0));
        await wait(tester, 16);
      }
      await g.up();
      await wait(tester, 600);
    });

    await tester.tap(
      find.byIcon(Icons.widgets_rounded).last,
      warnIfMissed: false,
    );
    await wait(tester, 800);
    await tester.scrollUntilVisible(
      find.byType(LiquidGlassSwitch).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await wait(tester, 800);
    await measure(tester, 'switch toggle x4', () async {
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byType(LiquidGlassSwitch).first);
        await wait(tester, 600);
      }
    });

    await measure(tester, 'slider drag', () async {
      final slider = find.byType(LiquidGlassSlider).first;
      await tester.ensureVisible(slider);
      await wait(tester, 300);
      final g = await tester.startGesture(tester.getCenter(slider));
      for (var i = 0; i < 30; i++) {
        await g.moveBy(Offset(i < 15 ? 6 : -6, 0));
        await wait(tester, 16);
      }
      await g.up();
      await wait(tester, 500);
    });

    // Finger scroll: slow drag down then up, like reading a page.
    Future<void> scrollPage(String name, IconData tab) async {
      await tester.tap(find.byIcon(tab).last, warnIfMissed: false);
      await wait(tester, 800);
      final center = tester.getCenter(find.byType(Scaffold).first);
      await measure(tester, 'scroll $name', () async {
        for (final dir in [-1.0, 1.0, -1.0, 1.0]) {
          final g = await tester.startGesture(center);
          for (var i = 0; i < 25; i++) {
            await g.moveBy(Offset(0, 14 * dir));
            await wait(tester, 16);
          }
          await g.up();
          await wait(tester, 500);
        }
      });
    }

    await scrollPage('controls', Icons.touch_app_rounded);
    await scrollPage('components', Icons.widgets_rounded);
    await scrollPage('groups', Icons.bubble_chart_rounded);
    await scrollPage('gallery', Icons.category_rounded);
    await scrollPage('settings', Icons.settings_rounded);

    await measure(tester, 'tab switch all x2', () async {
      for (var r = 0; r < 2; r++) {
        for (final icon in [
          Icons.touch_app_rounded,
          Icons.widgets_rounded,
          Icons.bubble_chart_rounded,
          Icons.category_rounded,
          Icons.settings_rounded,
        ]) {
          await tester.tap(find.byIcon(icon).last, warnIfMissed: false);
          await wait(tester, 600);
        }
      }
    });
  });
}
