//
//  UIButton+.swift
//   Sequence
//
//  Created by June Kim on 9/9/21.
//

import UIKit

extension UIButton {
  func setImageScale(to factor: CGFloat) {
    imageView?.layer.transform = CATransform3DMakeScale(factor, factor, 0.8)
  }
  static var sideButtonScale: CGFloat { return 1.2 }
  static var sideButtonSize: CGFloat { return 44 }
  static var actionButtonHeight: CGFloat { return 50 }
  static var icon: UIButton {
    let button = UIButton()
    button.setImageScale(to: 1.2)
    button.tintColor = .white
    return button
  }
  static func backButton() -> UIButton {
    let button = UIButton.icon
    button.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
    return button
  }
}
