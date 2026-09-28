import Flutter
import SwiftUI
import UIKit

public class LiquidGlassPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
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
      result([
        "liquidGlass": LiquidGlassEffects.isLiquidGlassAvailable,
        "osVersion": UIDevice.current.systemVersion,
        "reduceTransparency": UIAccessibility.isReduceTransparencyEnabled,
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

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let args = args as? [String: Any] ?? [:]
    let view: UIView & LiquidGlassUpdatable
    switch kind {
    case .glass: view = LiquidGlassView(frame: frame)
    case .group: view = LiquidGlassGroupView(frame: frame)
    case .lens: view = LiquidGlassLensView(frame: frame)
    }
    view.update(args)
    return LiquidGlassPlatformView(
      view: view,
      channelName: "\(kind.rawValue)_\(viewId)",
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

protocol LiquidGlassUpdatable: AnyObject {
  func update(_ args: [String: Any])
}

final class LiquidGlassPlatformView: NSObject, FlutterPlatformView {
  private let glassView: UIView & LiquidGlassUpdatable
  private let channel: FlutterMethodChannel

  init(view: UIView & LiquidGlassUpdatable, channelName: String, messenger: FlutterBinaryMessenger) {
    glassView = view
    channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update", let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.glassView.update(args)
      result(nil)
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView { glassView }
}

private func number(_ value: Any?) -> CGFloat? {
  (value as? NSNumber).map { CGFloat($0.doubleValue) }
}

struct LiquidGlassPathGeometry: Equatable, Sendable {
  static let empty = LiquidGlassPathGeometry(
    commands: [], evenOdd: false, fit: "contain", alignX: 0, alignY: 0, viewBox: .zero)

  var commands: [CGFloat]
  var evenOdd: Bool
  var fit: String
  var alignX: CGFloat
  var alignY: CGFloat
  var viewBox: CGSize

  init(
    commands: [CGFloat], evenOdd: Bool, fit: String, alignX: CGFloat, alignY: CGFloat,
    viewBox: CGSize
  ) {
    self.commands = commands
    self.evenOdd = evenOdd
    self.fit = fit
    self.alignX = alignX
    self.alignY = alignY
    self.viewBox = viewBox
  }

  init(_ args: [String: Any]) {
    let raw = args["path"] as? [Any] ?? []
    commands = raw.compactMap { ($0 as? NSNumber).map { CGFloat($0.doubleValue) } }
    evenOdd = (args["fillRule"] as? String) == "evenOdd"
    fit = args["fit"] as? String ?? "contain"
    alignX = number(args["alignX"]) ?? 0
    alignY = number(args["alignY"]) ?? 0
    viewBox = CGSize(
      width: number(args["viewBoxWidth"]) ?? 1,
      height: number(args["viewBoxHeight"]) ?? 1)
  }

  func frame(in bounds: CGRect) -> CGRect? {
    let w = viewBox.width, h = viewBox.height
    guard w > 0, h > 0, bounds.width > 0, bounds.height > 0 else { return nil }
    let fx = bounds.width / w, fy = bounds.height / h
    var sx: CGFloat, sy: CGFloat
    switch fit {
    case "fill": sx = fx; sy = fy
    case "cover": sx = max(fx, fy); sy = sx
    case "fitWidth": sx = fx; sy = fx
    case "fitHeight": sx = fy; sy = fy
    case "none": sx = 1; sy = 1
    case "scaleDown": sx = min(1, min(fx, fy)); sy = sx
    default: sx = min(fx, fy); sy = sx
    }
    let size = CGSize(width: w * sx, height: h * sy)
    return CGRect(
      x: bounds.minX + (bounds.width - size.width) * (1 + alignX) / 2,
      y: bounds.minY + (bounds.height - size.height) * (1 + alignY) / 2,
      width: size.width,
      height: size.height)
  }

  func cgPath(in bounds: CGRect) -> CGPath {
    let path = CGMutablePath()
    guard let frame = frame(in: bounds) else { return path }
    func point(_ i: Int) -> CGPoint {
      CGPoint(
        x: frame.minX + commands[i] * frame.width,
        y: frame.minY + commands[i + 1] * frame.height)
    }
    var i = 0
    var open = false
    while i < commands.count {
      let op = Int(commands[i])
      let count = [2, 2, 6, 4, 0][min(max(op, 0), 4)]
      guard i + count < commands.count || (count == 0 && i < commands.count) else { break }
      switch op {
      case 0:
        path.move(to: point(i + 1))
        open = true
      case 1 where open:
        path.addLine(to: point(i + 1))
      case 2 where open:
        path.addCurve(to: point(i + 5), control1: point(i + 1), control2: point(i + 3))
      case 3 where open:
        path.addQuadCurve(to: point(i + 3), control: point(i + 1))
      case 4 where open:
        path.closeSubpath()
      default:
        break
      }
      i += 1 + count
    }
    return path
  }

  func windingPath(in bounds: CGRect) -> CGPath {
    let path = cgPath(in: bounds)
    guard evenOdd, !path.isEmpty else { return path }
    if #available(iOS 16.0, *) { return path.normalized(using: .evenOdd) }
    return path
  }
}

struct LiquidGlassConfig: Equatable {
  enum Shape: String { case capsule, roundedRect, rect, path }

  var shape: Shape = .capsule
  var radius: CGFloat = 0
  var path = LiquidGlassPathGeometry.empty
  var clear = false
  var opacity: CGFloat = 1
  var tint: UIColor?
  var tintOpacity: CGFloat = 0.3
  var style: UIUserInterfaceStyle = .unspecified

  init(_ args: [String: Any]) {
    shape = Shape(rawValue: args["shape"] as? String ?? "") ?? .capsule
    radius = number(args["radius"]) ?? 0
    if shape == .path { path = LiquidGlassPathGeometry(args) }
    clear = (args["style"] as? String) == "clear"
    opacity = number(args["opacity"]) ?? 1
    tintOpacity = number(args["tintOpacity"]) ?? 0.3
    if let argb = (args["tint"] as? NSNumber)?.uint32Value {
      tint = UIColor(
        red: CGFloat((argb >> 16) & 0xFF) / 255,
        green: CGFloat((argb >> 8) & 0xFF) / 255,
        blue: CGFloat(argb & 0xFF) / 255,
        alpha: 1
      )
    }
    switch args["brightness"] as? String {
    case "light": style = .light
    case "dark": style = .dark
    default: style = .unspecified
    }
  }

  func sameLook(as other: LiquidGlassConfig?) -> Bool {
    guard let other else { return false }
    return clear == other.clear && tint == other.tint
      && tintOpacity == other.tintOpacity && style == other.style
  }
}

enum LiquidGlassEffects {
  static var isLiquidGlassAvailable: Bool {
    #if compiler(>=6.2)
      if #available(iOS 26.0, *) { return true }
    #endif
    return false
  }

  static func effect(for config: LiquidGlassConfig) -> UIVisualEffect {
    #if compiler(>=6.2)
      if #available(iOS 26.0, *) {
        let glass = UIGlassEffect(style: config.clear ? .clear : .regular)
        glass.tintColor = config.tint?.withAlphaComponent(config.tintOpacity)
        glass.isInteractive = false
        return glass
      }
    #endif
    return UIBlurEffect(style: config.clear ? .systemUltraThinMaterial : .systemThinMaterial)
  }

  static func shapePath(_ rect: CGRect, radius: CGFloat) -> UIBezierPath {
    UIBezierPath(roundedRect: rect, cornerRadius: min(radius, min(rect.width, rect.height) / 2))
  }

  static func applyFallbackTint(_ config: LiquidGlassConfig, to view: UIVisualEffectView) {
    let tag = 0x71AC
    let tintView =
      view.contentView.viewWithTag(tag)
      ?? {
        let v = UIView(frame: view.contentView.bounds)
        v.tag = tag
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        v.isUserInteractionEnabled = false
        view.contentView.addSubview(v)
        return v
      }()
    let tint = isLiquidGlassAvailable ? nil : config.tint
    tintView.backgroundColor = tint?.withAlphaComponent(config.tintOpacity)
    tintView.isHidden = tint == nil
  }

  static func setEffect(
    _ config: LiquidGlassConfig, previous: LiquidGlassConfig?, on view: UIVisualEffectView
  ) {
    view.overrideUserInterfaceStyle = config.style
    if previous != nil && previous?.style != config.style { view.effect = nil }
    view.effect = effect(for: config)
    applyFallbackTint(config, to: view)
  }

  static func setCornerRadius(_ radius: CGFloat, on view: UIView) {
    view.layer.cornerRadius = radius
    view.layer.cornerCurve = .continuous
    view.clipsToBounds = true
  }
}

#if compiler(>=6.2)
  @available(iOS 26.0, *)
  struct LiquidGlassPathShape: Shape {
    var geometry: LiquidGlassPathGeometry

    func path(in rect: CGRect) -> Path { Path(geometry.windingPath(in: rect)) }
  }

  @available(iOS 26.0, *)
  struct LiquidGlassPathSurface: View {
    var geometry: LiquidGlassPathGeometry
    var clear: Bool
    var tint: Color?

    var body: some View {
      Color.clear
        .glassEffect(glass, in: LiquidGlassPathShape(geometry: geometry))
        .ignoresSafeArea()
    }

    private var glass: Glass {
      let base: Glass = clear ? .clear : .regular
      guard let tint else { return base }
      return base.tint(tint)
    }
  }
#endif

final class LiquidGlassPathMaskView: UIView {
  override class var layerClass: AnyClass { CAShapeLayer.self }

  var shapeLayer: CAShapeLayer { layer as! CAShapeLayer }
}

final class LiquidGlassView: UIView, LiquidGlassUpdatable {
  private var effectView = UIVisualEffectView(effect: nil)
  private var config: LiquidGlassConfig?
  private var pathHost: UIViewController?
  private var pathMask: LiquidGlassPathMaskView?
  private let hostMask = CAShapeLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
    clipsToBounds = true
    effectView.frame = bounds
    effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(effectView)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  func update(_ args: [String: Any]) {
    let new = LiquidGlassConfig(args)
    if new.shape == .path {
      updatePath(new)
      return
    }
    leavePathMode()
    let old = config
    config = new
    effectView.alpha = new.opacity

    if !new.sameLook(as: old) {
      UIView.performWithoutAnimation {
        overrideUserInterfaceStyle = new.style
        if let old, old.style != new.style {
          let fresh = UIVisualEffectView(effect: nil)
          fresh.frame = bounds
          fresh.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          fresh.alpha = new.opacity
          insertSubview(fresh, aboveSubview: effectView)
          effectView.removeFromSuperview()
          effectView = fresh
        }
        LiquidGlassEffects.setEffect(new, previous: nil, on: effectView)
        effectView.layoutIfNeeded()
      }
    }
    setNeedsLayout()
  }

  private func updatePath(_ new: LiquidGlassConfig) {
    let old = config
    config = new
    LiquidGlassEffects.setCornerRadius(0, on: self)
    #if compiler(>=6.2)
      if #available(iOS 26.0, *) {
        let surface = LiquidGlassPathSurface(
          geometry: new.path,
          clear: new.clear,
          tint: new.tint.map { Color(uiColor: $0.withAlphaComponent(new.tintOpacity)) })
        UIView.performWithoutAnimation {
          effectView.effect = nil
          effectView.isHidden = true
          overrideUserInterfaceStyle = new.style
          let host: UIHostingController<LiquidGlassPathSurface>
          if let existing = pathHost as? UIHostingController<LiquidGlassPathSurface> {
            host = existing
            host.rootView = surface
          } else {
            host = UIHostingController(rootView: surface)
            host.safeAreaRegions = []
            host.view.backgroundColor = .clear
            host.view.isOpaque = false
            host.view.isUserInteractionEnabled = false
            host.view.frame = bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostMask.fillColor = UIColor.black.cgColor
            host.view.layer.mask = hostMask
            addSubview(host.view)
            pathHost = host
          }
          applyHostMask(new.path)
          host.view.overrideUserInterfaceStyle = new.style
          host.view.alpha = new.opacity
        }
        setNeedsLayout()
        return
      }
    #endif
    let mask = pathMask ?? {
      let view = LiquidGlassPathMaskView(frame: effectView.bounds)
      view.shapeLayer.fillColor = UIColor.black.cgColor
      pathMask = view
      return view
    }()
    UIView.performWithoutAnimation {
      effectView.isHidden = false
      effectView.alpha = new.opacity
      LiquidGlassEffects.setCornerRadius(0, on: effectView)
      applyPathMask(mask, geometry: new.path)
      if effectView.mask !== mask { effectView.mask = mask }
      if !new.sameLook(as: old) {
        overrideUserInterfaceStyle = new.style
        LiquidGlassEffects.setEffect(new, previous: nil, on: effectView)
      }
    }
    setNeedsLayout()
  }

  private func applyHostMask(_ geometry: LiquidGlassPathGeometry) {
    guard let view = pathHost?.view else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    hostMask.frame = view.bounds
    hostMask.fillRule = geometry.evenOdd ? .evenOdd : .nonZero
    hostMask.path = geometry.cgPath(in: view.bounds)
    CATransaction.commit()
  }

  private func applyPathMask(_ mask: LiquidGlassPathMaskView, geometry: LiquidGlassPathGeometry) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    mask.frame = effectView.bounds
    mask.shapeLayer.fillRule = geometry.evenOdd ? .evenOdd : .nonZero
    mask.shapeLayer.path = geometry.cgPath(in: mask.bounds)
    CATransaction.commit()
  }

  private func leavePathMode() {
    guard pathHost != nil || pathMask != nil else { return }
    UIView.performWithoutAnimation {
      pathHost?.view.layer.mask = nil
      pathHost?.view.removeFromSuperview()
      pathHost = nil
      effectView.mask = nil
      pathMask = nil
      effectView.isHidden = false
    }
    config = nil
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    guard let config else { return }
    if config.shape == .path {
      pathHost?.view.frame = bounds
      applyHostMask(config.path)
      if let pathMask { applyPathMask(pathMask, geometry: config.path) }
      return
    }
    let maxRadius = min(bounds.width, bounds.height) / 2
    let radius: CGFloat
    switch config.shape {
    case .capsule: radius = maxRadius
    case .roundedRect: radius = min(config.radius, maxRadius)
    case .rect, .path: radius = 0
    }
    LiquidGlassEffects.setCornerRadius(radius, on: effectView)
    LiquidGlassEffects.setCornerRadius(radius, on: self)
  }
}

final class LiquidGlassGroupView: UIView, LiquidGlassUpdatable {
  private var container = UIVisualEffectView(effect: nil)
  private var groupStyle: UIUserInterfaceStyle?
  private var lastArgs: [String: Any]?
  private var builtInWindow = false
  private let shadowMask = CALayer()
  private var members: [Int: UIVisualEffectView] = [:]
  private var looks: [Int: LiquidGlassConfig] = [:]
  private var spacing: CGFloat = -1

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
    container.frame = bounds
    container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(container)
    layer.mask = shadowMask
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    shadowMask.frame = bounds
    CATransaction.commit()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    guard window != nil, !builtInWindow, let args = lastArgs else { return }
    builtInWindow = true
    rebuildContainer()
    groupStyle = nil
    update(args)
  }

  private func applyContainerEffect() {
    #if compiler(>=6.2)
      if #available(iOS 26.0, *) {
        let effect = UIGlassContainerEffect()
        effect.spacing = max(spacing, 0)
        container.effect = effect
      }
    #endif
  }

  private func rebuildContainer() {
    UIView.performWithoutAnimation {
      let fresh = UIVisualEffectView(effect: nil)
      fresh.frame = bounds
      fresh.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      insertSubview(fresh, aboveSubview: container)
      container.removeFromSuperview()
      container = fresh
    }
    members.removeAll()
    looks.removeAll()
  }

  private func updateShadowMask(_ shapes: [(CGRect, CGFloat)]) {
    var paths: [CGPath] = shapes.map { rect, radius in
      LiquidGlassEffects.shapePath(rect, radius: radius).cgPath
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
          let ca = CGPoint(x: a.midX, y: a.midY), cb = CGPoint(x: b.midX, y: b.midY)
          let bridge = UIBezierPath()
          let dx = cb.x - ca.x, dy = cb.y - ca.y
          let length = max(hypot(dx, dy), 0.001)
          let nx = -dy / length * thickness / 2, ny = dx / length * thickness / 2
          bridge.move(to: CGPoint(x: ca.x + nx, y: ca.y + ny))
          bridge.addLine(to: CGPoint(x: cb.x + nx, y: cb.y + ny))
          bridge.addLine(to: CGPoint(x: cb.x - nx, y: cb.y - ny))
          bridge.addLine(to: CGPoint(x: ca.x - nx, y: ca.y - ny))
          bridge.close()
          paths.append(bridge.cgPath)
        }
      }
    }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    shadowMask.frame = bounds
    var pieces = shadowMask.sublayers as? [CAShapeLayer] ?? []
    while pieces.count < paths.count {
      let piece = CAShapeLayer()
      piece.fillColor = UIColor.black.cgColor
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
    let newSpacing = number(args["spacing"]) ?? 20
    if newSpacing != spacing {
      spacing = newSpacing
      applyContainerEffect()
    }
    guard let list = args["members"] as? [[String: Any]] else { return }
    lastArgs = args

    var materialize = true
    let style = list.first.map { LiquidGlassConfig($0).style } ?? .unspecified
    if style != groupStyle {
      if groupStyle != nil {
        rebuildContainer()
        materialize = false
      }
      groupStyle = style
      overrideUserInterfaceStyle = style
      container.overrideUserInterfaceStyle = style
      applyContainerEffect()
    }

    var shapes: [(CGRect, CGFloat)] = []
    defer { updateShadowMask(shapes) }
    var seen = Set<Int>()
    for member in list {
      guard let id = (member["id"] as? NSNumber)?.intValue else { continue }
      seen.insert(id)
      let config = LiquidGlassConfig(member)
      let frame = CGRect(
        x: number(member["x"]) ?? 0,
        y: number(member["y"]) ?? 0,
        width: number(member["w"]) ?? 0,
        height: number(member["h"]) ?? 0
      )
      let radius = number(member["cornerRadius"]) ?? 0
      shapes.append((frame, radius))

      if let view = members[id] {
        UIView.performWithoutAnimation {
          view.frame = frame
          LiquidGlassEffects.setCornerRadius(
            min(radius, min(frame.width, frame.height) / 2), on: view)
          view.alpha = config.opacity
          if !config.sameLook(as: looks[id]) {
            LiquidGlassEffects.setEffect(config, previous: looks[id], on: view)
          }
        }
      } else {
        let view = UIVisualEffectView(effect: nil)
        let animated = materialize
        view.isUserInteractionEnabled = false
        UIView.performWithoutAnimation {
          view.frame = frame
          LiquidGlassEffects.setCornerRadius(
            min(radius, min(frame.width, frame.height) / 2), on: view)
          view.overrideUserInterfaceStyle = config.style
          view.alpha = config.opacity
          LiquidGlassEffects.applyFallbackTint(config, to: view)
        }
        container.contentView.addSubview(view)
        members[id] = view
        if animated {
          UIView.animate(withDuration: 0.3) {
            view.effect = LiquidGlassEffects.effect(for: config)
          }
        } else {
          UIView.performWithoutAnimation {
            view.effect = LiquidGlassEffects.effect(for: config)
          }
        }
      }
      looks[id] = config
    }

    for (id, view) in members where !seen.contains(id) {
      members[id] = nil
      looks[id] = nil
      view.removeFromSuperview()
    }
  }
}

final class LiquidGlassLensView: UIView, LiquidGlassUpdatable {
  private let lens = UIView()
  private var glass = UIVisualEffectView(effect: nil)
  private var config: LiquidGlassConfig?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
    lens.isUserInteractionEnabled = false
    lens.alpha = 0
    lens.clipsToBounds = true
    glass.frame = lens.bounds
    glass.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    lens.addSubview(glass)
    addSubview(lens)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  func update(_ args: [String: Any]) {
    let new = LiquidGlassConfig(args)
    if !new.sameLook(as: config) {
      let previous = config
      config = new
      UIView.performWithoutAnimation {
        if let previous, previous.style != new.style {
          let fresh = UIVisualEffectView(effect: nil)
          fresh.frame = lens.bounds
          fresh.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          fresh.layer.cornerRadius = glass.layer.cornerRadius
          fresh.layer.cornerCurve = .continuous
          fresh.clipsToBounds = true
          lens.insertSubview(fresh, aboveSubview: glass)
          glass.removeFromSuperview()
          glass = fresh
        }
        LiquidGlassEffects.setEffect(new, previous: nil, on: glass)
      }
    }

    guard
      let x = number(args["x"]), let y = number(args["y"]),
      let w = number(args["w"]), let h = number(args["h"])
    else { return }
    let target = CGRect(x: x, y: y, width: w, height: h)
    let alpha = number(args["alpha"]) ?? 1
    let radius = min(w, h) / 2
    let apply = {
      self.lens.frame = target
      self.lens.layer.cornerRadius = radius
      self.glass.layer.cornerRadius = radius
      self.lens.alpha = alpha
    }
    lens.layer.cornerCurve = .continuous
    glass.layer.cornerCurve = .continuous
    glass.clipsToBounds = true

    let options: UIView.AnimationOptions = [.beginFromCurrentState, .allowUserInteraction]
    switch args["motion"] as? String {
    case "instant":
      lens.layer.removeAllAnimations()
      glass.layer.removeAllAnimations()
      UIView.performWithoutAnimation(apply)
    case "follow":
      UIView.animate(
        withDuration: 0.05, delay: 0, options: options.union(.curveEaseOut),
        animations: apply)
    default:
      UIView.animate(
        withDuration: number(args["duration"]) ?? 0.45,
        delay: 0,
        usingSpringWithDamping: number(args["damping"]) ?? 0.72,
        initialSpringVelocity: 0,
        options: options,
        animations: apply)
    }
  }
}
