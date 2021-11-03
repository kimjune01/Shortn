//
//  String+.swift
//  Shorten
//
//  Created by June Kim on 11/3/21.
//

import Foundation
import UIKit

extension String {
  func width(withHeight constrainedHeight: CGFloat, font: UIFont) -> CGFloat {
    let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: constrainedHeight)
    let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
    return ceil(boundingBox.width)
  }
  
  func height(withWidth constrainedWidth: CGFloat, font: UIFont) -> CGFloat {
    let constraintRect = CGSize(width: constrainedWidth, height: .greatestFiniteMagnitude)
    let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
    return ceil(boundingBox.height)
  }
}
