import 'package:flutter/material.dart';
import 'package:liquid_design/liquid_design.dart';

import '../common.dart';

/// Every way to give glass a shape.
class ShapesPage extends StatelessWidget {
  const ShapesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoSection(
          title: 'Explicit shape',
          description: 'Pass shape: to LiquidGlass.',
          child: GlassGrid(
            children: [
              GlassTile(
                label: 'LiquidGlassShape.capsule()',
                index: 0,
                child: LiquidGlass(
                  shape: LiquidGlassShape.capsule(),
                  child: GlassLabel('Capsule'),
                ),
              ),
              GlassTile(
                label: 'LiquidGlassShape.circle()',
                index: 1,
                child: LiquidGlass(
                  shape: LiquidGlassShape.circle(),
                  child: GlassLabel('Circle', width: 80, height: 80),
                ),
              ),
              GlassTile(
                label: 'LiquidGlassShape.roundedRect(12)',
                index: 2,
                child: LiquidGlass(
                  shape: LiquidGlassShape.roundedRect(12),
                  child: GlassLabel('Radius 12', height: 80),
                ),
              ),
              GlassTile(
                label: 'LiquidGlassShape.roundedRect(28)',
                index: 3,
                child: LiquidGlass(
                  shape: LiquidGlassShape.roundedRect(28),
                  child: GlassLabel('Radius 28', height: 90),
                ),
              ),
              GlassTile(
                label: 'LiquidGlassShape.rect()',
                index: 4,
                child: LiquidGlass(
                  shape: LiquidGlassShape.rect(),
                  child: GlassLabel('Rect', height: 80),
                ),
              ),
              GlassTile(
                label: 'capsule(), tall child',
                index: 5,
                child: LiquidGlass(
                  shape: LiquidGlassShape.capsule(),
                  child: GlassLabel('Tall', width: 60, height: 120),
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Detected from the child',
          description:
              'No shape: given — it is read from the child decoration or '
              'clip, even through GestureDetector / InkWell.',
          child: GlassGrid(
            children: [
              GlassTile(
                label: 'Container(BoxDecoration(shape: circle))',
                index: 6,
                child: LiquidGlass(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                  ),
                ),
              ),
              GlassTile(
                label: 'Container(BoxDecoration(borderRadius: 20))',
                index: 7,
                child: LiquidGlass(
                  child: Container(
                    width: 120,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
              ),
              GlassTile(
                label: 'DecoratedBox(ShapeDecoration(StadiumBorder))',
                index: 0,
                child: LiquidGlass(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(shape: StadiumBorder()),
                    child: GlassLabel('Stadium'),
                  ),
                ),
              ),
              GlassTile(
                label: 'ShapeDecoration(RoundedRectangleBorder(16))',
                index: 1,
                child: LiquidGlass(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    child: GlassLabel('Rounded 16', height: 80),
                  ),
                ),
              ),
              GlassTile(
                label: 'ClipOval',
                index: 2,
                child: LiquidGlass(
                  child: ClipOval(
                    child: GlassLabel('Oval', width: 80, height: 80),
                  ),
                ),
              ),
              GlassTile(
                label: 'ClipRRect(borderRadius: 24)',
                index: 3,
                child: LiquidGlass(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    child: GlassLabel('ClipRRect', height: 90),
                  ),
                ),
              ),
              GlassTile(
                label: 'GestureDetector > Container(circle)',
                index: 4,
                child: LiquidGlass(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
              GlassTile(
                label: 'plain child → settings.shape (see Settings)',
                index: 5,
                child: LiquidGlass(child: GlassLabel('Default', height: 70)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
