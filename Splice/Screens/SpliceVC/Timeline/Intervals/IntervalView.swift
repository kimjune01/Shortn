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

  func appearSelected() {
    
  }

  func appearUnselected() {
    
  }
  
  func addColor() {
    backgroundColor = .systemBlue
    roundCorner(radius: 3, cornerCurve: .continuous)
  }
}
