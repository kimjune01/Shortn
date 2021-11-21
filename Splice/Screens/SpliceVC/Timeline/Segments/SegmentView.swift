//
//  SegmentView.swift
//  Shorten
//
//  Created by June Kim on 11/2/21.
//

import UIKit

class SegmentView: UIView {
  var isSelected = false
  var coloredPortion = UIView()
  
  func appearDeletable() {
    stopAppearingDeletable()
    layer.masksToBounds = false
    layer.shadowColor = UIColor.white.cgColor
    layer.shadowRadius = 8
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
    
    coloredPortion.backgroundColor = .systemPink

    let xImage = UIImageView(image: UIImage(systemName: "xmark"))
    xImage.tintColor = .white
    coloredPortion.addSubview(xImage)
    xImage.centerXInParent()
    xImage.centerYInParent()
  }
  
  func stopAppearingDeletable() {
    layer.removeAllAnimations()
    layer.shadowOpacity = 0
    coloredPortion.backgroundColor = .systemBlue
    for subview in coloredPortion.subviews {
      subview.removeFromSuperview()
    }
  }
  
  func addColor() {
    coloredPortion.frame = CGRect(x: 0,
                                  y: CustomSlider.defaultHeight,
                                  width: width,
                                  height: CustomSlider.defaultHeight)
    coloredPortion.backgroundColor = .systemBlue
    coloredPortion.roundCorner(radius: 3, cornerCurve: .continuous)
    addSubview(coloredPortion)
  }
}
