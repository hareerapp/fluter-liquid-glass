/// Registers liquid_design on platforms without native glass code.
///
/// Android, Windows and Linux need nothing native: widgets there show their
/// child as-is or Flutter-drawn glass.
class LiquidGlassDartPlugin {
  /// Called by Flutter when the app starts.
  static void registerWith() {}
}
