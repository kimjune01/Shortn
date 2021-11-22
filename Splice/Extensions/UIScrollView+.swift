//
//  UIScrollView+.swift
//  Shortn
//
//  Created by June Kim on 11/21/21.
//

import UIKit

extension UIScrollView  {
  
  func stopDecelerating() {
    let contentOffset = self.contentOffset
    self.setContentOffset(contentOffset, animated: false)
  }
}
