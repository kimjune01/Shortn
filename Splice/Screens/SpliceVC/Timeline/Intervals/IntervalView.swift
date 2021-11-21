//
//  IntervalView.swift
//  Shortn
//
//  Created by June Kim on 11/21/21.
//

import UIKit

class IntervalView: UIView {
  var isSelected = false {
    didSet {
      if isSelected {
        appearSelected()
      } else {
        appearUnselected()
      }
    }
  }
  static let baseColor: UIColor = .systemBlue
  static let normalColor: UIColor = baseColor.withAlphaComponent(0.3)
  static let expandingColor: UIColor = .systemRed.withAlphaComponent(0.4)
  static let selectedColor: UIColor = baseColor.withAlphaComponent(0.5)

  func appearSelected() {
    animateSwellHorizontal()
    backgroundColor = IntervalView.selectedColor
    doGlowAnimation(withColor: .white, withEffect: .normal)
  }

  func appearUnselected() {
    layer.removeAllAnimations()
    backgroundColor = IntervalView.normalColor
  }
  
  func addColor() {
    backgroundColor = IntervalView.normalColor
    roundCorner(radius: 3, cornerCurve: .continuous)
  }
}
