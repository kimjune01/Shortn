//
//  SegmentView.swift
//  Shorten
//
//  Created by June Kim on 11/2/21.
//

import UIKit

class SegmentView: UIView {
  var isSelected = false

  
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
  
  func addColor() {
    let coloredPortion = UIView(frame: CGRect(x: 0,
                                              y: CustomSlider.defaultHeight,
                                              width: width,
                                              height: CustomSlider.defaultHeight))
    coloredPortion.backgroundColor = .systemBlue
    coloredPortion.roundCorner(radius: 3, cornerCurve: .continuous)
    addSubview(coloredPortion)
  }
}
