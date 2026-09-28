import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';

import '../common.dart';

const _heart =
    'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 '
    '3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 '
    '3.78-3.4 6.86-8.55 11.54L12 21.35z';

const _star = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26" fill="#FFC107"/>
</svg>''';

const _wave = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 60">
  <path d="M8 30 C 28 4, 44 4, 60 30 S 92 56, 112 30" fill="none"
        stroke="#1E88E5" stroke-width="14" stroke-linecap="round"/>
</svg>''';

const _bubbles = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 60">
  <circle cx="22" cy="30" r="20" fill="#E91E63"/>
  <circle cx="54" cy="26" r="16" fill="#9C27B0"/>
  <rect x="68" y="14" width="30" height="32" rx="10" fill="#3F51B5"/>
</svg>''';

class SvgPage extends StatefulWidget {
  const SvgPage({super.key});

  @override
  State<SvgPage> createState() => _SvgPageState();
}

class _SvgPageState extends State<SvgPage> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoSection(
          title: 'LiquidGlassSvg.asset',
          description:
              'The glass follows the SVG outline. On iOS and macOS it is '
              'native Liquid Glass; on other platforms the plain SVG is drawn.',
          child: GradientPanel(
            index: 7,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const LiquidGlassSvg.asset(
                  'assets/h_logo.svg',
                  height: 40,
                  semanticLabel: 'Hareer',
                ),
                const LiquidGlassSvg.asset(
                  'assets/h_logo.svg',
                  height: 72,
                  tintColor: Color(0xFF3E205A),
                  tintOpacity: 0.35,
                ),
                LiquidGlassSvg.asset(
                  'assets/h_logo.svg',
                  height: 110,
                  interactive: true,
                  color: Colors.white,
                  onTap: () => setState(() => _taps++),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            'Big logo tapped $_taps times (taps outside the outline are ignored)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        DemoSection(
          title: 'LiquidGlassSvg(svg: ...)',
          description:
              'Raw path data or a full SVG document as a string. Stroke-only '
              'artwork is turned into a fillable outline.',
          child: GlassGrid(
            children: [
              const GlassTile(
                label: 'path data',
                index: 0,
                child: LiquidGlassSvg(svg: _heart, width: 96),
              ),
              const GlassTile(
                label: 'polygon, tinted',
                index: 1,
                child: LiquidGlassSvg(
                  svg: _star,
                  width: 100,
                  tintColor: Colors.amber,
                ),
              ),
              const GlassTile(
                label: 'stroke-only, strokeToFill',
                index: 2,
                child: LiquidGlassSvg(svg: _wave, width: 130),
              ),
              GlassTile(
                label: 'several shapes, clear style',
                index: 3,
                child: LiquidGlassSvg(
                  svg: _bubbles,
                  width: 140,
                  settings: LiquidGlassService.instance.settings.copyWith(
                    style: LiquidGlassStyle.clear,
                  ),
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'child clipped to the shape',
          description: 'Any widget drawn inside the outline.',
          child: GradientPanel(
            index: 5,
            child: Center(
              child: LiquidGlassSvg(
                svg: _heart,
                width: 140,
                child: Center(
                  child: Text(
                    'LOVE',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        DemoSection(
          title: 'LiquidGlassShape.svg / .path',
          description:
              'Use the shape descriptor with LiquidGlass or .liquidGlass() '
              'directly.',
          child: GlassGrid(
            children: [
              GlassTile(
                label: 'LiquidGlassShape.svg(_star)',
                index: 4,
                child: LiquidGlass(
                  shape: LiquidGlassShape.svg(_star),
                  child: const SizedBox(width: 100, height: 100),
                ),
              ),
              GlassTile(
                label: 'LiquidGlassShape.path(Path)',
                index: 6,
                child: const SizedBox(width: 110, height: 90).liquidGlass(
                  shape: LiquidGlassShape.path(
                    Path()
                      ..moveTo(0, 50)
                      ..quadraticBezierTo(50, -20, 100, 50)
                      ..quadraticBezierTo(50, 120, 0, 50)
                      ..close(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
