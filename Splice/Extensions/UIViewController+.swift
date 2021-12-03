//
//  UIViewController+.swift
//  Shortn
//
//  Created by June Kim on 12/3/21.
//

import UIKit

extension UIViewController {
  func showToast(message : String, seconds: Double) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alert.view.backgroundColor = UIColor.black
    alert.view.alpha = 0.4
    alert.view.layer.cornerRadius = 15
    present(alert, animated: true)
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
      alert.dismiss(animated: true)
    }
  }
}
