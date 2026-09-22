import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';

import '../common.dart';

/// Tappable glass: the child handles its own gestures.
class ControlsPage extends StatefulWidget {
  const ControlsPage({super.key, required this.report});

  final ActionReporter report;

  @override
  State<ControlsPage> createState() => _ControlsPageState();
}

class _ControlsPageState extends State<ControlsPage> {
  bool _playing = false;
  int _segment = 0;

  static const _segments = ['Day', 'Week', 'Month'];

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final report = widget.report;

    return DemoPage(
      children: [
        _PlatformCard(fg: fg),
        const SizedBox(height: 28),

        DemoSection(
          title: 'Press, hold & drag',
          description:
              'Glass grows under the finger, stretches toward a drag, glows '
              'at the touch point and springs back on release.',
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: demoGradient(0),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: LiquidGlass(
              shape: const LiquidGlassShape.roundedRect(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: Text(
                  'Press, hold & drag me',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        ),

        DemoSection(
          title: 'Any tappable child',
          description:
              'LiquidGlass has no onTap — put GestureDetector, InkWell or any '
              'button inside, it keeps working.',
          child: GlassGrid(
            children: [
              GlassTile(
                label: 'GestureDetector + circle Container',
                index: 1,
                child: LiquidGlass(
                  child: GestureDetector(
                    onTap: () => report('GestureDetector tap'),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Icon(Icons.touch_app_rounded, color: fg),
                    ),
                  ),
                ),
              ),
              GlassTile(
                label: 'IconButton',
                index: 2,
                child: LiquidGlass(
                  child: IconButton(
                    onPressed: () => report('IconButton pressed'),
                    padding: const EdgeInsets.all(16),
                    icon: Icon(Icons.favorite_rounded, color: fg),
                  ),
                ),
              ),
              GlassTile(
                label: 'InkWell',
                index: 3,
                child: LiquidGlass(
                  child: InkWell(
                    onTap: () => report('InkWell tap'),
                    customBorder: const StadiumBorder(),
                    child: GlassLabel('InkWell', color: fg),
                  ),
                ),
              ),
              GlassTile(
                label: 'TextButton',
                index: 4,
                child: LiquidGlass(
                  child: TextButton(
                    onPressed: () => report('TextButton pressed'),
                    style: TextButton.styleFrom(
                      foregroundColor: fg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                    ),
                    child: const Text('TextButton'),
                  ),
                ),
              ),
              GlassTile(
                label: 'GestureDetector onLongPress',
                index: 5,
                child: LiquidGlass(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () => report('Long press'),
                    child: GlassLabel('Hold me', color: fg),
                  ),
                ),
              ),
              GlassTile(
                label: 'GestureDetector onDoubleTap',
                index: 6,
                child: LiquidGlass(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () => report('Double tap'),
                    child: GlassLabel('Double tap', color: fg),
                  ),
                ),
              ),
            ],
          ),
        ),

        DemoSection(
          title: 'Floating toolbar',
          description: 'One capsule of glass with several buttons inside.',
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: demoGradient(7),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: LiquidGlass(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: IconTheme(
                  data: IconThemeData(color: fg),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => report('Previous'),
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      IconButton(
                        iconSize: 34,
                        onPressed: () {
                          setState(() => _playing = !_playing);
                          report(_playing ? 'Play' : 'Pause');
                        },
                        icon: Icon(
                          _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      IconButton(
                        onPressed: () => report('Next'),
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        DemoSection(
          title: 'Segmented control',
          description: 'A glass track with a sliding selection pill.',
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: demoGradient(5),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: LiquidGlass(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: SizedBox(
                  width: 270,
                  height: 44,
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        alignment: Alignment(-1 + _segment * 1.0, 0),
                        child: FractionallySizedBox(
                          widthFactor: 1 / _segments.length,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              shape: const StadiumBorder(),
                              color: fg.withValues(alpha: 0.14),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < _segments.length; i++)
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() => _segment = i);
                                  report('Segment ${_segments[i]}');
                                },
                                child: Center(
                                  child: Text(
                                    _segments[i],
                                    style: TextStyle(
                                      color: fg,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
          title: 'Static glass card',
          description:
              'interactive: false — for panels and cards that should not '
              'move when touched.',
          child: Container(
            decoration: BoxDecoration(
              gradient: demoGradient(3),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.all(20),
            child: LiquidGlass(
              interactive: false,
              shape: const LiquidGlassShape.roundedRect(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded, size: 44, color: fg),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '24° Sunny',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                          Text(
                            'Glass card with regular content',
                            style: TextStyle(color: fg),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({required this.fg});

  final Color fg;

  @override
  Widget build(BuildContext context) {
    final service = LiquidGlassService.instance;
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    return Container(
      decoration: BoxDecoration(
        gradient: demoGradient(1),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(16),
      child: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final supported = service.isLiquidGlassSupported;
          final native = LiquidGlassService.isNativePlatform;
          final version = service.capabilities.osVersion;
          return LiquidGlass(
            interactive: false,
            shape: const LiquidGlassShape.roundedRect(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    supported ? Icons.check_circle_rounded : Icons.info_rounded,
                    color: fg,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      supported
                          ? 'Running on $platform $version: native Liquid Glass.'
                          : native
                          ? 'Running on $platform $version: Liquid Glass needs '
                                '26+, showing the system material blur.'
                          : 'Running on $platform: no native glass. Turn on the '
                                'frosted fallback in Settings to see an '
                                'approximation.',
                      style: TextStyle(color: fg, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
