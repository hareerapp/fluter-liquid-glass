import AppKit
import FlutterMacOS

public class LiquidGlassPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger
    for kind in LiquidGlassViewFactory.Kind.allCases {
      registrar.register(
        LiquidGlassViewFactory(messenger: messenger, kind: kind),
        withId: kind.rawValue
      )
    }
    let channel = FlutterMethodChannel(name: "liquid_design", binaryMessenger: messenger)
    registrar.addMethodCallDelegate(LiquidGlassPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCapabilities":
      let version = ProcessInfo.processInfo.operatingSystemVersion
      result([
        "liquidGlass": LiquidGlassEffects.isLiquidGlassAvailable,
        "osVersion": "\(version.majorVersion).\(version.minorVersion)",
        "reduceTransparency": NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency,
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class LiquidGlassViewFactory: NSObject, FlutterPlatformViewFactory {
  enum Kind: String, CaseIterable {
    case glass = "liquid_design/glass"
    case group = "liquid_design/glass_group"
    case lens = "liquid_design/lens"
  }

  private let messenger: FlutterBinaryMessenger
  private let kind: Kind

  init(messenger: FlutterBinaryMessenger, kind: Kind) {
    self.messenger = messenger
    self.kind = kind
    super.init()
  }

  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    let args = args as? [String: Any] ?? [:]
    let view: NSView & LiquidGlassUpdatable
    switch kind {
    case .glass: view = LiquidGlassView(frame: .zero)
    case .group: view = LiquidGlassGroupView(frame: .zero)
    case .lens: view = LiquidGlassLensView(frame: .zero)
    }
    view.update(args)
    let channel = FlutterMethodChannel(
      name: "\(kind.rawValue)_\(viewId)",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak view] call, result in
      guard call.method == "update", let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      view?.update(args)
      result(nil)
    }
    objc_setAssociatedObject(view, &channelKey, channel, .OBJC_ASSOCIATION_RETAIN)
    return view
  }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

private var channelKey: UInt8 = 0

protocol LiquidGlassUpdatable: AnyObject {
  func update(_ args: [String: Any])
}

private func number(_ value: Any?) -> CGFloat? {
  (value as? NSNumber).map { CGFloat($0.doubleValue) }
}

struct LiquidGlassConfig: Equatable {
  enum Shape: String { case capsule, roundedRect, rect }

  var shape: Shape = .capsule
  var radius: CGFloat = 0
  var clear = false
  var opacity: CGFloat = 1
  var tint: NSColor?
  var tintOpacity: CGFloat = 0.3
  var appearance: NSAppearance.Name?

  init(_ args: [String: Any]) {
    shape = Shape(rawValue: args["shape"] as? String ?? "") ?? .capsule
    radius = number(args["radius"]) ?? 0
    clear = (args["style"] as? String) == "clear"
    opacity = number(args["opacity"]) ?? 1
    tintOpacity = number(args["tintOpacity"]) ?? 0.3
    if let argb = (args["tint"] as? NSNumber)?.uint32Value {
      tint = NSColor(
        srgbRed: CGFloat((argb >> 16) & 0xFF) / 255,
        green: CGFloat((argb >> 8) & 0xFF) / 255,
        blue: CGFloat(argb & 0xFF) / 255,
        alpha: 1
      )
    }
    switch args["brightness"] as? String {
    case "light": appearance = .aqua
    case "dark": appearance = .darkAqua
    default: appearance = nil
    }
  }

  func sameLook(as other: LiquidGlassConfig?) -> Bool {
    guard let other else { return false }
    return clear == other.clear && tint == other.tint
      && tintOpacity == other.tintOpacity && appearance == other.appearance
  }

  func cornerRadius(for size: CGSize) -> CGFloat {
    let maxRadius = min(size.width, size.height) / 2
    switch shape {
    case .capsule: return maxRadius
    case .roundedRect: return min(radius, maxRadius)
    case .rect: return 0
    }
  }
}

enum LiquidGlassEffects {
  static var isLiquidGlassAvailable: Bool {
    #if compiler(>=6.2)
      if #available(macOS 26.0, *) { return true }
    #endif
    return false
  }

  static func makeSurface() -> NSView {
    #if compiler(>=6.2)
      if #available(macOS 26.0, *) { return NSGlassEffectView() }
    #endif
    let view = NSVisualEffectView()
    view.material = .hudWindow
    view.blendingMode = .withinWindow
    view.state = .active
    view.wantsLayer = true
    return view
  }

  static func applyGeometry(opacity: CGFloat, cornerRadius: CGFloat, to surface: NSView) {
    surface.alphaValue = opacity
    #if compiler(>=6.2)
      if #available(macOS 26.0, *), let glass = surface as? NSGlassEffectView {
        glass.cornerRadius = cornerRadius
        return
      }
    #endif
    surface.layer?.cornerRadius = cornerRadius
  }

  static func apply(_ config: LiquidGlassConfig, cornerRadius: CGFloat, to surface: NSView) {
    surface.appearance = config.appearance.flatMap(NSAppearance.init(named:))
    surface.alphaValue = config.opacity
    #if compiler(>=6.2)
      if #available(macOS 26.0, *), let glass = surface as? NSGlassEffectView {
        glass.style = config.clear ? .clear : .regular
        glass.tintColor = config.tint?.withAlphaComponent(config.tintOpacity)
        glass.cornerRadius = cornerRadius
        return
      }
    #endif
    surface.layer?.cornerRadius = cornerRadius
    surface.layer?.cornerCurve = .continuous
    surface.layer?.masksToBounds = true
    surface.layer?.backgroundColor =
      config.tint?.withAlphaComponent(config.tintOpacity).cgColor
  }
}

class FlippedView: NSView {
  override var isFlipped: Bool { true }
}

final class LiquidGlassView: FlippedView, LiquidGlassUpdatable {
  private let surface = LiquidGlassEffects.makeSurface()
  private var config: LiquidGlassConfig?

  override init(frame: NSRect) {
    super.init(frame: frame)
    wantsLayer = true
    layer?.masksToBounds = true
    layer?.cornerCurve = .continuous
    surface.frame = bounds
    surface.autoresizingMask = [.width, .height]
    addSubview(surface)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  func update(_ args: [String: Any]) {
    config = LiquidGlassConfig(args)
    needsLayout = true
    layoutSurface()
  }

  override func layout() {
    super.layout()
    layoutSurface()
  }

  private func layoutSurface() {
    guard let config else { return }
    surface.frame = bounds
    let radius = config.cornerRadius(for: bounds.size)
    layer?.cornerRadius = radius
    LiquidGlassEffects.apply(config, cornerRadius: radius, to: surface)
  }

  override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

final class LiquidGlassGroupView: FlippedView, LiquidGlassUpdatable {
  private let content = FlippedView()
  private var looks: [Int: LiquidGlassConfig] = [:]
  private let shadowMask = CALayer()
  private var container: NSView?
  private var members: [Int: NSView] = [:]

  override init(frame: NSRect) {
    super.init(frame: frame)
    content.autoresizingMask = [.width, .height]
    #if compiler(>=6.2)
      if #available(macOS 26.0, *) {
        let glassContainer = NSGlassEffectContainerView()
        glassContainer.frame = bounds
        glassContainer.autoresizingMask = [.width, .height]
        content.frame = glassContainer.bounds
        glassContainer.contentView = content
        addSubview(glassContainer)
        container = glassContainer
        return
      }
    #endif
    content.frame = bounds
    addSubview(content)
  }

  override func layout() {
    super.layout()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    if layer?.mask == nil {
      wantsLayer = true
      layer?.mask = shadowMask
    }
    shadowMask.frame = bounds
    CATransaction.commit()
  }

  private func updateShadowMask(_ shapes: [(CGRect, CGFloat)], spacing: CGFloat) {
    var paths: [CGPath] = shapes.map { rect, radius in
      let r = min(radius, min(rect.width, rect.height) / 2)
      return CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)
    }
    if spacing > 0 {
      for i in shapes.indices {
        for j in shapes.indices where j > i {
          let a = shapes[i].0, b = shapes[j].0
          let gap = max(
            max(a.minX, b.minX) - min(a.maxX, b.maxX),
            max(a.minY, b.minY) - min(a.maxY, b.maxY))
          guard gap < spacing else { continue }
          let closeness = max(0, min(1, 1 - gap / spacing))
          guard closeness > 0.4 else { continue }
          let thickness =
            min(min(a.height, b.height), min(a.width, b.width)) * 0.85 * closeness
          let dx = b.midX - a.midX, dy = b.midY - a.midY
          let length = max(hypot(dx, dy), 0.001)
          let nx = -dy / length * thickness / 2, ny = dx / length * thickness / 2
          let bridge = CGMutablePath()
          bridge.addLines(between: [
            CGPoint(x: a.midX + nx, y: a.midY + ny),
            CGPoint(x: b.midX + nx, y: b.midY + ny),
            CGPoint(x: b.midX - nx, y: b.midY - ny),
            CGPoint(x: a.midX - nx, y: a.midY - ny),
          ])
          bridge.closeSubpath()
          paths.append(bridge)
        }
      }
    }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    wantsLayer = true
    if layer?.mask == nil { layer?.mask = shadowMask }
    shadowMask.frame = bounds
    var pieces = shadowMask.sublayers as? [CAShapeLayer] ?? []
    while pieces.count < paths.count {
      let piece = CAShapeLayer()
      piece.fillColor = NSColor.black.cgColor
      shadowMask.addSublayer(piece)
      pieces.append(piece)
    }
    for (index, piece) in pieces.enumerated() {
      piece.frame = shadowMask.bounds
      piece.path = index < paths.count ? paths[index] : nil
    }
    CATransaction.commit()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  func update(_ args: [String: Any]) {
    #if compiler(>=6.2)
      if #available(macOS 26.0, *), let glassContainer = container as? NSGlassEffectContainerView {
        glassContainer.spacing = number(args["spacing"]) ?? 20
      }
    #endif
    guard let list = args["members"] as? [[String: Any]] else { return }

    let groupAppearance = list.first.flatMap { LiquidGlassConfig($0).appearance }
    appearance = groupAppearance.flatMap(NSAppearance.init(named:))
    container?.appearance = appearance
    var shapes: [(CGRect, CGFloat)] = []
    let spacing = number(args["spacing"]) ?? 20
    defer { updateShadowMask(shapes, spacing: spacing) }
    var seen = Set<Int>()
    for member in list {
      guard let id = (member["id"] as? NSNumber)?.intValue else { continue }
      seen.insert(id)
      let config = LiquidGlassConfig(member)
      let surface: NSView
      if let existing = members[id] {
        surface = existing
      } else {
        surface = LiquidGlassEffects.makeSurface()
        content.addSubview(surface)
        members[id] = surface
      }
      surface.frame = NSRect(
        x: number(member["x"]) ?? 0,
        y: number(member["y"]) ?? 0,
        width: number(member["w"]) ?? 0,
        height: number(member["h"]) ?? 0
      )
      let radius = number(member["cornerRadius"]) ?? 0
      shapes.append((surface.frame, radius))
      if config.sameLook(as: looks[id]) {
        LiquidGlassEffects.applyGeometry(
          opacity: config.opacity, cornerRadius: radius, to: surface)
      } else {
        LiquidGlassEffects.apply(config, cornerRadius: radius, to: surface)
        looks[id] = config
      }
    }
    for (id, surface) in members where !seen.contains(id) {
      members[id] = nil
      looks[id] = nil
      surface.removeFromSuperview()
    }
  }

  override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

final class LiquidGlassLensView: FlippedView, LiquidGlassUpdatable {
  private let lens = FlippedView()
  private let glass = LiquidGlassEffects.makeSurface()
  private var config: LiquidGlassConfig?

  override init(frame: NSRect) {
    super.init(frame: frame)
    wantsLayer = true
    lens.wantsLayer = true
    lens.layer?.masksToBounds = true
    lens.layer?.cornerCurve = .continuous
    lens.alphaValue = 0
    glass.autoresizingMask = [.width, .height]
    lens.addSubview(glass)
    addSubview(lens)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  func update(_ args: [String: Any]) {
    var new = LiquidGlassConfig(args)
    new.opacity = 1
    if !new.sameLook(as: config) {
      config = new
      LiquidGlassEffects.apply(
        new, cornerRadius: min(lens.bounds.width, lens.bounds.height) / 2, to: glass)
    }
    guard
      let x = number(args["x"]), let y = number(args["y"]),
      let w = number(args["w"]), let h = number(args["h"])
    else { return }
    let target = NSRect(x: x, y: y, width: w, height: h)
    let alpha = number(args["alpha"]) ?? 1
    let radius = min(w, h) / 2
    LiquidGlassEffects.applyGeometry(opacity: 1, cornerRadius: radius, to: glass)

    let motion = args["motion"] as? String
    if motion == "instant" {
      lens.layer?.removeAllAnimations()
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      lens.frame = target
      lens.alphaValue = alpha
      lens.layer?.cornerRadius = radius
      CATransaction.commit()
      return
    }
    let duration = motion == "follow" ? 0.05 : (number(args["duration"]).map(Double.init) ?? 0.45)
    let timing = CAMediaTimingFunction(name: .easeOut)
    if let layer = lens.layer {
      let corner = CABasicAnimation(keyPath: "cornerRadius")
      corner.fromValue = layer.presentation()?.cornerRadius ?? layer.cornerRadius
      corner.toValue = radius
      corner.duration = duration
      corner.timingFunction = timing
      layer.cornerRadius = radius
      layer.add(corner, forKey: "cornerRadius")
    }
    NSAnimationContext.runAnimationGroup { context in
      context.duration = duration
      context.timingFunction = timing
      context.allowsImplicitAnimation = true
      lens.animator().frame = target
      lens.animator().alphaValue = alpha
    }
  }

  override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
