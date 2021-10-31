//
//  AVAsset+.swift
//   Sequence
//
//  Created by June Kim on 9/17/21.
//

import AVFoundation

fileprivate var cache = [URL:AVAsset]()

extension AVAsset {
  static func cacheAsset(for url: URL) -> AVAsset {
    if let cached = cache[url] {
      return cached
    }
    let newAsset = AVAsset(url: url)
    cache[url] = newAsset
    return newAsset
  }
}
