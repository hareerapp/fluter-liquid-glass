import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:liquid_design/liquid_design.dart';

import '../common.dart';

/// LiquidGlassGroup: morphing glass and one native view for many shapes.
class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key, required this.report});

  final ActionReporter report;

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  bool _expanded = false;
  double _spacing = 24;
  Offset _blob = const Offset(16, 16);

  static const _actions = [
    (Icons.photo_camera_rounded, 'Camera'),
    (Icons.mic_rounded, 'Voice'),
    (Icons.edit_rounded, 'Note'),
  ];

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;

    return DemoPage(
      children: [
        DemoSection(
          title: 'Morphing',
          description:
              'Inside a LiquidGlassGroup, glass shapes closer than '
              '`spacing` melt together and split apart like liquid.',
          child: GradientPanel(
            index: 0,
            padding: const EdgeInsets.all(16),
            child: LiquidGlassGroup(
              spacing: _spacing,
              child: SizedBox(
                height: 72,
                child: Stack(
                  children: [
                    for (var i = 0; i < _actions.length; i++)
                      AnimatedPositionedDirectional(
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutBack,
                        start: _expanded ? 72.0 * (i + 1) : 4,
                        top: 4,
                        child: LiquidGlass(
                          child: IconButton(
                            padding: const EdgeInsets.all(14),
                            tooltip: _actions[i].$2,
                            onPressed: () => widget.report(_actions[i].$2),
                            // Group glass sits under all Flutter content,
                            // so hide icons while tucked behind the button.
                            icon: AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              opacity: _expanded ? 1 : 0,
                              child: Icon(_actions[i].$1, color: fg),
                            ),
                          ),
                        ),
                      ),
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      child: LiquidGlass(
                        tintColor: Theme.of(context).colorScheme.primary,
                        tintOpacity: 0.9,
                        child: GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 400),
                              turns: _expanded ? 0.125 : 0,
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        DemoSection(
          title: 'Drag to merge',
          description: 'Drag the small drop towards the big one.',
          child: GradientPanel(
            index: 7,
            padding: EdgeInsets.zero,
            child: LiquidGlassGroup(
              spacing: _spacing,
              child: SizedBox(
                height: 200,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Positioned(
                        left: constraints.maxWidth / 2 - 55,
                        top: 45,
                        child: const LiquidGlass(
                          interactive: false,
                          shape: LiquidGlassShape.circle(),
                          child: SizedBox.square(dimension: 110),
                        ),
                      ),
                      Positioned(
                        left: _blob.dx,
                        top: _blob.dy,
                        child: GestureDetector(
                          onPanUpdate: (d) => setState(() {
                            _blob = Offset(
                              (_blob.dx + d.delta.dx).clamp(
                                0,
                                constraints.maxWidth - 64,
                              ),
                              (_blob.dy + d.delta.dy).clamp(0, 200 - 64),
                            );
                          }),
                          child: const LiquidGlass(
                            shape: LiquidGlassShape.circle(),
                            child: SizedBox.square(dimension: 64),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        DemoSection(
          title: 'spacing: ${_spacing.round()}',
          description: 'How close shapes must be before they merge.',
          child: LiquidGlassSlider(
            value: _spacing,
            max: 60,
            onChanged: (v) => setState(() => _spacing = v),
          ),
        ),

        DemoSection(
          title: 'Grouped toolbar',
          description:
              'Close buttons in one group read as a single piece of '
              'glass.',
          child: GradientPanel(
            index: 5,
            child: Center(
              child: LiquidGlassGroup(
                spacing: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final icon in const [
                      Icons.format_bold_rounded,
                      Icons.format_italic_rounded,
                      Icons.format_underline_rounded,
                      Icons.format_list_bulleted_rounded,
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: LiquidGlassButton.icon(
                          onPressed: () => widget.report(icon.toString()),
                          icon: Icon(icon),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const DemoSection(
          title: 'Performance',
          description:
              '40 glass chips in a scrolling grid. "Individual" '
              'creates 40 native views, "Grouped" draws them all in one. '
              'Run the benchmark to auto-scroll and measure frame times.',
          child: _Benchmark(),
        ),
      ],
    );
  }
}

class _Benchmark extends StatefulWidget {
  const _Benchmark();

  @override
  State<_Benchmark> createState() => _BenchmarkState();
}

class _BenchmarkState extends State<_Benchmark> {
  static const _count = 40;
  bool _grouped = true;
  bool _running = false;
  final _controller = ScrollController();
  final _results = <bool, String>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_running) return;
    final grouped = _grouped;
    setState(() => _running = true);
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(collect);
    final clock = Stopwatch()..start();

    final max = _controller.position.maxScrollExtent;
    for (var i = 0; i < 2; i++) {
      await _controller.animateTo(
        max,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
      );
      await _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
      );
    }
    clock.stop();
    // Let the last timings arrive.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    SchedulerBinding.instance.removeTimingsCallback(collect);

    if (!mounted) return;
    setState(() {
      _running = false;
      _results[grouped] = _summary(timings, clock.elapsed);
    });
  }

  static String _summary(List<FrameTiming> timings, Duration elapsed) {
    if (timings.isEmpty) return 'no frames';
    String avg(Duration Function(FrameTiming) f) =>
        (timings.map((t) => f(t).inMicroseconds).reduce((a, b) => a + b) /
                timings.length /
                1000)
            .toStringAsFixed(2);
    final fps = timings.length / (elapsed.inMilliseconds / 1000);
    return '${fps.toStringAsFixed(0)} fps · '
        'build ${avg((t) => t.buildDuration)} ms · '
        'raster ${avg((t) => t.rasterDuration)} ms';
  }

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    Widget grid = GridView.builder(
      controller: _controller,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _count,
      // No per-chip backgrounds: in a group, all Flutter content is drawn
      // above the group's glass, so the glass needs a background outside
      // the group (the gradient below).
      itemBuilder: (context, i) => Center(
        child: LiquidGlass(
          child: SizedBox.square(
            dimension: 56,
            child: Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
    if (_grouped) grid = LiquidGlassGroup(child: grid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiquidGlassSegmentedControl<bool>(
          value: _grouped,
          onValueChanged: (v) => setState(() => _grouped = v),
          children: const {
            false: Text('Individual (40 views)'),
            true: Text('Grouped (1 view)'),
          },
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: demoGradient(3)),
              // New key per mode so the grid is rebuilt from scratch.
              child: KeyedSubtree(key: ValueKey(_grouped), child: grid),
            ),
          ),
        ),
        const SizedBox(height: 12),
        LiquidGlassButton(
          style: LiquidGlassButtonStyle.prominent,
          onPressed: _running ? null : _run,
          child: Text(_running ? 'Running…' : 'Run benchmark'),
        ),
        const SizedBox(height: 8),
        for (final grouped in const [false, true])
          if (_results[grouped] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${grouped ? 'Grouped' : 'Individual'}: ${_results[grouped]}',
                style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
              ),
            ),
      ],
    );
  }
}
