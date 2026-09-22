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
