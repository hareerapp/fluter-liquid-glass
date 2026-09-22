# liquid_design example

A demo app that shows every feature of
[liquid_design](https://pub.dev/packages/liquid_design): native iOS 26
Liquid Glass on any widget, with iOS 26 interactions and ready-made
components.

## What's inside

| Tab | Shows |
|---|---|
| **Controls** | Press, hold and drag glass; switches, sliders and segmented controls with the glass lens |
| **Components** | Glass buttons, the app bar, search bar, bottom sheet and navigation |
| **Groups** | `LiquidGlassGroup` morphing, plus a live grouped-vs-separate benchmark |
| **Gallery** | Shapes, per-widget overrides, `.liquidGlass()` and `LiquidGlassTheme` |
| **Settings** | Every `LiquidGlassService` setting, applied live |

The bottom tab bar is a `LiquidGlassNavigationBar`. It shrinks as you
scroll down, scrolls a page back to the top when you tap its tab again,
and supports light / dark and right-to-left.

## Run it

```bash
cd example
flutter run
```

Use an iOS 26 or macOS 26 device or simulator to see the native glass. On
Android and web the app runs with the optional frosted fallback.

To check smoothness, run in profile mode on a real device:

```bash
flutter run --profile
```
