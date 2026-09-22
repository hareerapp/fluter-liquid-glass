import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';

import 'common.dart';
import 'pages/components_page.dart';
import 'pages/controls_page.dart';
import 'pages/gallery_page.dart';
import 'pages/groups_page.dart';
import 'pages/settings_page.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeMode, rtlLayout, reduceMotion]),
      builder: (context, _) => MaterialApp(
        title: 'Liquid Glass',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode.value,
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
        ),
        // Demo switches for right-to-left layout and Reduce Motion.
        builder: (context, child) => Directionality(
          textDirection: rtlLayout.value
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion.value),
            child: child!,
          ),
        ),
        home: const DemoShell(),
      ),
    );
  }
}

/// Glass app bar + glass tab bar + floating glass button over the pages.
class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  static const _tabs = [
    (Icons.touch_app_rounded, 'Controls'),
    (Icons.widgets_rounded, 'Components'),
    (Icons.bubble_chart_rounded, 'Groups'),
    (Icons.category_rounded, 'Gallery'),
    (Icons.settings_rounded, 'Settings'),
  ];

  int _tab = 0;
  bool _collapsed = false;

  /// Tabs are built on first visit and then kept alive (like iOS), so
  /// switching tabs never rebuilds a page and its native glass views.
  final _visited = <int>{0};

  /// Same widget instances on every rebuild, so switching tabs does not
  /// rebuild the pages themselves.
  final _pageCache = <int, Widget>{};

  /// One scroll controller per tab, so tapping the current tab again can
  /// scroll that page back to the top (like iOS).
  late final _scrollControllers = [
    for (var i = 0; i < _tabs.length; i++) ScrollController(),
  ];
  String? _message;
  Timer? _messageTimer;

  @override
  void dispose() {
    _messageTimer?.cancel();
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _scrollToTop(int tab) {
    final controller = _scrollControllers[tab];
    if (!controller.hasClients) return;
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _report(String message) {
    _messageTimer?.cancel();
    setState(() => _message = message);
    _messageTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _message = null);
    });
  }

  Widget _page(int tab) => switch (tab) {
    0 => ControlsPage(report: _report),
    1 => ComponentsPage(report: _report),
    2 => GroupsPage(report: _report),
    3 => const GalleryPage(),
    _ => const SettingsPage(),
  };

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = Theme.of(context).colorScheme.onSurface;
    final service = LiquidGlassService.instance;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ListenableBuilder(
          listenable: service,
          builder: (context, _) => LiquidGlassAppBar(
            // Stays glass when the effect is switched off globally, so it
            // can be switched back on.
            settings: service.settings.copyWith(enabled: true),
            leading: LiquidGlassButton.icon(
              settings: service.settings.copyWith(enabled: true),
              semanticLabel: 'Toggle dark mode',
              onPressed: () =>
                  themeMode.value = dark ? ThemeMode.light : ThemeMode.dark,
              icon: Icon(
                dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
            ),
            titleInGlass: true,
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _message ?? _tabs[_tab].$2,
                key: ValueKey(_message ?? _tab),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Enable / disable glass',
                onPressed: () => service.setEnabled(!service.settings.enabled),
                icon: Icon(
                  service.settings.enabled
                      ? Icons.blur_on_rounded
                      : Icons.blur_off_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Scrolling down collapses the tab bar, scrolling up expands it.
          LiquidGlassScrollCollapse(
            collapsed: _collapsed,
            onChanged: (c) => setState(() => _collapsed = c),
            child: IndexedStack(
              index: _tab,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  _visited.contains(i)
                      // Pages use this controller through DemoPage.
                      ? PrimaryScrollController(
                          controller: _scrollControllers[i],
                          child: _pageCache.putIfAbsent(i, () => _page(i)),
                        )
                      : const SizedBox.shrink(),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: padding.bottom + 12,
            // One native view for the tab bar and the button next to it
            // (spacing 0: they do not merge).
            child: LiquidGlassGroup(
              spacing: 0,
              child: Row(
                children: [
                  Expanded(
                    child: LiquidGlassNavigationBar(
                      currentIndex: _tab,
                      collapsed: _collapsed,
                      onExpand: () => setState(() => _collapsed = false),
                      // Tapping the tab that is already selected.
                      onReselect: _scrollToTop,
                      onTap: (i) => setState(() {
                        _tab = i;
                        _visited.add(i);
                        _collapsed = false;
                      }),
                      items: [
                        for (final (icon, label) in _tabs)
                          LiquidGlassNavItem(icon: Icon(icon), label: label),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  LiquidGlass(
                    child: GestureDetector(
                      onTap: () => _showQuickSheet(context),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Icon(Icons.bolt_rounded, color: fg),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick toggles in a glass bottom sheet.
  void _showQuickSheet(BuildContext context) {
    final service = LiquidGlassService.instance;
    showLiquidGlassBottomSheet<void>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: Listenable.merge([service, themeMode, rtlLayout]),
        builder: (context, _) {
          final s = service.settings;
          final dark = Theme.of(context).brightness == Brightness.dark;
          Widget row(String label, bool value, ValueChanged<bool> onChanged) =>
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 2,
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    LiquidGlassSwitch(
                      value: value,
                      semanticLabel: label,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              );
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quick settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                row(
                  'Dark mode',
                  dark,
                  (v) => themeMode.value = v ? ThemeMode.dark : ThemeMode.light,
                ),
                row(
                  'Clear style',
                  s.style == LiquidGlassStyle.clear,
                  (v) => service.setStyle(
                    v ? LiquidGlassStyle.clear : LiquidGlassStyle.regular,
                  ),
                ),
                row(
                  'Blue tint',
                  s.tintColor == Colors.blue,
                  (v) => service.setTint(v ? Colors.blue : null),
                ),
                row('Interactive', s.interactive, service.setInteractive),
                row(
                  'Collapse tab bar on scroll',
                  s.collapseOnScroll,
                  service.setCollapseOnScroll,
                ),
                row(
                  'Right-to-left',
                  rtlLayout.value,
                  (v) => rtlLayout.value = v,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
