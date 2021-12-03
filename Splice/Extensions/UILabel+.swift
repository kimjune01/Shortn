//
//  UILabel+.swift
//  Shortn
//
//  Created by June Kim on 12/2/21.
//

import UIKit

extension UILabel {
  func timeFormat() {
    textAlignment = .center
    text = "0:00"
    font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
    textColor = .white
    backgroundColor = .black.withAlphaComponent(0.3)
  }
  
  func updateTime(_ seconds: TimeInterval) {
    let intSeconds = Int(seconds.rounded())
    let minutes = (intSeconds % 3600) / 60
    let seconds = intSeconds % 60
    text = String(format: "%01d:%02d", minutes, seconds)
  }

}
