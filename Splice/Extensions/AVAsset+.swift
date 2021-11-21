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
  
  func makeThumbnails(every nSeconds: TimeInterval, size: CGSize) -> [Thumbnail] {
    let composition = AVVideoComposition(propertiesOf: self)
    let generator = AVAssetImageGenerator(asset: self)
    generator.apertureMode = .cleanAperture
    generator.videoComposition = composition
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = size
    generator.requestedTimeToleranceBefore = .init(seconds: 0.1, preferredTimescale: 600)
    generator.requestedTimeToleranceAfter = .init(seconds: 0.1, preferredTimescale: 600)

    // from async handbook https://khanlou.com/2016/04/the-GCD-handbook/
    let group = DispatchGroup()
    let times: [CMTime] = stride(from: 0.0, to: duration.seconds, by: nSeconds).map { seconds in
      group.enter()
      return CMTime(seconds: seconds, preferredTimescale: composition.frameDuration.timescale)
    }
    
    var thumbnails: [Thumbnail] = []
    
    generator.generateCGImagesAsynchronously(forTimes: times.map{NSValue(time: $0)}) { [weak self]
      requestedTime, cgImage, actualTime, result, error in
      defer { group.leave() }
      guard let self = self, let cgImage = cgImage else {return}
      let image = UIImage(cgImage: cgImage)
      let portion = min(nSeconds, self.duration.seconds - requestedTime.seconds) / nSeconds
      thumbnails.append(Thumbnail(image, widthPortion: portion))
    }
    
    group.wait()
    
    return thumbnails
  }
}
