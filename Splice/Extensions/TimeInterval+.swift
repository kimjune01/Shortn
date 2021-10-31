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
}
