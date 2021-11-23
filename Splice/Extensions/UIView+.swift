//
//  UIView+.swift
//   Sequence
//
//  Created by June Kim on 9/4/21.
//

import UIKit

typealias Completion = ()->()
typealias BoolCompletion = (Bool)->()
typealias ErrorCompletion = (Error?)->()

extension UIView {
  var width: CGFloat {
    return frame.width
  }
  var height: CGFloat {
    return frame.height
  }
  var size: CGSize {
    return frame.size
  }
  var origin: CGPoint {
    return frame.origin
  }
  var minX: CGFloat {
    return frame.minX
  }
  var maxX: CGFloat {
    return frame.maxX
  }
  var minY: CGFloat {
    return frame.minY
  }
  var maxY: CGFloat {
    return frame.maxY
  }
  var midX: CGFloat {
    return frame.midX
  }
  var midY: CGFloat {
    return frame.midY
  }
  // for siblings to use
  var centerFrame: CGPoint {
    return CGPoint(x: midX, y: midY)
  }
  // for children to use
  var centerBounds: CGPoint {
    return CGPoint(x: bounds.midX, y: bounds.midY)
  }

  static var identifier: String {
    return NSStringFromClass(self)
  }
  
  var parentView: UIView {
    return superview!
  }
  
  func pinBottomToParent(margin: CGFloat = 0, insideSafeArea: Bool = true) {
    translatesAutoresizingMaskIntoConstraints = false
    let guide = parentView.safeAreaLayoutGuide
    if insideSafeArea {
      NSLayoutConstraint.activate([
        bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -margin),
      ])
    } else {
      NSLayoutConstraint.activate([
        bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -margin),
      ])
    }
    
  }
  
  func pinTopToParent(margin: CGFloat = 0, insideSafeArea: Bool = true) {
    translatesAutoresizingMaskIntoConstraints = false
    let guide = parentView.safeAreaLayoutGuide
    if insideSafeArea {
      NSLayoutConstraint.activate([
        topAnchor.constraint(equalTo: guide.topAnchor, constant: margin),
      ])
    } else {
      NSLayoutConstraint.activate([
        topAnchor.constraint(equalTo: parentView.topAnchor, constant: margin),
      ])
    }
  }
  
  func pinLeadingToParent(margin: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: margin),
    ])
  }
  
  func pinTrailingToParent(margin: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -margin),
    ])
  }
  
  func set(height: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      heightAnchor.constraint(equalToConstant: height)
    ])
  }
  
  func set(width: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: width)
    ])
  }
  
  func setSquare(constant: CGFloat? = nil) {
    if let k = constant {
      set(width: k)
      set(height: k)
    } else {
      translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        widthAnchor.constraint(equalTo: heightAnchor)
      ])
    }
  }
  
  func fillWidthOfParent(withDefaultMargin: Bool = false) {
    let edgeMargin = withDefaultMargin ? UIView.defaultEdgeMargin : 0
    pinLeadingToParent(margin: edgeMargin)
    pinTrailingToParent(margin: edgeMargin)
  }
  
  func fillHeightOfParent(insideSafeArea: Bool = true) {
    pinTopToParent(margin: 0, insideSafeArea: insideSafeArea)
    pinBottomToParent(margin: 0, insideSafeArea: insideSafeArea)
  }
  
  func fillBottomOfParent(height: CGFloat? = nil, insideSafeArea: Bool = true) {
    pinBottomToParent(margin: 0, insideSafeArea: insideSafeArea)
    fillWidthOfParent()
    if let height = height {
      set(height: height)
    }
  }
  
  func fillTopOfParent(height: CGFloat? = nil, insideSafeArea: Bool = true) {
    pinTopToParent(margin: 0, insideSafeArea: insideSafeArea)
    fillWidthOfParent()
    if let height = height {
      set(height: height)
    }
  }
  
  func pinBottom(toTopOf siblingView: UIView, margin: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      bottomAnchor.constraint(equalTo: siblingView.topAnchor, constant: -margin),
    ])
  }
  
  func pinTop(toBottomOf siblingView: UIView, margin: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topAnchor.constraint(equalTo: siblingView.bottomAnchor, constant: margin),
    ])
  }
  
  func pinLeading(toTrailingOf siblingView: UIView, margin: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      leadingAnchor.constraint(equalTo: siblingView.trailingAnchor, constant: margin),
    ])
  }
  
  func pinTrailing(toLeadingOf siblingView: UIView, margin: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      trailingAnchor.constraint(equalTo: siblingView.leadingAnchor, constant: -margin),
    ])
  }
  
  func setTopToParent(margin: CGFloat){
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topAnchor.constraint(equalTo: parentView.topAnchor, constant: margin),
    ])
  }
  
  func setBottomToParent(margin: CGFloat){
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -margin),
    ])
  }
  
  func centerXInParent(offset: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      centerXAnchor.constraint(equalTo: parentView.centerXAnchor, constant: offset)
    ])
  }
  
  func centerYInParent(offset: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      centerYAnchor.constraint(equalTo: parentView.centerYAnchor, constant: offset)
    ])
  }
  
  func fillParent(withDefaultMargin: Bool = false, insideSafeArea: Bool = true) {
    fillWidthOfParent(withDefaultMargin: withDefaultMargin)
    fillHeightOfParent(insideSafeArea: insideSafeArea)
  }
  
  func fadeOut(_ completion: Completion? = nil) {
    UIView.animate(withDuration: 0.25, delay: 0, options: .beginFromCurrentState) {
      self.alpha = 0
    } completion: { _ in
      completion?()
    }
  }
  
  func fadeIn(_ completion: Completion? = nil) {
    UIView.animate(withDuration: 0.25, delay: 0, options: .beginFromCurrentState) {
      self.alpha = 1
    } completion: { _ in
      completion?()
    }
  }
  
  func animateSwell(_ percentage: CGFloat = 0.15) {
    UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState) {
      self.transform = .identity.scaledBy(x: 1 + percentage, y: 1 + percentage)
    } completion: { _ in
      UIView.animate(withDuration: 0.25, delay: 0, options: .beginFromCurrentState) {
        self.transform = .identity
      }
    }
  }
  
  func animateSwellHorizontal(_ amount: CGFloat = 2) {
    let expansionPercentage = amount / bounds.width
    animateSwell(expansionPercentage)
  }
    
  func roundCorner(radius: CGFloat = 4, cornerCurve: CALayerCornerCurve = .continuous) {
    layer.cornerRadius = radius
    layer.cornerCurve = cornerCurve
    clipsToBounds = true
  }
  
  // margin between two ui elements laid vertically on screen
  static var defaultVerticalMargin: CGFloat { return 12 }

  // margin away from edge of screen
  static var defaultEdgeMargin: CGFloat { return 8 }
  
  /// disables interaction and makes it darker
  func obscure() {
    isUserInteractionEnabled = false
    alpha = 0.3
  }
  
  /// enables interaction and un-darkens it
  func clarify() {
    isUserInteractionEnabled = true
    alpha = 1
  }
  
  func displayTooltip(_ message: String, completion: (() -> Void)? = nil) {
    let tooltipBottomPadding: CGFloat = 12
    let tooltipCornerRadius: CGFloat = 6
    let tooltipAlpha: CGFloat = 0.95
    let pointerBaseWidth: CGFloat = 14
    let pointerHeight: CGFloat = 8
    let padding = CGPoint(x: 18, y: 12)
    
    let tooltip = UIView()
    
    let font = UIFont.preferredFont(for: .headline, weight: .medium)
    
    let tooltipLabel = UILabel()
    tooltipLabel.text = "\(message)"
    tooltipLabel.font = font
    tooltipLabel.textAlignment = .center
    tooltipLabel.textColor = .white
    tooltipLabel.layer.backgroundColor = UIColor(red: 44 / 255, green: 44 / 255, blue: 44 / 255, alpha: 1).cgColor
    tooltipLabel.layer.cornerRadius = tooltipCornerRadius
    
    tooltip.addSubview(tooltipLabel)
    tooltipLabel.translatesAutoresizingMaskIntoConstraints = false
    tooltipLabel.bottomAnchor.constraint(equalTo: tooltip.bottomAnchor, constant: -pointerHeight).isActive = true
    tooltipLabel.topAnchor.constraint(equalTo: tooltip.topAnchor).isActive = true
    tooltipLabel.leadingAnchor.constraint(equalTo: tooltip.leadingAnchor).isActive = true
    tooltipLabel.trailingAnchor.constraint(equalTo: tooltip.trailingAnchor).isActive = true
    
    let labelHeight = message.height(withWidth: .greatestFiniteMagnitude, font: font) + padding.y
    let labelWidth = message.width(withHeight: .zero, font: font) + padding.x
    
    let pointerTip = CGPoint(x: labelWidth / 2, y: labelHeight + pointerHeight)
    let pointerBaseLeft = CGPoint(x: labelWidth / 2 - pointerBaseWidth / 2, y: labelHeight)
    let pointerBaseRight = CGPoint(x: labelWidth / 2 + pointerBaseWidth / 2, y: labelHeight)
    
    let pointerPath = UIBezierPath()
    pointerPath.move(to: pointerBaseLeft)
    pointerPath.addLine(to: pointerTip)
    pointerPath.addLine(to: pointerBaseRight)
    pointerPath.close()
    
    let pointer = CAShapeLayer()
    pointer.path = pointerPath.cgPath
    pointer.fillColor = UIColor(red: 44 / 255, green: 44 / 255, blue: 44 / 255, alpha: 1).cgColor
    
    tooltip.layer.addSublayer(pointer)
    (superview ?? self).addSubview(tooltip)
    tooltip.translatesAutoresizingMaskIntoConstraints = false
    tooltip.bottomAnchor.constraint(equalTo: topAnchor, constant: -tooltipBottomPadding + pointerHeight).isActive = true
    tooltip.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    tooltip.heightAnchor.constraint(equalToConstant: labelHeight + pointerHeight).isActive = true
    tooltip.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
    
    tooltip.alpha = 0
    UIView.animate(withDuration: 0.2, animations: {
      tooltip.alpha = tooltipAlpha
    }, completion: { _ in
      UIView.animate(withDuration: 2.5, delay: 0.5, animations: {
        tooltip.alpha = 0
      }, completion: { _ in
        tooltip.removeFromSuperview()
        completion?()
      })
    })
  }
  
  enum GlowEffect: Float {
    case small = 0.4, normal = 5, big = 15
  }
  
  func doGlowAnimation(withColor color: UIColor, withEffect effect: GlowEffect = .normal) {
    layer.masksToBounds = false
    layer.shadowColor = color.cgColor
    layer.shadowRadius = 0
    layer.shadowOpacity = 1
    layer.shadowOffset = .zero
    
    let glowAnimation = CABasicAnimation(keyPath: "shadowRadius")
    glowAnimation.fromValue = 0
    glowAnimation.toValue = effect.rawValue
    glowAnimation.beginTime = CACurrentMediaTime()
    glowAnimation.duration = CFTimeInterval(0.6)
    glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
    glowAnimation.fillMode = .removed
    glowAnimation.autoreverses = true
    glowAnimation.repeatCount = 1000
    glowAnimation.isRemovedOnCompletion = true
    layer.add(glowAnimation, forKey: "shadowGlowingAnimation")
  }
  
  func roundClipLeftCorners(_ radius: CGFloat) {
    layer.cornerRadius = radius
    layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
  }
  
  func roundClipRightCorners(_ radius: CGFloat) {
    layer.cornerRadius = radius
    layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
  }
}
