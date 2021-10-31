//
//  SpliceComposition.swift
//  Splice
//
//  Created by June Kim on 10/29/21.
//

import Foundation
import AVFoundation
import Combine

typealias Splice = ClosedRange<Double>
// source of truth for the assets, segments, and AV composition. Up to one perisstent composition per app (TODO)
class SpliceComposition {
  var assets: [AVAsset] = []
  var splices: [Splice] = []
  
  let timeSubject = CurrentValueSubject<TimeInterval, Never>(0)
  
  var totalDuration: TimeInterval {
    return assets.reduce(0.0) { partialResult, asset in
      return partialResult + asset.duration.seconds
    }
  }
  
  func append(_ splice: Splice) {
    for i in 0..<splices.count {
      let eachOldSplice = splices[i]
      if almostOverlaps(eachOldSplice, splice) {
        let lower = min(eachOldSplice.lowerBound, splice.lowerBound)
        let upper = max(eachOldSplice.upperBound, splice.upperBound)
        splices.append(lower...upper)
        splices.remove(at: i)
        print("joining")
        return
      }
    }
    splices.append(splice)
  }
  
  func almostOverlaps(_ left: Splice, _ right: Splice) -> Bool {
    return left.overlaps(right) ||
    abs(left.upperBound - right.lowerBound) < 0.05 ||
    abs(right.upperBound - left.lowerBound) < 0.05
  }
}

