/// iOS 26 Liquid Glass for any Flutter widget.
///
/// Wrap a widget in [LiquidGlass] or call `.liquidGlass()` on it, or use the
/// ready-made components such as [LiquidGlassButton],
/// [LiquidGlassNavigationBar] and [LiquidGlassSvg]. Glass is native on iOS
/// and macOS 26; other platforms show the widget as-is or Flutter-drawn glass.
library;

export 'src/liquid_glass.dart' hide FlutterGlass;
export 'src/liquid_glass_app_bar.dart';
export 'src/liquid_glass_dart_plugin.dart';
export 'src/liquid_glass_button.dart';
export 'src/liquid_glass_controls.dart';
export 'src/liquid_glass_group.dart' show LiquidGlassGroup;
export 'src/liquid_glass_navigation_bar.dart';
export 'src/liquid_glass_segmented_control.dart';
export 'src/liquid_glass_service.dart';
export 'src/liquid_glass_settings.dart';
export 'src/liquid_glass_shape.dart';
export 'src/liquid_glass_sheet.dart';
export 'src/liquid_glass_svg.dart';
export 'src/liquid_glass_theme.dart';
