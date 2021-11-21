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
  static let normalColor: UIColor = .systemYellow.withAlphaComponent(0.3)
  static let expandingColor: UIColor = .systemYellow.withAlphaComponent(0.4)
  static let selectedColor: UIColor = .systemYellow.withAlphaComponent(0.4)

  func appearSelected() {
    animateSwellHorizontal(0.03)
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
