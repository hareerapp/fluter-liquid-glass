import 'package:flutter/material.dart';

/// App theme mode, changed from the settings page and the quick sheet.
final themeMode = ValueNotifier(ThemeMode.light);

/// Demo-wide right-to-left layout switch.
final rtlLayout = ValueNotifier(false);

/// Simulates the system "Reduce Motion" setting.
final reduceMotion = ValueNotifier(false);

/// Shows short feedback (e.g. "IconButton tapped") in the glass app bar.
typedef ActionReporter = void Function(String message);

const _gradients = [
  [Color(0xFFFF5F6D), Color(0xFFFFC371)],
  [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)],
  [Color(0xFF11998E), Color(0xFF38EF7D)],
  [Color(0xFFFC466B), Color(0xFF3F5EFB)],
  [Color(0xFFF7971E), Color(0xFFFFD200)],
  [Color(0xFF00C6FF), Color(0xFF0072FF)],
  [Color(0xFFEE0979), Color(0xFFFF6A00)],
  [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
];

/// Colorful backgrounds so the glass has something to refract.
LinearGradient demoGradient(int index) => LinearGradient(
  colors: _gradients[index % _gradients.length],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Scrollable page body that leaves room for the glass bars.
class DemoPage extends StatelessWidget {
  const DemoPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return ListView(
      // Uses the tab's PrimaryScrollController (scroll to top on reselect).
      primary: true,
      // The glass app bar is included in padding.top.
      padding: EdgeInsets.fromLTRB(
        16,
        padding.top + 12,
        16,
        padding.bottom + 110,
      ),
      children: children,
    );
  }
}

class DemoSection extends StatelessWidget {
  const DemoSection({
    super.key,
    required this.title,
    this.description,
    required this.child,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// A gradient tile with a glass demo centered on it and a caption below.
class GlassTile extends StatelessWidget {
  const GlassTile({
    super.key,
    required this.label,
    required this.index,
    required this.child,
  });

  final String label;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: demoGradient(index),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(fontFamily: 'Menlo'),
        ),
      ],
    );
  }
}

/// Two-column grid of [GlassTile]s.
class GlassGrid extends StatelessWidget {
  const GlassGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 16,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      children: children,
    );
  }
}

/// A rounded gradient panel to show glass components over.
class GradientPanel extends StatelessWidget {
  const GradientPanel({
    super.key,
    required this.index,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final int index;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: demoGradient(index),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// A fixed-size label to put inside glass.
class GlassLabel extends StatelessWidget {
  const GlassLabel(
    this.text, {
    super.key,
    this.width = 116,
    this.height = 56,
    this.color,
  });

  final String text;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
