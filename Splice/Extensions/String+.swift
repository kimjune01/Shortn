//
//  String+.swift
//  Shorten
//
//  Created by June Kim on 11/3/21.
//

import Foundation
import UIKit
import CryptoKit

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
  
  func md5() -> String {
    return Insecure.MD5.hash(data: self.data(using: .utf8)!).map { String(format: "%02hhx", $0) }.joined()
  }
}
