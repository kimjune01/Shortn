//
//  TimeInterval+.swift
//  Splice
//
//  Created by June Kim on 10/30/21.
//

import Foundation
import CoreMedia

extension TimeInterval {
  var cmTime: CMTime {
    return CMTime(seconds: self, preferredTimescale: 600)
  }
  var twoDecimals: String {
    return String(format: "%.2f", self)
  }
}
