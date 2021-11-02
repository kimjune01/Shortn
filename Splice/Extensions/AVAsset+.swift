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
  var isPortrait: Bool {
    guard let videoTrack = self.tracks(withMediaType: .video).first else {
      return false
    }
    let transformedVideoSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
    return abs(transformedVideoSize.width) < abs(transformedVideoSize.height)
    
  }
}
