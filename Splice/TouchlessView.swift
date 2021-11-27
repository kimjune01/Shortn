//
//  TouchlessView.swift
//  Shortn
//
//  Created by June Kim on 11/27/21.
//

import UIKit

class TouchlessView: UIView {
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let view = super.hitTest(point, with: event)
    if view == self {
      return nil
    }
    return view
  }
}
