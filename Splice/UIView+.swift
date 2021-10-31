//
//  UIView+.swift
//   Sequence
//
//  Created by June Kim on 9/4/21.
//

import UIKit

typealias Completion = ()->()
typealias BoolCompletion = (Bool)->()

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
  
  func animateSwell() {
    UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState) {
      self.transform = self.transform.scaledBy(x: 1.15, y: 1.15)
    } completion: { _ in
      UIView.animate(withDuration: 0.25, delay: 0, options: .beginFromCurrentState) {
        self.transform = .identity
      }
    }
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
  
  func startGlowing() {
    stopGlowing()
    layer.masksToBounds = false
    layer.shadowColor = UIColor.white.withAlphaComponent(0.9).cgColor
    layer.shadowRadius = 0
    layer.shadowOpacity = 1
    layer.shadowOffset = .zero
    
    let glowAnimation = CABasicAnimation(keyPath: "shadowRadius")
    glowAnimation.fromValue = 1
    glowAnimation.toValue = 2.8
    glowAnimation.beginTime = CACurrentMediaTime()
    glowAnimation.duration = CFTimeInterval(0.8)
    glowAnimation.fillMode = .removed
    glowAnimation.autoreverses = true
    glowAnimation.repeatCount = .infinity
    layer.add(glowAnimation, forKey: "shadowGlowingAnimation")
  }
  
  func stopGlowing() {
    layer.removeAllAnimations()
    layer.shadowOpacity = 0
  }
}
