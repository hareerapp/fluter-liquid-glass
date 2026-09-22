import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';

import '../common.dart';

/// Live controls for every value of [LiquidGlassService].
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _tints = <(Color?, String)>[
    (null, 'None'),
    (Colors.blue, 'Blue'),
    (Colors.pink, 'Pink'),
    (Colors.green, 'Green'),
    (Colors.orange, 'Orange'),
  ];

  static const _shapes = <(LiquidGlassShape, String)>[
    (LiquidGlassShape.capsule(), 'Capsule'),
    (LiquidGlassShape.roundedRect(16), 'Rounded 16'),
    (LiquidGlassShape.rect(), 'Rect'),
  ];

  @override
  Widget build(BuildContext context) {
    final service = LiquidGlassService.instance;
    final fg = Theme.of(context).colorScheme.onSurface;

    return ListenableBuilder(
      listenable: Listenable.merge([
        service,
        themeMode,
        rtlLayout,
        reduceMotion,
      ]),
      builder: (context, _) {
        final s = service.settings;
        return DemoPage(
          children: [
            // Live preview: default glass, driven only by the service.
            Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: demoGradient(6),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  LiquidGlass(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Icon(Icons.bolt_rounded, color: fg),
                    ),
                  ),
                  LiquidGlass(child: GlassLabel('Preview', color: fg)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _Group(
              title: 'Layout & accessibility',
              children: [
                _SwitchRow(
                  label: 'Right-to-left layout',
                  value: rtlLayout.value,
                  onChanged: (v) => rtlLayout.value = v,
                ),
                _SwitchRow(
                  label: 'Reduce Motion (simulated)',
                  value: reduceMotion.value,
                  onChanged: (v) => reduceMotion.value = v,
                ),
                const SizedBox(height: 8),
                Text(
                  'Device: ${service.capabilities}\n'
                  'isLiquidGlassSupported: ${service.isLiquidGlassSupported}',
                  style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
                ),
              ],
            ),

            _Group(
              title: 'Appearance',
              children: [
                _Label('App theme (ThemeMode)'),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                    ),
                  ],
                  selected: {themeMode.value},
                  onSelectionChanged: (v) => themeMode.value = v.first,
                ),
                _Label('Glass brightness — setBrightness()'),
                SegmentedButton<LiquidGlassBrightness>(
                  showSelectedIcon: false,
                  segments: [
                    for (final b in LiquidGlassBrightness.values)
                      ButtonSegment(value: b, label: Text(b.name)),
                  ],
                  selected: {s.brightness},
                  onSelectionChanged: (v) => service.setBrightness(v.first),
                ),
                _Label('Style — setStyle()'),
                SegmentedButton<LiquidGlassStyle>(
                  segments: [
                    for (final style in LiquidGlassStyle.values)
                      ButtonSegment(value: style, label: Text(style.name)),
                  ],
                  selected: {s.style},
                  onSelectionChanged: (v) => service.setStyle(v.first),
                ),
                // native (default, fastest on iPhone), flutter (Flutter-drawn
                // glass), auto (Flutter-drawn inside scrolling lists).
                _Label('Renderer — setRenderer()'),
                SegmentedButton<LiquidGlassRenderer>(
                  segments: [
                    for (final r in LiquidGlassRenderer.values)
                      ButtonSegment(value: r, label: Text(r.name)),
                  ],
                  selected: {s.renderer},
                  onSelectionChanged: (v) => service.setRenderer(v.first),
                ),
                _Slider(
                  label: 'Opacity — setOpacity()',
                  value: s.opacity,
                  onChanged: service.setOpacity,
                ),
              ],
            ),

            _Group(
              title: 'Tint',
              children: [
                _Label('Color — setTint()'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (color, name) in _tints)
                      ChoiceChip(
                        label: Text(name),
                        avatar: color == null
                            ? null
                            : CircleAvatar(backgroundColor: color),
                        selected: s.tintColor == color,
                        onSelected: (_) => service.setTint(color),
                      ),
                  ],
                ),
                _Slider(
                  label: 'Tint opacity',
                  value: s.tintOpacity,
                  onChanged: (v) => service.setTint(s.tintColor, opacity: v),
                ),
              ],
            ),

            _Group(
              title: 'Interaction',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Interactive — setInteractive()'),
                  value: s.interactive,
                  onChanged: service.setInteractive,
                ),
                _SwitchRow(
                  label: 'Collapse tab bar on scroll — setCollapseOnScroll()',
                  value: s.collapseOnScroll,
                  onChanged: service.setCollapseOnScroll,
                ),
                _Slider(
                  label: 'Strength — setInteractionStrength()',
                  value: s.interactionStrength,
                  max: 2,
                  onChanged: s.interactive
                      ? service.setInteractionStrength
                      : null,
                ),
              ],
            ),

            _Group(
              title: 'Shape & platforms',
              children: [
                _Label('Default shape — settings.shape'),
                SegmentedButton<LiquidGlassShape>(
                  showSelectedIcon: false,
                  segments: [
                    for (final (shape, name) in _shapes)
                      ButtonSegment(value: shape, label: Text(name)),
                  ],
                  selected: {s.shape},
                  onSelectionChanged: (v) =>
                      service.update((s) => s.copyWith(shape: v.first)),
                ),
                _Label('Non-iOS fallback — setFallback()'),
                SegmentedButton<LiquidGlassFallback>(
                  segments: [
                    for (final f in LiquidGlassFallback.values)
                      ButtonSegment(value: f, label: Text(f.name)),
                  ],
                  selected: {s.fallback},
                  onSelectionChanged: (v) => service.setFallback(v.first),
                ),
                // Blur of Flutter-drawn glass (in lists on iOS / macOS, and
                // the frosted fallback on other platforms).
                _Slider(
                  label: 'Flutter glass blur — fallbackBlurSigma',
                  value: s.fallbackBlurSigma,
                  max: 40,
                  onChanged:
                      LiquidGlassService.isNativePlatform ||
                          s.fallback == LiquidGlassFallback.frosted
                      ? (v) => service.update(
                          (s) => s.copyWith(fallbackBlurSigma: v),
                        )
                      : null,
                ),
                if (LiquidGlassService.isNativePlatform)
                  const Text(
                    'Fallback only applies on Android, web and desktop.',
                  ),
              ],
            ),

            _Group(
              title: 'Global',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enabled — setEnabled()'),
                  value: s.enabled,
                  onChanged: service.setEnabled,
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: service.reset,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('reset()'),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  _describe(s),
                  style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _describe(LiquidGlassSettings s) {
    String color(Color? c) => c == null
        ? 'null'
        : '0x${c.toARGB32().toRadixString(16).padLeft(8, '0')}';
    return 'LiquidGlassSettings(\n'
        '  enabled: ${s.enabled},\n'
        '  style: ${s.style.name},\n'
        '  opacity: ${s.opacity.toStringAsFixed(2)},\n'
        '  tintColor: ${color(s.tintColor)},\n'
        '  tintOpacity: ${s.tintOpacity.toStringAsFixed(2)},\n'
        '  interactive: ${s.interactive},\n'
        '  interactionStrength: ${s.interactionStrength.toStringAsFixed(2)},\n'
        '  brightness: ${s.brightness.name},\n'
        '  shape: ${s.shape},\n'
        '  fallback: ${s.fallback.name},\n'
        '  fallbackBlurSigma: ${s.fallbackBlurSigma.toStringAsFixed(1)},\n'
        '  collapseOnScroll: ${s.collapseOnScroll},\n'
        '  renderer: ${s.renderer.name},\n'
        ')';
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Uses the package's own glass switch.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        LiquidGlassSwitch(
          value: value,
          semanticLabel: label,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 1,
  });

  final String label;
  final double value;
  final double max;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('$label: ${value.toStringAsFixed(2)}'),
        Slider(value: value.clamp(0, max), max: max, onChanged: onChanged),
      ],
    );
  }
}
