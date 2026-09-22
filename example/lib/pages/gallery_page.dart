import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';

import '../common.dart';
import 'overrides_page.dart';
import 'shapes_page.dart';

/// Shapes, per-widget overrides and LiquidGlassTheme.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      children: [
        LiquidGlassSegmentedControl<int>(
          value: _tab,
          onValueChanged: (v) => setState(() => _tab = v),
          children: const {
            0: Text('Shapes'),
            1: Text('Overrides'),
            2: Text('Theme'),
          },
        ),
        const SizedBox(height: 20),
        switch (_tab) {
          0 => const ShapesPage(),
          1 => const OverridesPage(),
          _ => const _ThemeDemo(),
        },
      ],
    );
  }
}

class _ThemeDemo extends StatelessWidget {
  const _ThemeDemo();

  @override
  Widget build(BuildContext context) {
    final global = LiquidGlassService.instance.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoSection(
          title: 'LiquidGlassTheme',
          description:
              'Overrides the settings for a whole subtree — every '
              'glass widget and component below uses it. Here: clear, pink '
              'tinted glass with stronger motion.',
          child: LiquidGlassTheme(
            settings: global.copyWith(
              style: LiquidGlassStyle.clear,
              tintColor: Colors.pink,
              tintOpacity: 0.35,
              interactionStrength: 1.6,
            ),
            child: GradientPanel(
              index: 1,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      LiquidGlassButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.favorite_rounded),
                      ),
                      LiquidGlassButton(
                        onPressed: () {},
                        child: const Text('Themed'),
                      ),
                      const LiquidGlass(child: GlassLabel('LiquidGlass')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ThemedSegments(),
                ],
              ),
            ),
          ),
        ),
        const DemoSection(
          title: 'Outside the theme',
          description: 'Same widgets, global settings.',
          child: GradientPanel(
            index: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [LiquidGlass(child: GlassLabel('LiquidGlass'))],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemedSegments extends StatefulWidget {
  const _ThemedSegments();

  @override
  State<_ThemedSegments> createState() => _ThemedSegmentsState();
}

class _ThemedSegmentsState extends State<_ThemedSegments> {
  int _value = 0;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSegmentedControl<int>(
      value: _value,
      onValueChanged: (v) => setState(() => _value = v),
      children: const {0: Text('One'), 1: Text('Two'), 2: Text('Three')},
    );
  }
}
