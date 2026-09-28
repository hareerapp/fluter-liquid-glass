import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';

void main() => runApp(const ReadmeShots());

const _star = '''
<svg viewBox="0 0 24 24"><polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26"/></svg>''';

const _items = [
  LiquidGlassNavItem(icon: Icon(Icons.home_rounded), label: 'Home'),
  LiquidGlassNavItem(icon: Icon(Icons.search_rounded), label: 'Search'),
  LiquidGlassNavItem(icon: Icon(Icons.favorite_rounded), label: 'Saved'),
  LiquidGlassNavItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
];

const _iconItems = [
  LiquidGlassNavItem(icon: Icon(Icons.home_rounded)),
  LiquidGlassNavItem(icon: Icon(Icons.search_rounded)),
  LiquidGlassNavItem(icon: Icon(Icons.favorite_rounded)),
  LiquidGlassNavItem(icon: Icon(Icons.person_rounded)),
];

class Scene {
  const Scene(this.name, this.builder, {this.dark = false});

  final String name;
  final WidgetBuilder builder;
  final bool dark;
}

final scenes = <Scene>[
  Scene('nav_labels', (_) => const _NavDemo(items: _items)),
  Scene('nav_icons', (_) => const _NavDemo(items: _iconItems)),
  Scene('nav_collapsed', (_) => const _NavDemo(items: _items, collapsed: true)),
  Scene('nav_action', (_) => const _NavDemo(items: _items, action: true)),
  Scene(
    'nav_tinted',
    (_) => _NavDemo(
      items: _items,
      activeColor: Colors.white,
      inactiveColor: Colors.white70,
      settings: LiquidGlassService.instance.settings.copyWith(
        tintColor: const Color(0xFF6A1B9A),
        tintOpacity: 0.55,
      ),
    ),
  ),
  Scene('nav_dark', (_) => const _NavDemo(items: _items), dark: true),
  Scene('buttons', (_) => const _Buttons()),
  Scene('shapes', (_) => const _Shapes()),
  Scene('styles', (_) => const _Styles()),
  Scene('app_bar', (_) => const _AppBarDemo()),
  Scene('segmented', (_) => const _Segmented()),
  Scene('controls', (_) => const _Controls()),
  Scene('search', (_) => const _Search()),
  Scene('sheet', (_) => const _Sheet()),
  Scene('group', (_) => const _Group()),
];

class ReadmeShots extends StatefulWidget {
  const ReadmeShots({super.key});

  @override
  State<ReadmeShots> createState() => _ReadmeShotsState();
}

class _ReadmeShotsState extends State<ReadmeShots> {
  int _index = const int.fromEnvironment('SCENE');

  @override
  Widget build(BuildContext context) {
    final scene = scenes[_index];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: scene.dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 120,
              height: 280,
              child: _Stage(
                key: ValueKey(scene.name),
                dark: scene.dark,
                child: Builder(builder: scene.builder),
              ),
            ),
            Positioned(
              left: 0,
              top: 60,
              width: 120,
              height: 50,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    setState(() => _index = (_index + 1) % scenes.length),
                child: Center(
                  child: Text(
                    '${_index + 1}/${scenes.length} ${scene.name}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({super.key, required this.dark, required this.child});

  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = dark
        ? const [Color(0xFF1A1033), Color(0xFF2B1B5A), Color(0xFF0E3A5C)]
        : const [Color(0xFFFFB199), Color(0xFFB9A7FF), Color(0xFF7FD6FF)];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ..._blobs(dark),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }

  List<Widget> _blobs(bool dark) {
    Widget blob(double l, double t, double s, Color c) => Positioned(
      left: l,
      top: t,
      width: s,
      height: s,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
        ),
      ),
    );
    return [
      blob(
        -40,
        -30,
        200,
        dark ? const Color(0xAA7C4DFF) : const Color(0xCCFF6F91),
      ),
      blob(
        220,
        40,
        220,
        dark ? const Color(0x9900B8D4) : const Color(0xCC6C63FF),
      ),
      blob(
        90,
        150,
        180,
        dark ? const Color(0x88FF4081) : const Color(0xCCFFC75F),
      ),
    ];
  }
}

class _NavDemo extends StatefulWidget {
  const _NavDemo({
    required this.items,
    this.collapsed = false,
    this.action = false,
    this.activeColor,
    this.inactiveColor,
    this.settings,
  });

  final List<LiquidGlassNavItem> items;
  final bool collapsed;
  final bool action;
  final Color? activeColor;
  final Color? inactiveColor;
  final LiquidGlassSettings? settings;

  @override
  State<_NavDemo> createState() => _NavDemoState();
}

class _NavDemoState extends State<_NavDemo> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final bar = LiquidGlassNavigationBar(
      currentIndex: _tab,
      onTap: (i) => setState(() => _tab = i),
      collapsed: widget.collapsed,
      onExpand: () {},
      activeColor: widget.activeColor,
      inactiveColor: widget.inactiveColor,
      settings: widget.settings,
      items: widget.items,
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: bar),
          if (widget.action) ...[
            const SizedBox(width: 12),
            LiquidGlassButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            LiquidGlassButton(onPressed: () {}, child: const Text('Glass')),
            LiquidGlassButton(
              style: LiquidGlassButtonStyle.tinted,
              onPressed: () {},
              child: const Text('Tinted'),
            ),
            LiquidGlassButton(
              style: LiquidGlassButtonStyle.prominent,
              onPressed: () {},
              child: const Text('Prominent'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LiquidGlassButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.ios_share_rounded),
            ),
            const SizedBox(width: 16),
            LiquidGlassButton.icon(
              style: LiquidGlassButtonStyle.tinted,
              onPressed: () {},
              icon: const Icon(Icons.favorite_rounded),
            ),
            const SizedBox(width: 16),
            LiquidGlassButton.icon(
              style: LiquidGlassButtonStyle.prominent,
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.width = 96, this.height = 56});

  final String text;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
  );
}

class _Shapes extends StatelessWidget {
  const _Shapes();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            LiquidGlass(
              shape: LiquidGlassShape.capsule(),
              child: _Label('capsule', width: 104, height: 48),
            ),
            LiquidGlass(
              shape: LiquidGlassShape.circle(),
              child: _Label('circle', width: 72, height: 72),
            ),
            LiquidGlass(
              shape: LiquidGlassShape.roundedRect(16),
              child: _Label('rounded', width: 88, height: 72),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const LiquidGlass(
              shape: LiquidGlassShape.rect(),
              child: _Label('rect', width: 88, height: 64),
            ),
            LiquidGlass(
              shape: LiquidGlassShape.svg(_star),
              child: const SizedBox(width: 80, height: 80),
            ),
            const LiquidGlassSvg.asset('assets/h_logo.svg', height: 80),
          ],
        ),
      ],
    );
  }
}

class _Styles extends StatelessWidget {
  const _Styles();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        LiquidGlass(
          shape: LiquidGlassShape.roundedRect(24),
          child: _Label('regular', height: 110),
        ),
        LiquidGlass(
          style: LiquidGlassStyle.clear,
          shape: LiquidGlassShape.roundedRect(24),
          child: _Label('clear', height: 110),
        ),
        LiquidGlass(
          tintColor: Color(0xFF2962FF),
          tintOpacity: 0.4,
          shape: LiquidGlassShape.roundedRect(24),
          child: _Label('tinted', height: 110),
        ),
      ],
    );
  }
}

class _AppBarDemo extends StatelessWidget {
  const _AppBarDemo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: SizedBox(
          height: 56,
          child: LiquidGlassAppBar(
            leading: LiquidGlassButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            title: const Text('Inbox'),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatefulWidget {
  const _Segmented();

  @override
  State<_Segmented> createState() => _SegmentedState();
}

class _SegmentedState extends State<_Segmented> {
  String _value = 'w';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LiquidGlassSegmentedControl<String>(
        value: _value,
        onValueChanged: (v) => setState(() => _value = v),
        children: const {
          'd': Text('Day'),
          'w': Text('Week'),
          'm': Text('Month'),
          'y': Text('Year'),
        },
      ),
    );
  }
}

class _Controls extends StatefulWidget {
  const _Controls();

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  bool _on = true;
  bool _off = false;
  double _value = 0.6;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LiquidGlassSwitch(
              value: _on,
              onChanged: (v) => setState(() => _on = v),
            ),
            const SizedBox(width: 32),
            LiquidGlassSwitch(
              value: _off,
              onChanged: (v) => setState(() => _off = v),
            ),
          ],
        ),
        const SizedBox(height: 36),
        LiquidGlassSlider(
          value: _value,
          onChanged: (v) => setState(() => _value = v),
        ),
      ],
    );
  }
}

class _Search extends StatelessWidget {
  const _Search();

  @override
  Widget build(BuildContext context) {
    return const Center(child: LiquidGlassSearchBar(hintText: 'Search photos'));
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: 170,
        child: LiquidGlassSheet(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Share', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final icon in [
                      Icons.message_rounded,
                      Icons.mail_rounded,
                      Icons.link_rounded,
                      Icons.download_rounded,
                    ])
                      LiquidGlassButton.icon(
                        onPressed: () {},
                        icon: Icon(icon),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LiquidGlassGroup(
        spacing: 24,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LiquidGlassButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_rounded),
            ),
            const SizedBox(width: 8),
            LiquidGlassButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.crop_rounded),
            ),
            const SizedBox(width: 8),
            LiquidGlassButton(onPressed: () {}, child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}
