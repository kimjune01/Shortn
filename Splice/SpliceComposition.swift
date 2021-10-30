//
//  SpliceComposition.swift
//  Splice
//
//  Created by June Kim on 10/29/21.
//

import Foundation
import AVFoundation

typealias Splice = ClosedRange<Double>
// source of truth for the assets, segments, and AV composition. Up to one perisstent composition per app (TODO)
class SpliceComposition {
  var assets: [AVAsset] = []
  var splices: [Splice] = []
  
  var totalDuration: TimeInterval {
    return assets.reduce(0.0) { partialResult, asset in
      return partialResult + asset.duration.seconds
    }
  }
  
  func append(_ splice: Splice) {
    for i in 0..<splices.count {
      let eachOldSplice = splices[i]
      if eachOldSplice.overlaps(splice) {
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
}
