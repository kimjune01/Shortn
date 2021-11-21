//
//  TimelineScrollConfig.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import Foundation
import UIKit

struct TimelineScrollConfig {
  static let secondsPerSpan: TimeInterval = 12
  
  static func clipWidthPortion(duration: TimeInterval) -> CGFloat {
    return CGFloat(duration / secondsPerSpan)
  }
}
