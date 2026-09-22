import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';

import '../common.dart';

/// Ready-made glass components.
class ComponentsPage extends StatefulWidget {
  const ComponentsPage({super.key, required this.report});

  final ActionReporter report;

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> {
  String _period = 'week';
  String _view = 'grid';
  bool _wifi = true;
  bool _airplane = false;
  double _volume = 0.6;
  double _brightness = 0.4;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final fg = Theme.of(context).colorScheme.onSurface;

    return DemoPage(
      children: [
        DemoSection(
          title: 'LiquidGlassButton',
          description:
              'glass, tinted and prominent styles; null onPressed '
              'disables it.',
          child: GradientPanel(
            index: 1,
            // Performance: the seven buttons share one native glass view
            // (spacing 0: they never merge). Glass in a group still refracts
            // what is painted before the group, here the panel gradient.
            child: LiquidGlassGroup(
              spacing: 0,
              child: Column(
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      LiquidGlassButton(
                        onPressed: () => report('Glass button'),
                        child: const Text('Glass'),
                      ),
                      LiquidGlassButton(
                        style: LiquidGlassButtonStyle.tinted,
                        onPressed: () => report('Tinted button'),
                        child: const Text('Tinted'),
                      ),
                      LiquidGlassButton(
                        style: LiquidGlassButtonStyle.prominent,
                        onPressed: () => report('Prominent button'),
                        child: const Text('Prominent'),
                      ),
                      const LiquidGlassButton(
                        onPressed: null,
                        child: Text('Disabled'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LiquidGlassButton.icon(
                        semanticLabel: 'Share',
                        onPressed: () => report('Share'),
                        icon: const Icon(Icons.ios_share_rounded),
                      ),
                      const SizedBox(width: 12),
                      LiquidGlassButton.icon(
                        style: LiquidGlassButtonStyle.tinted,
                        color: Colors.pink,
                        semanticLabel: 'Like',
                        onPressed: () => report('Like'),
                        icon: const Icon(Icons.favorite_rounded),
                      ),
                      const SizedBox(width: 12),
                      LiquidGlassButton.icon(
                        style: LiquidGlassButtonStyle.prominent,
                        size: 56,
                        semanticLabel: 'Add',
                        onPressed: () => report('Add'),
                        icon: const Icon(Icons.add_rounded, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        DemoSection(
          title: 'LiquidGlassSegmentedControl',
          description: 'Tap or drag across: the thumb lifts into a lens.',
          child: GradientPanel(
            index: 5,
            child: Column(
              children: [
                LiquidGlassSegmentedControl<String>(
                  value: _period,
                  onValueChanged: (v) {
                    setState(() => _period = v);
                    report('Period: $v');
                  },
                  children: const {
                    'day': Text('Day'),
                    'week': Text('Week'),
                    'month': Text('Month'),
                    'year': Text('Year'),
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 180,
                  child: LiquidGlassSegmentedControl<String>(
                    value: _view,
                    semanticLabels: const ['Grid', 'List'],
                    onValueChanged: (v) => setState(() => _view = v),
                    children: const {
                      'grid': Icon(Icons.grid_view_rounded),
                      'list': Icon(Icons.view_list_rounded),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        DemoSection(
          title: 'LiquidGlassSwitch & LiquidGlassSlider',
          description: 'Touch the thumbs: they turn into glass lenses.',
          child: GradientPanel(
            index: 2,
            child: LiquidGlass(
              interactive: false,
              shape: const LiquidGlassShape.roundedRect(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: fg, fontSize: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('Wi-Fi')),
                          LiquidGlassSwitch(
                            value: _wifi,
                            semanticLabel: 'Wi-Fi',
                            onChanged: (v) => setState(() => _wifi = v),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Expanded(child: Text('Airplane mode')),
                          LiquidGlassSwitch(
                            value: _airplane,
                            activeColor: Colors.orange,
                            semanticLabel: 'Airplane mode',
                            onChanged: (v) => setState(() => _airplane = v),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Expanded(child: Text('Disabled')),
                          LiquidGlassSwitch(value: true, onChanged: null),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.volume_up_rounded, color: fg),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LiquidGlassSlider(
                              value: _volume,
                              onChanged: (v) => setState(() => _volume = v),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.light_mode_rounded, color: fg),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LiquidGlassSlider(
                              value: _brightness,
                              divisions: 5,
                              activeColor: Colors.orange,
                              onChanged: (v) => setState(() => _brightness = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        DemoSection(
          title: 'LiquidGlassSearchBar',
          description: 'Focus it: a round glass close button appears.',
          child: GradientPanel(
            index: 3,
            child: LiquidGlassSearchBar(
              hintText: 'Search photos',
              trailing: const Icon(Icons.mic_rounded),
              onSubmitted: (v) => report('Search: $v'),
            ),
          ),
        ),

        DemoSection(
          title: 'Sheets & navigation',
          description:
              'A floating glass bottom sheet, and a pushed page '
              'using LiquidGlassAppBar (automatic back button, scroll edge '
              'effect).',
          child: GradientPanel(
            index: 6,
            // One native glass view for both buttons.
            child: LiquidGlassGroup(
              spacing: 0,
              child: Wrap(
                spacing: 10,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  LiquidGlassButton(
                    onPressed: () => _showSheet(context),
                    child: const Text('Open sheet'),
                  ),
                  LiquidGlassButton(
                    style: LiquidGlassButtonStyle.prominent,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _AppBarDemoPage(),
                      ),
                    ),
                    child: const Text('Push app bar page'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSheet(BuildContext context) {
    showLiquidGlassBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, label) in const [
              (Icons.copy_rounded, 'Copy'),
              (Icons.ios_share_rounded, 'Share'),
              (Icons.favorite_border_rounded, 'Favorite'),
              (Icons.delete_outline_rounded, 'Delete'),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () {
                  Navigator.pop(context);
                  widget.report(label);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AppBarDemoPage extends StatelessWidget {
  const _AppBarDemoPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: LiquidGlassAppBar(
        title: const Text('Photos'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final padding = MediaQuery.paddingOf(context);
          return GridView.builder(
            padding: EdgeInsets.fromLTRB(
              4,
              padding.top + 8,
              4,
              padding.bottom + 8,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 60,
            itemBuilder: (context, i) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: demoGradient(i),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        },
      ),
    );
  }
}
