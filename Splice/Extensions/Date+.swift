//
//  SequenceIdentifier+.swift
//   Sequence
//
//  Created by June Kim on 9/9/21.
//

import Foundation

extension Date {
  var folderName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yy-MM-dd"
    return formatter.string(from: self)
  }
}
