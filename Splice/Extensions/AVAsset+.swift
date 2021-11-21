//
//  AVAsset+.swift
//   Sequence
//
//  Created by June Kim on 9/17/21.
//

import AVFoundation
import UIKit

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
  
  func makeThumbnails(every nSeconds: TimeInterval) -> [Thumbnail] {
    var currentDuration: TimeInterval = 0
    var thumbnails: [Thumbnail] = []
    while currentDuration < duration.seconds {
      let portion = min(1, duration.seconds - currentDuration)
      let thumb = Thumbnail(UIImage(systemName: "eye")!,
                            widthPortion: portion)
      thumbnails.append(thumb)
      currentDuration += nSeconds
    }
    return thumbnails
  }
}
