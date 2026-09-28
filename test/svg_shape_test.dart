import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_design/liquid_design.dart';
import 'package:liquid_design/src/liquid_glass.dart' show FlutterGlass;
import 'package:liquid_design/src/native_glass_view.dart';
import 'package:liquid_design/src/svg/svg_document_parser.dart';
import 'package:liquid_design/src/svg/svg_path_parser.dart';

final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

final logo = File('test/fixtures/h_logo.svg').readAsStringSync();

const square = 'M0 0 L10 0 L10 10 L0 10 Z';

Rect boundsOf(SvgPathCommands c) => c.toPath().getBounds();

void expectRect(Rect actual, Rect expected, [double epsilon = 1e-3]) {
  expect(actual.left, closeTo(expected.left, epsilon));
  expect(actual.top, closeTo(expected.top, epsilon));
  expect(actual.right, closeTo(expected.right, epsilon));
  expect(actual.bottom, closeTo(expected.bottom, epsilon));
}

class _TestBundle extends CachingAssetBundle {
  _TestBundle(this.assets);

  final Map<String, String> assets;
  int loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    final text = assets[key];
    if (text == null) throw FlutterError('missing $key');
    return ByteData.sublistView(Uint8List.fromList(text.codeUnits));
  }
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform_views,
          (_) async => null,
        );
  });
  tearDown(LiquidGlassService.instance.reset);

  group('existing shapes keep their wire format', () {
    const codec = StandardMessageCodec();

    void expectBytes(LiquidGlassShape shape, Map<String, Object> expected) {
      expect(shape.toMap(), expected);
      expect(
        codec.encodeMessage(shape.toMap())!.buffer.asUint8List(),
        codec.encodeMessage(expected)!.buffer.asUint8List(),
      );
    }

    test('capsule, circle, roundedRect and rect', () {
      expectBytes(const LiquidGlassShape.capsule(), {
        'shape': 'capsule',
        'radius': 0.0,
      });
      expectBytes(const LiquidGlassShape.circle(), {
        'shape': 'capsule',
        'radius': 0.0,
      });
      expectBytes(const LiquidGlassShape.roundedRect(12), {
        'shape': 'roundedRect',
        'radius': 12.0,
      });
      expectBytes(const LiquidGlassShape.rect(), {
        'shape': 'rect',
        'radius': 0.0,
      });
    });

    test('equality and toString are unchanged', () {
      expect(
        const LiquidGlassShape.roundedRect(8),
        const LiquidGlassShape.roundedRect(8),
      );
      expect(const LiquidGlassShape.capsule(), const LiquidGlassShape.circle());
      expect(
        const LiquidGlassShape.capsule().hashCode,
        const LiquidGlassShape.circle().hashCode,
      );
      expect(
        const LiquidGlassShape.roundedRect(4).toString(),
        'LiquidGlassShape.roundedRect(4.0)',
      );
      expect(const LiquidGlassShape.capsule().isPath, isFalse);
      expect(const LiquidGlassShape.rect().viewBox, Rect.zero);
    });

    test('detect never returns a path shape', () {
      final shape = LiquidGlassShape.detect(
        Container(decoration: const BoxDecoration(shape: BoxShape.circle)),
      );
      expect(shape, const LiquidGlassShape.circle());
    });
  });

  group('path data parser', () {
    test('absolute and relative lines', () {
      expectRect(
        boundsOf(parseSvgPathData(square)),
        const Rect.fromLTWH(0, 0, 10, 10),
      );
      expectRect(
        boundsOf(parseSvgPathData('m5 5 h10 v10 h-10 z')),
        const Rect.fromLTWH(5, 5, 10, 10),
      );
    });

    test('implicit commands, compact numbers and exponents', () {
      final c = parseSvgPathData('M0,0 10,0 10-10.5.5e1-5z');
      expectRect(boundsOf(c), const Rect.fromLTRB(0, -10.5, 10, 0));
      expect(c.data.where((v) => v == SvgOp.line).length, greaterThan(1));
    });

    test('smooth curves and arcs end at the right points', () {
      final c = parseSvgPathData(
        'M0 0 C0 10 10 10 10 0 S20 -10 20 0 Q25 10 30 0 T40 0 A5 5 0 0 1 50 0',
      );
      final metrics = c.toPath().computeMetrics().toList();
      final end = metrics.last
          .getTangentForOffset(metrics.last.length)!
          .position;
      expect(end.dx, closeTo(50, 1e-6));
      expect(end.dy, closeTo(0, 1e-6));
      expect(boundsOf(c).bottom, greaterThan(4.9));
    });

    test('arc flags without separators', () {
      final c = parseSvgPathData('M0 0a10 10 0 1110 10');
      expect(c.data.where((v) => v == SvgOp.cubic).length, greaterThan(0));
    });

    test('invalid data throws a FormatException', () {
      expect(() => parseSvgPathData('M0 0 L10'), throwsFormatException);
    });
  });

  group('document parser', () {
    test('reads the Hareer logo', () {
      final doc = parseSvgDocument(logo);
      expectRect(doc.viewBox, const Rect.fromLTWH(0, 0, 713.19, 984.3));
      expect(doc.drawables, hasLength(1));
      expect(doc.drawables.single.fill!.color, const Color(0xFF3E205A));
      final bounds = doc.drawables.single.path.getBounds();
      expect(bounds.width, closeTo(713.19, 16));
      expect(bounds.height, closeTo(984.3, 16));
    });

    test('css classes, groups, transforms and basic shapes', () {
      final doc = parseSvgDocument('''
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="50">
  <defs><style>.a{fill:#ff0000}</style></defs>
  <g transform="translate(10 5)" opacity="0.5">
    <rect class="a" width="20" height="10" rx="2"/>
    <circle cx="50" cy="20" r="5" style="fill: rgb(0, 0, 255)"/>
    <polygon points="0,30 10,30 5,40"/>
  </g>
</svg>''');
      expect(doc.viewBox, const Rect.fromLTWH(0, 0, 100, 50));
      expect(doc.drawables, hasLength(3));
      expect(doc.drawables[0].fill!.color, const Color(0xFFFF0000));
      expect(doc.drawables[0].opacity, 0.5);
      expectRect(
        doc.drawables[0].path.getBounds(),
        const Rect.fromLTWH(10, 5, 20, 10),
      );
      expect(doc.drawables[1].fill!.color, const Color(0xFF0000FF));
      expectRect(
        doc.drawables[1].path.getBounds(),
        const Rect.fromLTWH(55, 20, 10, 10),
      );
      expect(doc.drawables[2].fill!.color, const Color(0xFF000000));
    });

    test('hidden content is skipped and gradients resolve', () {
      final doc = parseSvgDocument('''
<svg viewBox="0 0 10 10">
  <rect width="10" height="10" fill="url(#g)"/>
  <defs>
    <linearGradient id="g"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#000"/></linearGradient>
    <rect width="5" height="5"/>
  </defs>
  <rect width="5" height="5" display="none"/>
</svg>''');
      expect(doc.drawables, hasLength(1));
      expect(doc.drawables.single.fill!.gradient, isNotNull);
    });

    test('colors', () {
      expect(parseSvgColor('#abc'), const Color(0xFFAABBCC));
      expect(parseSvgColor('#11223380'), const Color(0x80112233));
      expect(parseSvgColor('white'), const Color(0xFFFFFFFF));
      expect(parseSvgColor('none'), isNull);
      expect(parseSvgColor('hsl(0, 100%, 50%)')!.r, closeTo(1, 1e-6));
    });
  });

  group('LiquidGlassShape.svg', () {
    test('raw path data uses its bounds as the viewBox', () {
      final shape = LiquidGlassShape.svg('M10 20 h40 v20 h-40 z');
      expect(shape.isPath, isTrue);
      expect(shape.viewBox, const Rect.fromLTWH(10, 20, 40, 20));
      expect(shape.aspectRatio, 2);
    });

    test('toMap encodes unit space commands', () {
      final map = LiquidGlassShape.svg(square).toMap();
      expect(map['shape'], 'path');
      expect(map['radius'], 0);
      expect(map['fillRule'], 'nonZero');
      expect(map['fit'], 'contain');
      expect(map['alignX'], 0);
      expect(map['alignY'], 0);
      expect(map['path'], [0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 4]);
      expect(const StandardMessageCodec().encodeMessage(map), isNotNull);
    });

    test('logo commands stay close to unit space', () {
      final path = LiquidGlassShape.svg(logo).toMap()['path']! as List<double>;
      expect(path.first, SvgOp.move);
      final values = <double>[];
      var i = 0;
      while (i < path.length) {
        final count = SvgOp.argCount(path[i].toInt());
        values.addAll(path.sublist(i + 1, i + 1 + count));
        i += 1 + count;
      }
      expect(values.every((v) => v >= -0.05 && v <= 1.05), isTrue);
    });

    test('equality uses the source, not identity', () {
      final a = LiquidGlassShape.svg(logo);
      final b = LiquidGlassShape.svg(logo);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a == LiquidGlassShape.svg(logo, fillType: PathFillType.evenOdd),
        isFalse,
      );
      expect(a == LiquidGlassShape.svg(logo, fit: BoxFit.fill), isFalse);
      expect(a == const LiquidGlassShape.rect(), isFalse);
      expect(a.toString(), startsWith('LiquidGlassShape.svg('));
    });

    test('path shapes compare by geometry', () {
      final p1 = Path()..addOval(const Rect.fromLTWH(0, 0, 10, 10));
      final p2 = Path()..addOval(const Rect.fromLTWH(0, 0, 10, 10));
      expect(LiquidGlassShape.path(p1), LiquidGlassShape.path(p2));
      expect(
        LiquidGlassShape.path(p1) ==
            LiquidGlassShape.path(
              Path()..addRect(const Rect.fromLTWH(0, 0, 10, 10)),
            ),
        isFalse,
      );
    });

    test('resolvePath fits the viewBox into the box', () {
      final shape = LiquidGlassShape.svg('M0 0 H200 V100 H0 Z');
      expectRect(
        shape.resolvePath(const Size(100, 100)).getBounds(),
        const Rect.fromLTWH(0, 25, 100, 50),
      );
      expectRect(
        shape
            .resolvePath(const Size(100, 100), alignment: Alignment.topLeft)
            .getBounds(),
        const Rect.fromLTWH(0, 0, 100, 50),
      );
      expectRect(
        shape.resolvePath(const Size(100, 100), fit: BoxFit.fill).getBounds(),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
    });

    test('stroke-only artwork becomes a fillable outline', () {
      const svg =
          '<svg viewBox="0 0 100 100"><path d="M10 50 H90" fill="none" '
          'stroke="#000" stroke-width="10" stroke-linecap="round"/></svg>';
      final filled = LiquidGlassShape.svg(svg);
      final path = filled.resolvePath(const Size(100, 100));
      expect(path.contains(const Offset(50, 50)), isTrue);
      expect(path.contains(const Offset(50, 53)), isTrue);
      expect(path.contains(const Offset(7, 50)), isTrue);
      expect(path.contains(const Offset(50, 60)), isFalse);
      expect(path.contains(const Offset(50, 20)), isFalse);

      final raw = LiquidGlassShape.svg(svg, strokeToFill: false);
      expect(
        raw.resolvePath(const Size(100, 100)).contains(const Offset(50, 53)),
        isFalse,
      );
    });

    test('several filled elements are unioned', () {
      const svg =
          '<svg viewBox="0 0 30 10"><rect width="10" height="10"/>'
          '<rect x="20" width="10" height="10"/></svg>';
      final path = LiquidGlassShape.svg(
        svg,
        fit: BoxFit.fill,
      ).resolvePath(const Size(30, 10));
      expect(path.contains(const Offset(5, 5)), isTrue);
      expect(path.contains(const Offset(25, 5)), isTrue);
      expect(path.contains(const Offset(15, 5)), isFalse);
    });
  });

  group('LiquidGlassSvg', () {
    Widget app(Widget child, {AssetBundle? bundle}) {
      final body = MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );
      return bundle == null
          ? body
          : DefaultAssetBundle(bundle: bundle, child: body);
    }

    testWidgets('draws the plain SVG off Apple platforms', (tester) async {
      await tester.pumpWidget(app(LiquidGlassSvg(svg: logo, height: 40)));
      expect(find.byType(LiquidGlass), findsNothing);
      expect(find.byType(NativePlatformGlass), findsNothing);
      final size = tester.getSize(find.byType(LiquidGlassSvg));
      expect(size.height, 40);
      expect(size.width, closeTo(40 * 713.19 / 984.3, 1e-6));
    });

    testWidgets('frosted fallback draws Flutter glass off Apple platforms', (
      tester,
    ) async {
      LiquidGlassService.instance.setFallback(LiquidGlassFallback.frosted);
      await tester.pumpWidget(app(LiquidGlassSvg(svg: logo, height: 40)));
      expect(find.byType(FlutterGlass), findsOneWidget);
      final glass = tester.widget<FlutterGlass>(find.byType(FlutterGlass));
      expect(glass.shape.isPath, isTrue);
    });

    testWidgets('disabled glass draws the plain SVG', (tester) async {
      LiquidGlassService.instance.setFallback(LiquidGlassFallback.frosted);
      LiquidGlassService.instance.setEnabled(false);
      await tester.pumpWidget(app(LiquidGlassSvg(svg: logo, height: 40)));
      expect(find.byType(LiquidGlass), findsNothing);
    });

    testWidgets('native glass on iOS carries the path', (tester) async {
      await tester.pumpWidget(
        app(LiquidGlassSvg(svg: logo, height: 40, tintColor: Colors.purple)),
      );
      final native = tester.widget<NativePlatformGlass>(
        find.byType(NativePlatformGlass),
      );
      expect(native.params['shape'], 'path');
      expect(native.params['path'], isA<List<double>>());
      expect(native.params['tint'], Colors.purple.toARGB32());
      expect(find.byType(UiKitView), findsOneWidget);
    }, variant: ios);

    testWidgets('path shapes never join a native group', (tester) async {
      await tester.pumpWidget(
        app(
          LiquidGlassGroup(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LiquidGlassSvg(svg: logo, height: 40),
                const LiquidGlass(child: SizedBox(width: 40, height: 40)),
              ],
            ),
          ),
        ),
      );
      final natives = tester
          .widgetList<NativePlatformGlass>(find.byType(NativePlatformGlass))
          .where((w) => w.params['shape'] == 'path');
      expect(natives, hasLength(1));
    }, variant: ios);

    testWidgets('asset constructor loads once and caches', (tester) async {
      final bundle = _TestBundle({'assets/logo.svg': logo});
      await tester.pumpWidget(
        app(
          const LiquidGlassSvg.asset('assets/logo.svg', height: 40),
          bundle: bundle,
        ),
      );
      expect(tester.getSize(find.byType(LiquidGlassSvg)).width, 0);
      await tester.pump();
      expect(
        tester.getSize(find.byType(LiquidGlassSvg)).width,
        closeTo(40 * 713.19 / 984.3, 1e-6),
      );

      await tester.pumpWidget(app(const SizedBox(), bundle: bundle));
      await tester.pumpWidget(
        app(
          const LiquidGlassSvg.asset('assets/logo.svg', height: 40),
          bundle: bundle,
        ),
      );
      expect(tester.getSize(find.byType(LiquidGlassSvg)).width, greaterThan(0));
      expect(bundle.loads, 1);
    });

    testWidgets('taps only land inside the shape', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(
          LiquidGlassSvg(
            svg: '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="50"/></svg>',
            width: 100,
            height: 100,
            onTap: () => taps++,
            semanticLabel: 'Logo',
          ),
        ),
      );
      final origin = tester.getTopLeft(find.byType(LiquidGlassSvg));
      await tester.tapAt(origin + const Offset(50, 50));
      expect(taps, 1);
      await tester.tapAt(origin + const Offset(3, 3));
      expect(taps, 1);
      expect(find.bySemanticsLabel('Logo'), findsOneWidget);
    });

    testWidgets('invalid svg reports an error and renders nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const LiquidGlassSvg(svg: 'M0 0 L', width: 10, height: 10)),
      );
      expect(tester.takeException(), isFormatException);
    });

    testWidgets('child is clipped to the shape', (tester) async {
      await tester.pumpWidget(
        app(
          LiquidGlassSvg(
            svg: square,
            width: 50,
            height: 50,
            child: const ColoredBox(color: Colors.red),
          ),
        ),
      );
      expect(find.byType(ClipPath), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ClipPath),
          matching: find.byType(ColoredBox),
        ),
        findsOneWidget,
      );
    });
  });

  test('path shapes are drawn by the Flutter renderer', () async {
    final shape = LiquidGlassShape.svg(logo);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawPath(shape.toPath(const Rect.fromLTWH(0, 0, 40, 40)), Paint());
    final image = await recorder.endRecording().toImage(40, 40);
    expect(image.width, 40);
  });
}
