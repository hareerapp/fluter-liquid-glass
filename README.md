# liquid_design

iOS 26 **Liquid Glass** for any Flutter widget, plus ready-made iOS 26
components.

[![pub package](https://img.shields.io/pub/v/liquid_design.svg?style=flat-square)](https://pub.dev/packages/liquid_design)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Instagram](https://img.shields.io/badge/@m9__6m-E4405F?style=flat-square&logo=instagram&logoColor=white)](https://instagram.com/m9_6m)

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/nav_labels.png" width="600" alt="Liquid Glass navigation bar"></p>
<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/shapes.png" width="600" alt="Liquid Glass shapes"></p>

| Platform | What you get |
|---|---|
| iOS 26+ | Real native glass (`UIGlassEffect`, `UIGlassContainerEffect`) |
| macOS 26+ | Real native glass (`NSGlassEffectView`, `NSGlassEffectContainerView`) |
| iOS 15–25 / macOS 10.15–15 | Treated like Android: your widget as-is, or the optional frosted blur (no native views) |
| Android, web, Windows, Linux | Installs and runs without errors; your widget as-is, or an optional frosted blur |

> **New in 0.3.0:** a picture and a short example for every component
> below. **0.2.x:** [`LiquidGlassSvg`](#liquidglasssvg--glass-in-the-shape-of-any-svg),
> glass in the exact shape of any SVG, and older iOS / macOS behave like Android.

## Install

```yaml
dependencies:
  liquid_design: ^0.3.0
```

```dart
import 'package:liquid_design/liquid_design.dart';
```

## LiquidGlass — wrap anything

```dart
LiquidGlass(
  child: GestureDetector(
    onTap: () {},
    child: Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(shape: BoxShape.circle), // shape detected
      child: const Icon(Icons.add),
    ),
  ),
)
```

- The child defines the size and should have a transparent background.
- Glass has **no shadow**: iOS 26 glass draws a soft shadow around itself,
  and the package clips every glass surface (single, grouped, lens) to its
  own shape so nothing is drawn outside it.
- Taps are handled by your child (`GestureDetector`, `InkWell`, any button).
  `LiquidGlass` only observes touches to animate: grow on press, stretch
  toward a drag, glow under the finger, spring back on release.
- Shape is detected from `Container` / `DecoratedBox` / `ClipOval` /
  `ClipRRect` (also through `GestureDetector` / `InkWell`), or set
  `shape: LiquidGlassShape.roundedRect(20)`. Default: capsule.
- Inside a list, the press lets go as soon as the list starts scrolling.

Shorthand: call `.liquidGlass()` on any widget. It takes the same
parameters as `LiquidGlass`:

```dart
const Icon(Icons.add).liquidGlass(shape: const LiquidGlassShape.circle())
Text('Clear').liquidGlass(style: LiquidGlassStyle.clear, tintColor: Colors.blue)
```

### Shapes

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/shapes.png" width="600" alt="Capsule, circle, rounded, rect, star and SVG logo glass shapes"></p>

```dart
LiquidGlass(shape: const LiquidGlassShape.capsule(), child: label)       // default
LiquidGlass(shape: const LiquidGlassShape.circle(), child: icon)
LiquidGlass(shape: const LiquidGlassShape.roundedRect(16), child: card)
LiquidGlass(shape: const LiquidGlassShape.rect(), child: banner)
LiquidGlass(shape: LiquidGlassShape.svg(starSvg), child: box)            // any SVG
LiquidGlassSvg.asset('assets/logo.svg', height: 80)                      // SVG widget
```

### Styles

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/styles.png" width="600" alt="Regular, clear and tinted glass"></p>

```dart
LiquidGlass(child: card)                                                 // regular
LiquidGlass(style: LiquidGlassStyle.clear, child: card)                 // clear
LiquidGlass(tintColor: Colors.blue, tintOpacity: 0.4, child: card)      // tinted
```

## LiquidGlassSettings — every setting in one object

`LiquidGlassSettings` holds every glass setting. These are all of them,
with their defaults:

```dart
const settings = LiquidGlassSettings(
  enabled: true,                               // false = plain child, no glass
  style: LiquidGlassStyle.regular,             // regular / clear
  opacity: 1.0,                                // 0..1, how visible the glass is
  tintColor: null,                             // e.g. Colors.blue for coloured glass
  tintOpacity: 0.3,                            // 0..1, strength of the tint
  interactive: true,                           // press / drag / hover motion
  interactionStrength: 1.0,                    // 0 = none, 1 = iOS, >1 stronger
  brightness: LiquidGlassBrightness.auto,      // auto / system / light / dark
  shape: LiquidGlassShape.capsule(),           // default shape when not detected
  fallback: LiquidGlassFallback.none,          // none / frosted (Android, web, …)
  fallbackBlurSigma: 18,                       // blur of Flutter-drawn glass
  collapseOnScroll: true,                      // tab bar shrinks while scrolling
  renderer: LiquidGlassRenderer.native,        // native / flutter / auto
);
```

Apply it in one of three places:

```dart
// 1. The whole app
LiquidGlassService.instance.settings = settings;
// or change one value
LiquidGlassService.instance.update((s) => s.copyWith(opacity: 0.8));

// 2. One subtree (a screen, a sheet, ...)
LiquidGlassTheme(settings: settings, child: const MyScreen());

// 3. One widget
LiquidGlass(settings: settings, child: const MyButton());
// or single values straight on the widget
LiquidGlass(opacity: 0.6, tintColor: Colors.blue, child: const MyButton());
```

Components (`LiquidGlassButton`, `LiquidGlassNavigationBar`,
`LiquidGlassSwitch`, …) take a `settings:` too. Resolution order: the
widget's own values → its `settings:` → the nearest `LiquidGlassTheme` →
`LiquidGlassService`. Every change applies right away, with no reload.

| Setting | Type | Default | What it does |
|---|---|---|---|
| `enabled` | `bool` | `true` | Turns the glass on / off; off shows the child only |
| `style` | `LiquidGlassStyle` | `regular` | `regular` frosted glass or more transparent `clear` glass |
| `opacity` | `double` | `1.0` | How visible the glass material is (0–1) |
| `tintColor` | `Color?` | `null` | Coloured glass, like iOS tinted buttons |
| `tintOpacity` | `double` | `0.3` | Strength of the tint (0–1) |
| `interactive` | `bool` | `true` | Grow on press, stretch on drag, glow on hover |
| `interactionStrength` | `double` | `1.0` | Motion amount: 0 = none, 1 = iOS, >1 stronger |
| `brightness` | `LiquidGlassBrightness` | `auto` | `auto` follows your app theme; or `system`, `light`, `dark` |
| `shape` | `LiquidGlassShape` | `capsule()` | Shape used when it can't be detected from the child |
| `fallback` | `LiquidGlassFallback` | `none` | `frosted` shows a Flutter glass on Android, web and desktop |
| `fallbackBlurSigma` | `double` | `18` | Blur of Flutter-drawn glass (0 = no blur) |
| `collapseOnScroll` | `bool` | `true` | Navigation bar shrinks while scrolling down |
| `renderer` | `LiquidGlassRenderer` | `native` | `native` system glass, or `flutter` / `auto` Flutter-drawn glass |

## LiquidGlassSvg — glass in the shape of any SVG

Turn a logo, an icon or any SVG into a Liquid Glass surface whose outline
follows the artwork exactly: not a circle, not a capsule, the real shape.

<p align="center">
  <img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/screenshots/svg_logo_light.png" width="49%" alt="SVG logo as Liquid Glass, light mode">
  <img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/screenshots/svg_logo_dark.png" width="49%" alt="SVG logo as Liquid Glass, dark mode">
</p>

| Platform | What `LiquidGlassSvg` shows |
|---|---|
| iOS 26+ / macOS 26+ | Native Liquid Glass cut to the SVG outline (SwiftUI `glassEffect(in:)`) |
| iOS 15–25 / macOS 10.15–15 | Same as Android: the normal SVG |
| Android, web, Windows, Linux | **The normal SVG**, drawn with its own colours (or Flutter glass with `fallback: frosted`) |

Native glass is used only where the system has Liquid Glass (iOS / macOS 26+).
Everywhere else the package steps aside, exactly as on Android.

The rectangular platform view is never visible: the glass and its shadow are
masked to the outline, including during light / dark switches.

### From an asset

```yaml
flutter:
  assets:
    - assets/logo.svg
```

```dart
LiquidGlassSvg.asset(
  'assets/logo.svg',
  height: 40,                        // width follows the SVG aspect ratio
  tintColor: const Color(0xFF3E205A),
  tintOpacity: 0.35,
  semanticLabel: 'Hareer',
)
```

The file is loaded once and cached, so rebuilds never flash.

### From a string

A full SVG document:

```dart
const star = '''
<svg viewBox="0 0 24 24">
  <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02
                   12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26"/>
</svg>''';

LiquidGlassSvg(svg: star, width: 96, tintColor: Colors.amber)
```

Or only the path data (`d`):

```dart
LiquidGlassSvg(
  svg: 'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3'
      'c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 '
      '22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z',
  width: 96,
)
```

### Tap, press and content inside the shape

```dart
LiquidGlassSvg.asset(
  'assets/logo.svg',
  height: 110,
  interactive: true,                 // grows and stretches under the finger
  onTap: () => openHome(),           // only taps inside the outline count
  color: Colors.white,               // plain-SVG colour on Android / web
  child: const Center(child: Text('Hi')), // clipped to the outline
)
```

### Stroke-only artwork

Line icons with `fill="none"` and a `stroke` are turned into a filled
outline, so the glass has the width of the stroke:

```dart
LiquidGlassSvg(svg: waveIcon, width: 130)                     // strokeToFill: true
LiquidGlassSvg(svg: waveIcon, width: 130, strokeToFill: false) // raw path as fill
```

### As a shape for LiquidGlass

`LiquidGlassShape.svg` and `LiquidGlassShape.path` work anywhere a shape is
accepted:

```dart
LiquidGlass(
  shape: LiquidGlassShape.svg(starSvg),
  child: const SizedBox(width: 100, height: 100),
)

const SizedBox(width: 110, height: 90).liquidGlass(
  shape: LiquidGlassShape.path(
    Path()
      ..moveTo(0, 50)
      ..quadraticBezierTo(50, -20, 100, 50)
      ..quadraticBezierTo(50, 120, 0, 50)
      ..close(),
  ),
)
```

### Parameters

| Parameter | Type | Default | What it does |
|---|---|---|---|
| `svg` / `assetName` | `String` | required | SVG document, path data, or an asset path (`.asset`) |
| `width`, `height` | `double?` | SVG size | Give one and the other follows the aspect ratio |
| `fit` | `BoxFit` | `contain` | How the artwork fits the box |
| `alignment` | `Alignment` | `center` | Where the artwork sits in the box |
| `tintColor` | `Color?` | settings | Coloured glass, e.g. your brand colour |
| `tintOpacity` | `double?` | settings | Strength of the tint (0–1) |
| `color` | `Color?` | `null` | Paints the plain SVG in one colour (non-glass platforms) |
| `rimColor`, `rimWidth` | `Color?`, `double` | white, `1.0` | Edge highlight of Flutter-drawn glass |
| `strokeToFill` | `bool` | `true` | Outline stroke-only artwork |
| `settings` | `LiquidGlassSettings?` | theme / service | Per-widget glass settings |
| `interactive` | `bool` | `false` | Press / drag motion |
| `onTap` | `VoidCallback?` | `null` | Tap inside the outline |
| `semanticLabel` | `String?` | `null` | Screen-reader label |
| `child` | `Widget?` | `null` | Content drawn inside the shape (clipped) |
| `bundle` | `AssetBundle?` | `DefaultAssetBundle` | Bundle for `.asset` |

### Supported SVG

`path` (every command, arcs included), `rect` (rounded), `circle`,
`ellipse`, `line`, `polyline`, `polygon`, nested `g` / `svg`, `transform`,
`viewBox`, presentation attributes, `style=""`, `<style>` CSS classes,
`fill-rule`, opacity, and linear / radial gradients. Several shapes are
merged into one outline. No extra dependency: the parser is built in.

## Components

Ready-made iOS 26 controls. Each one works with the same settings as
`LiquidGlass` (`settings:`, `LiquidGlassTheme`, `LiquidGlassService`).

| Component | Widget |
|---|---|
| [Buttons](#buttons) | `LiquidGlassButton`, `LiquidGlassButton.icon` |
| [Segmented control](#segmented-control) | `LiquidGlassSegmentedControl` |
| [Switch and slider](#switch-and-slider) | `LiquidGlassSwitch`, `LiquidGlassSlider` |
| [Search bar](#search-bar) | `LiquidGlassSearchBar` |
| [Bottom sheet](#bottom-sheet) | `showLiquidGlassBottomSheet`, `LiquidGlassSheet` |
| [Navigation bar](#navigation-bar) | `LiquidGlassNavigationBar` |
| [App bar](#app-bar) | `LiquidGlassAppBar` |

### Buttons

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/buttons.png" width="600" alt="Glass, tinted and prominent buttons"></p>

Three styles, as text or icon buttons:

```dart
LiquidGlassButton(onPressed: save, child: const Text('Glass'))

LiquidGlassButton(
  style: LiquidGlassButtonStyle.tinted,
  onPressed: save,
  child: const Text('Tinted'),
)

LiquidGlassButton(
  style: LiquidGlassButtonStyle.prominent,
  onPressed: buy,
  child: const Text('Prominent'),
)

LiquidGlassButton.icon(onPressed: share, icon: const Icon(Icons.ios_share_rounded))
```

`color` and `foregroundColor` change the colours, `shape` the outline
(capsule by default), and `onLongPress` adds a long press.

### Segmented control

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/segmented.png" width="600" alt="Segmented control with a glass selection"></p>

```dart
LiquidGlassSegmentedControl<String>(
  value: period,
  onValueChanged: (v) => setState(() => period = v),
  children: const {
    'd': Text('Day'),
    'w': Text('Week'),
    'm': Text('Month'),
    'y': Text('Year'),
  },
)
```

### Switch and slider

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/controls.png" width="600" alt="Glass switches and slider"></p>

```dart
LiquidGlassSwitch(value: on, onChanged: (v) => setState(() => on = v))

LiquidGlassSlider(
  value: volume,
  onChanged: (v) => setState(() => volume = v),
  divisions: 10, // optional
)
```

Switch, slider and segmented thumbs lift into a glass lens while touched.
They work inside scrolling lists: a vertical swipe that starts on a switch,
slider or segmented control scrolls the list and never changes the value.
A sideways swipe or a tap changes it. Dragging past either end pulls the
lens a little beyond the edge, with a rubber-band feel, and it springs back
on release. A fast slider drag stretches the lens in the direction of travel.

### Search bar

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/search.png" width="600" alt="Glass search bar"></p>

```dart
LiquidGlassSearchBar(
  hintText: 'Search photos',
  onChanged: filter,
  onSubmitted: search,
)
```

### Bottom sheet

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/sheet.png" width="600" alt="Glass bottom sheet"></p>

```dart
showLiquidGlassBottomSheet(
  context: context,
  builder: (context) => const ShareMenu(),
);
```

Or place a `LiquidGlassSheet(child: ...)` yourself.

### Navigation bar

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/nav_labels.png" width="600" alt="Glass navigation bar with icons and labels"></p>

```dart
LiquidGlassNavigationBar(
  currentIndex: tab,
  onTap: (i) => setState(() => tab = i),
  onReselect: (i) => scrollToTop(i),          // current tab tapped again
  items: const [
    LiquidGlassNavItem(icon: Icon(Icons.home_rounded), label: 'Home'),
    LiquidGlassNavItem(icon: Icon(Icons.search_rounded), label: 'Search'),
    LiquidGlassNavItem(icon: Icon(Icons.favorite_rounded), label: 'Saved'),
    LiquidGlassNavItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
  ],
)
```

The selection pill slides with a liquid stretch. Pressing lifts it into a
glass lens that follows the finger (with haptic ticks) and snaps on release.

#### Icons only

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/nav_icons.png" width="600" alt="Navigation bar with icons only"></p>

Leave out `label` and the bar gets shorter (56 instead of 64):

```dart
items: const [
  LiquidGlassNavItem(icon: Icon(Icons.home_rounded)),
  LiquidGlassNavItem(icon: Icon(Icons.search_rounded)),
  LiquidGlassNavItem(icon: Icon(Icons.favorite_rounded)),
  LiquidGlassNavItem(icon: Icon(Icons.person_rounded)),
],
```

`activeIcon` shows a different icon for the selected tab.

#### With an action button

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/nav_action.png" width="600" alt="Navigation bar next to a round glass action button"></p>

```dart
Row(
  children: [
    Expanded(child: LiquidGlassNavigationBar(/* ... */)),
    const SizedBox(width: 12),
    LiquidGlassButton.icon(onPressed: compose, icon: const Icon(Icons.add_rounded)),
  ],
)
```

#### Collapsed while scrolling

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/nav_collapsed.png" width="600" alt="Collapsed navigation bar showing only the current tab"></p>

Like iOS 26, the bar can shrink to the current tab while the user scrolls
down, and open again when tapped:

```dart
LiquidGlassScrollCollapse(
  onChanged: (c) => setState(() => collapsed = c),
  child: ListView(/* ... */),
)

LiquidGlassNavigationBar(
  collapsed: collapsed,
  onExpand: () => setState(() => collapsed = false),
  /* ... */
)
```

Users can turn this off with
`LiquidGlassService.instance.setCollapseOnScroll(false)`: the bar then stays
open, and opens right away if it was collapsed.

#### Tinted and custom colours

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/nav_tinted.png" width="600" alt="Purple tinted navigation bar with white icons"></p>

```dart
LiquidGlassNavigationBar(
  activeColor: Colors.white,
  inactiveColor: Colors.white70,
  settings: LiquidGlassService.instance.settings.copyWith(
    tintColor: const Color(0xFF6A1B9A),
    tintOpacity: 0.55,
  ),
  /* ... */
)
```

#### Dark mode

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/nav_dark.png" width="600" alt="Navigation bar in dark mode"></p>

Nothing to do: with `brightness: LiquidGlassBrightness.auto` (the default)
the glass follows your app theme.

### App bar

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/app_bar.png" width="600" alt="Glass app bar with back button, title and actions"></p>

```dart
Scaffold(
  extendBodyBehindAppBar: true,
  appBar: LiquidGlassAppBar(
    title: const Text('Inbox'),
    actions: [
      IconButton(onPressed: search, icon: const Icon(Icons.search)),
      IconButton(onPressed: more, icon: const Icon(Icons.more_horiz_rounded)),
    ],
  ),
  body: ListView(/* ... */),
)
```

Floating glass buttons (automatic back button; several actions share one
capsule) and a scroll-edge fade once content scrolls underneath.

## Groups: morphing and performance

<p align="center"><img src="https://raw.githubusercontent.com/hareerapp/fluter-liquid-glass/main/doc/readme/group.png" width="600" alt="Three glass buttons melting together in a group"></p>

```dart
LiquidGlassGroup(
  spacing: 24,
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    LiquidGlassButton.icon(onPressed: edit, icon: const Icon(Icons.edit_rounded)),
    const SizedBox(width: 8),
    LiquidGlassButton.icon(onPressed: crop, icon: const Icon(Icons.crop_rounded)),
    const SizedBox(width: 8),
    LiquidGlassButton(onPressed: done, child: const Text('Done')),
  ]),
)
```

Everything inside a `LiquidGlassGroup` is drawn by **one** native glass
container:

- **Morphing**: shapes closer than `spacing` melt together and split apart
  like liquid as they move.
- **Performance**: one native view instead of one per widget. In the example
  benchmark (40 glass chips scrolling, iOS 26.3 simulator): grouped
  **62 fps, 2.1 ms raster** vs individual **46 fps, 5.1 ms raster**.
  These are simulator numbers; measure on a device for your app.

Group glass is drawn beneath all Flutter content in the group:

- The background the glass shows must be **outside** the group (a group
  wrapping a list of cards with their own backgrounds hides the glass
  behind the cards).
- Hide the content of shapes that tuck behind others (see the example's
  morph demo).
- `LiquidGlass(joinGroup: false)` keeps a glass out of an enclosing group.
- Glass can grow `overflow` points (default 24) past the group's bounds,
  e.g. a button pressed at the edge.

Use `LiquidGlassGroup(spacing: 0, ...)` to share one native view between
neighbouring glass without merging them. `LiquidGlassAppBar` does this for
its buttons by default (`groupGlass`).

## Settings

```dart
final glass = LiquidGlassService.instance;
glass.setOpacity(0.8);                    // 0..1
glass.setInteractionStrength(1.4);        // 0 = no motion, 1 = iOS, >1 stronger
glass.setStyle(LiquidGlassStyle.clear);   // regular / clear
glass.setTint(Colors.blue, opacity: 0.3); // null removes the tint
glass.setBrightness(LiquidGlassBrightness.auto); // auto / system / light / dark
glass.setFallback(LiquidGlassFallback.frosted);  // non-Apple platforms
glass.setCollapseOnScroll(false);         // keep navigation bars open
glass.setRenderer(LiquidGlassRenderer.native);   // native / flutter / auto
glass.setEnabled(false);
```

### Renderer: native or Flutter-drawn glass

`LiquidGlassRenderer.native` (default) uses the real iOS 26 / macOS 26 glass
everywhere. It is also the fastest option on iPhone.

`LiquidGlassRenderer.flutter` draws glass with Flutter: a blur with a colour
boost, a light sheen and a specular rim. Use it only where a native view
can't go, for example inside a `ShaderMask` or `ColorFiltered`. Flutter blurs
can't be cached, so every frame of any animation on screen re-blurs every
Flutter glass. `LiquidGlassRenderer.auto` uses native glass except inside
scroll views.

Measured on an iPhone at 120 Hz in profile mode (missed frames while
scrolling the example's Controls page / toggling a switch):

| renderer | scroll | switch |
|---|---|---|
| native | 57 | 0 |
| auto | 189 | 147 |
| flutter | 281 | 181 |

```dart
LiquidGlass(renderer: LiquidGlassRenderer.flutter, child: ...) // per widget
LiquidGlassService.instance.setRenderer(LiquidGlassRenderer.native);
```

`fallbackBlurSigma` sets the blur of Flutter-drawn glass (0 = no blur, the
cheapest).

Settings resolve in this order: a widget's own parameters → its `settings:`
→ the nearest `LiquidGlassTheme` → `LiquidGlassService`.

```dart
LiquidGlassTheme(
  settings: LiquidGlassService.instance.settings.copyWith(style: LiquidGlassStyle.clear),
  child: const PhotoViewer(),
)
```

**Light / dark**: with `LiquidGlassBrightness.auto` (default) glass follows
your app theme and switches instantly. For an instant app-wide switch, also
set `themeAnimationDuration: Duration.zero` on `MaterialApp`.

**Capabilities**: `LiquidGlassService.instance.isLiquidGlassSupported` is
true on iOS / macOS 26+. It is filled in once the first glass widget builds,
or `await LiquidGlassService.instance.ensureInitialized()`.

## Accessibility & RTL

- **Right-to-left**: navigation bar, segmented control, switch and slider
  mirror correctly; dragging selects what is under the finger.
- **Reduce Motion**: no stretching or bouncing, only calm transitions.
- **Increase Contrast**: the frosted fallback becomes more opaque. Native
  glass follows Reduce Transparency / Increase Contrast by itself.
- **Screen readers**: tabs and segments are selectable buttons, switches
  report their state, sliders support increase / decrease, buttons accept a
  `semanticLabel`. The glass itself is hidden from the accessibility tree.
- Buttons keep Apple's 44 pt minimum touch target.

## Performance tips

- **Keep tab pages alive** (e.g. an `IndexedStack` whose pages are built on
  first visit and cached). Rebuilding a page on every tab switch recreates
  all its native glass views right as the tab bar animates. The example app
  does this: a tab switch costs ~4 ms instead of ~100 ms (debug build).
- **Every separate glass view on screen adds work to every frame** on iOS.
  Flutter draws the content above each native view (a button's label, for
  example) into its own full-screen layer. It redraws those layers on every
  frame of any animation, and creates or drops them as views scroll in and
  out. **Group glass that sits on the same background** in a
  `LiquidGlassGroup(spacing: 0, ...)`: one native view and one layer for the
  whole group. Bars, toolbars, rows of buttons and chip grids all fit.
  Glass in a group refracts what is painted *before* the group (the panel
  or page behind it), so put the group inside that background. The example
  groups its tab bar and the button panels on the Components page.
  (Measured: the Groups page scrolls with ~1 missed frame; pages with 10+
  separate glass views miss 50–150.)
- Switch, slider, segmented control and navigation bar lenses are created on
  first touch and leave the scene when the touch ends, so idle controls cost
  no native view.
- The lens follows the finger closely: native tracking catches up in 50 ms
  and the Flutter spring lags only about 30 ms.
- On iOS / macOS those lenses are animated by **Core Animation**: Flutter
  only sends a target on each touch event and the system animates at the
  display's refresh rate (up to 120 Hz), smooth even if Flutter drops a
  frame. Dragging across the tab bar went from ~30 to ~60 visible fps in
  the simulator.
- Glass animations never jump after a slow frame: each frame advances them
  by at most 1/30 s.
- Judge smoothness in profile mode on a device (`flutter run --profile`);
  debug builds, especially on the simulator, are many times slower.
  `example/integration_test/perf_test.dart` measures frame times:

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/perf_test.dart
```

## Notes

- On iOS 15–25 / macOS before 26 there is no Liquid Glass, so the package
  behaves like Android: no native views, your widgets as-is (or Flutter glass
  with `fallback: LiquidGlassFallback.frosted`).
- `example/integration_test/feature_test.dart` walks through every feature
  on a device or simulator.

- Without a group, each `LiquidGlass` on iOS / macOS is a native platform
  view: fine for bars, buttons and floating controls. Use `LiquidGlassGroup`
  for many glass shapes (lists, grids, toolbars).
- Glass inside a group ignores `Opacity` ancestors (the group draws it);
  use the `opacity` setting instead.

---

## 👨‍💻 Author

**Mohammed Al-Jaf**: made with 💙 for the Flutter community.

[![Instagram](https://img.shields.io/badge/Instagram-@m9__6m-E4405F?style=for-the-badge&logo=instagram&logoColor=white)](https://instagram.com/m9_6m)

Questions, ideas or feedback? Message me on Instagram or
[open an issue](https://github.com/hareerapp/fluter-liquid-glass/issues).
If this package helps you, a 👍 on pub.dev and a ⭐ on GitHub are much appreciated.
