## 0.4.1 — API docs and all platforms on pub.dev

- API documentation for every public class, constructor and property
  (hover docs in the IDE and on the pub.dev API page).
- pub.dev now lists all six platforms: Android, iOS, macOS, web, Windows
  and Linux. Nothing changes at runtime: platforms without native glass
  still show the widget as-is, or Flutter glass with `fallback: frosted`.
- The OS version check no longer imports `dart:io` directly, so the package
  is web-compatible.

## 0.4.0 — Native press and drag for glass buttons

- Glass buttons now feel like iOS 26: pressing grows the glass, dragging
  pulls it along with a rubber-band feel (up to 60% of its size, at most
  36 pt) and stretches it toward the finger while it thins across.
- Drag more than 70 pt away and the glass springs back and the tap is
  cancelled; come back inside and it grabs the finger again (like
  `UIControl`).
- `LiquidGlassButton` taps survive small drags: releasing within 70 pt still
  taps (before, any move over 18 px cancelled the tap).
- Inside lists, a vertical drag still scrolls instead of tapping.
- The follow and stretch apply to every interactive `LiquidGlass`; set
  `interactive: false` or lower `interactionStrength` to calm it down.

## 0.3.0 — Picture guide for every component

- README: a screenshot and a short example for every component: buttons
  (glass, tinted, prominent, icon), segmented control, switch and slider,
  search bar, bottom sheet, app bar, groups, glass shapes and styles.
- Navigation bar gallery: icons and labels, icons only, with an action
  button, collapsed while scrolling, tinted colours and dark mode.
- Example: `lib/readme_shots.dart` renders every README scene, so the
  pictures can be regenerated (`flutter run -t lib/readme_shots.dart`).
- No API changes.

## 0.2.1 — Older iOS / macOS behave like Android

- On iOS / macOS older than 26 (no Liquid Glass) the package now behaves
  exactly like Android: no native views, your widgets as-is, the plain SVG for
  `LiquidGlassSvg`, and Flutter glass only with `fallback: frosted`.
  Previously a native blur was shown instead.
- Decided synchronously from the OS version (no flash on start), then
  confirmed by the plugin capabilities.
- New: `LiquidGlassService.isApplePlatform` and
  `LiquidGlassService.osMajorVersion`.

## 0.2.0 — Glass in the shape of any SVG

- **SVG and custom-path glass.** `LiquidGlassShape.svg(...)` and
  `LiquidGlassShape.path(...)` give glass any outline: a full SVG document or
  raw path data (`d`). Stroke-only artwork is outlined (`strokeToFill`).
- **`LiquidGlassSvg`** widget, from a string or with `LiquidGlassSvg.asset(...)`.
  Native Liquid Glass shaped like the SVG on iOS / macOS 26 (SwiftUI
  `glassEffect(in:)`, masked to the outline so the rectangular bounds never
  show). On other platforms it draws the plain SVG, or Flutter glass with
  `fallback: frosted`. Taps only land inside the outline.
- `LiquidGlass` / `.liquidGlass()` accept `rimColor` and `rimWidth` for the
  Flutter renderer.
- No new dependencies; the SVG parser is built in. Existing shapes send
  exactly the same data to native as before.

## 0.1.0 — First release ✨

**iOS 26 Liquid Glass for any Flutter widget.** Real native glass on
iOS / macOS 26. On every other platform it runs safely, showing your widget
as-is or with an optional frosted blur.

---

### 🚀 Getting started

**1. Install**

```yaml
dependencies:
  liquid_design: ^0.1.0
```

**2. Import**

```dart
import 'package:liquid_design/liquid_design.dart';
```

**3. Wrap any widget**

```dart
LiquidGlass(
  child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
)

// or the shorthand
const Icon(Icons.add).liquidGlass()
```

**4. Tune it (optional)**

```dart
LiquidGlassService.instance.setStyle(LiquidGlassStyle.clear);
```

---

### 🫧 Liquid glass

- **`LiquidGlass`**: native glass behind any child, with no size or layout
  changes.
- **Shape detection** from `Container`, `DecoratedBox`, `ClipOval` and
  `ClipRRect`, or set `shape:` yourself (capsule, circle, rounded rect).
- **No shadows**: every glass surface is clipped to its own shape.
- **`.liquidGlass()`** extension on any `Widget`.

### 👆 iOS 26 interactions

- **Press** grows the glass, **drag** stretches it toward your finger,
  **release** springs it back.
- **Hover** glow for mouse and trackpad pointers (macOS, iPad, web).
- **Taps stay with your child**: no `onTap` to wire up.
- **Scroll-safe**: a press lets go as soon as the list around it scrolls.

### 🧩 Components

| Widget | Highlights |
|---|---|
| `LiquidGlassNavigationBar` | Sliding pill, drag-to-select lens, haptics, `onReselect`, shrinks on scroll |
| `LiquidGlassAppBar` | One native view, back button, scroll-edge effect |
| `LiquidGlassButton` | `glass` · `tinted` · `prominent`, plus `.icon` |
| `LiquidGlassSegmentedControl` | Thumb lifts into a glass lens |
| `LiquidGlassSwitch` · `LiquidGlassSlider` | Lens thumb, rubber-band edges, velocity stretch |
| `LiquidGlassSearchBar` | Glass search field, works with your own controller and focus node |
| `LiquidGlassSheet` | Floating glass bottom sheet (`showLiquidGlassBottomSheet`) |

- **Swipe-friendly controls**: a vertical swipe scrolls the list and never
  changes a switch, slider or tab. A tap or a sideways drag does.
- **`LiquidGlassScrollCollapse`**: the tab bar shrinks while you scroll
  down and comes back when you scroll up. Users can turn it off.

### 🔗 Groups and morphing

- **`LiquidGlassGroup`**: many glass shapes in **one** native view.
- **Liquid morphing** between shapes closer than `spacing`.
- **`spacing: 0`** shares the view without merging. This is the biggest
  performance win for rows of buttons, toolbars and chips.

### 🎛 Settings and theming

- **`LiquidGlassSettings`**: every setting in one object. That's style,
  opacity, tint, interaction, brightness, shape, fallback, blur,
  collapse-on-scroll and renderer.
- **Global**: `LiquidGlassService.instance` with `setStyle`, `setOpacity`,
  `setTint`, `setBrightness`, `setInteractive`, `setInteractionStrength`,
  `setCollapseOnScroll`, `setRenderer`, `setFallback` and `setEnabled`.
- **Per subtree**: `LiquidGlassTheme`.
- **Per widget**: every setting is also a parameter on `LiquidGlass`.
- **Order**: widget → `settings:` → theme → service.
- **Live**: every change applies at runtime, no reload needed.
- **Light / dark**: follows your app theme and switches instantly.
- **Capabilities**: `isLiquidGlassSupported`, OS version, Reduce
  Transparency.

### ⚡ Performance

- **Lenses on Core Animation**: switch, slider, segmented and tab bar
  lenses run at the display's refresh rate (up to 120 Hz).
- **Tight tracking**: the lens follows the finger within about 50 ms.
- **Only while touched**: lenses exist while you touch them and leave the
  scene when you let go.
- **No jumps**: glass springs never jump after a slow frame.
- **Idle groups sleep**: hidden groups stop syncing.
- **Renderer choice**: `native` (default and fastest on iPhone), with
  `flutter` / `auto` for places a native view can't go.

### ♿ Accessibility and RTL

- Right-to-left layouts.
- Reduce Motion, Increase Contrast and Reduce Transparency.
- Screen reader labels, states and actions on every component.

### 📱 Platforms

| Platform | Result |
|---|---|
| iOS 26+ · macOS 26+ | Native Liquid Glass (`UIGlassEffect` · `NSGlassEffectView`) |
| iOS 15–25 · macOS 10.15–15 | Native system material blur |
| Android · web · Windows · Linux | Runs without errors; child as-is or an optional frosted glass |
