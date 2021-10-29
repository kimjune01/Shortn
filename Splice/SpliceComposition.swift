//
//  SpliceComposition.swift
//  Splice
//
//  Created by June Kim on 10/29/21.
//

import Foundation
import AVFoundation

typealias Splice = (Float, Float)
// source of truth for the assets, segments, and AV composition. Up to one perisstent composition per app (TODO)
class SpliceComposition {
  var assets: [AVAsset] = []
  var splices: [Splice] = []
}
