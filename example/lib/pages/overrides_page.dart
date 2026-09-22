import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';

import '../common.dart';

/// Per-widget parameters that override the global service settings.
class OverridesPage extends StatelessWidget {
  const OverridesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoSection(
          title: '.liquidGlass() shorthand',
          description:
              'Call .liquidGlass() on any widget instead of wrapping it. '
              'It takes the same per-widget parameters as LiquidGlass.',
          child: GlassGrid(
            children: [
              GlassTile(
                label: "const GlassLabel('Default').liquidGlass()",
                index: 2,
                child: const GlassLabel('Default').liquidGlass(),
              ),
              GlassTile(
                label: 'tintColor: purple, style: clear',
                index: 2,
                child: const GlassLabel('Shorthand', color: Colors.white)
                    .liquidGlass(
                      tintColor: Colors.purple,
                      style: LiquidGlassStyle.clear,
                    ),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'renderer',
          description:
              'native (default) is the real system glass. flutter draws it '
              'with Flutter, for places a native view cannot go. It is '
              'slower on iPhone.',
          child: GlassGrid(
            children: [
              GlassTile(
                label: 'renderer: LiquidGlassRenderer.native',
                index: 3,
                child: LiquidGlass(
                  renderer: LiquidGlassRenderer.native,
                  child: GlassLabel('Native'),
                ),
              ),
              GlassTile(
                label: 'renderer: LiquidGlassRenderer.flutter',
                index: 3,
                child: LiquidGlass(
                  renderer: LiquidGlassRenderer.flutter,
                  child: GlassLabel('Flutter'),
                ),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'style',
          description: 'Regular glass, or the more transparent clear glass.',
          child: GlassGrid(
            children: [
              GlassTile(
                label: 'style: LiquidGlassStyle.regular',
                index: 0,
                child: LiquidGlass(
                  style: LiquidGlassStyle.regular,
                  child: GlassLabel('Regular'),
                ),
              ),
              GlassTile(
                label: 'style: LiquidGlassStyle.clear',
                index: 0,
                child: LiquidGlass(
                  style: LiquidGlassStyle.clear,
                  child: GlassLabel('Clear'),
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'opacity',
          description: 'How visible the glass material is (0 to 1).',
          child: GlassGrid(
            children: [
              for (final opacity in const [1.0, 0.6, 0.3, 0.0])
                GlassTile(
                  label: 'opacity: $opacity',
                  index: 1,
                  child: LiquidGlass(
                    opacity: opacity,
                    child: GlassLabel('$opacity'),
                  ),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'tintColor + tintOpacity',
          description: 'Colored glass, like iOS prominent buttons.',
          child: GlassGrid(
            children: [
              for (final (color, name, opacity) in const [
                (Colors.blue, 'blue', 0.3),
                (Colors.pink, 'pink', 0.5),
                (Colors.green, 'green', 0.7),
                (Colors.orange, 'orange', 1.0),
              ])
                GlassTile(
                  label: 'tintColor: $name, tintOpacity: $opacity',
                  index: 5,
                  child: LiquidGlass(
                    tintColor: color,
                    tintOpacity: opacity,
                    child: const GlassLabel('Tinted', color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'interactive + interactionStrength',
          description: 'Press and drag each one to compare.',
          child: GlassGrid(
            children: [
              const GlassTile(
                label: 'interactive: false',
                index: 2,
                child: LiquidGlass(
                  interactive: false,
                  child: GlassLabel('Static'),
                ),
              ),
              for (final strength in const [0.5, 1.0, 2.0])
                GlassTile(
                  label: 'interactionStrength: $strength',
                  index: 2,
                  child: LiquidGlass(
                    interactionStrength: strength,
                    child: GlassLabel('× $strength'),
                  ),
                ),
            ],
          ),
        ),
        const DemoSection(
          title: 'brightness',
          description:
              'auto follows the app theme, system follows iOS, light / dark '
              'force one look.',
          child: GlassGrid(
            children: [
              GlassTile(
                label: 'LiquidGlassBrightness.auto',
                index: 3,
                child: LiquidGlass(
                  brightness: LiquidGlassBrightness.auto,
                  child: GlassLabel('Auto'),
                ),
              ),
              GlassTile(
                label: 'LiquidGlassBrightness.system',
                index: 3,
                child: LiquidGlass(
                  brightness: LiquidGlassBrightness.system,
                  child: GlassLabel('System'),
                ),
              ),
              GlassTile(
                label: 'LiquidGlassBrightness.light',
                index: 3,
                child: LiquidGlass(
                  brightness: LiquidGlassBrightness.light,
                  child: GlassLabel('Light', color: Colors.black87),
                ),
              ),
              GlassTile(
                label: 'LiquidGlassBrightness.dark',
                index: 3,
                child: LiquidGlass(
                  brightness: LiquidGlassBrightness.dark,
                  child: GlassLabel('Dark', color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'enabled',
          description: 'enabled: false renders only the child.',
          child: GlassGrid(
            children: [
              GlassTile(
                label: 'enabled: true',
                index: 4,
                child: LiquidGlass(enabled: true, child: GlassLabel('On')),
              ),
              GlassTile(
                label: 'enabled: false',
                index: 4,
                child: LiquidGlass(enabled: false, child: GlassLabel('Off')),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'settings: object',
          description:
              'A full LiquidGlassSettings for one widget. It ignores the '
              'global service, so changes on the Settings page do not touch '
              'it.',
          child: GlassGrid(
            children: [
              GlassTile(
                label: 'settings: LiquidGlassSettings(clear, purple, ×1.6)',
                index: 6,
                child: LiquidGlass(
                  settings: LiquidGlassSettings(
                    style: LiquidGlassStyle.clear,
                    tintColor: Colors.deepPurple,
                    tintOpacity: 0.4,
                    interactionStrength: 1.6,
                    fallback: LiquidGlassFallback.frosted,
                  ),
                  child: GlassLabel('Own settings', color: Colors.white),
                ),
              ),
              GlassTile(
                label: 'settings: + override opacity: 0.5',
                index: 6,
                child: LiquidGlass(
                  settings: LiquidGlassSettings(
                    tintColor: Colors.teal,
                    fallback: LiquidGlassFallback.frosted,
                  ),
                  opacity: 0.5,
                  child: GlassLabel('Mixed', color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
