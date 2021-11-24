//
//  AVAsset+.swift
//   Sequence
//
//  Created by June Kim on 9/17/21.
//

import AVFoundation
import UIKit

fileprivate var cache = [URL:AVAsset]()
typealias ThumbnailProgress = (Thumbnail?, Int) -> ()

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
  
  func widthPortionOfInterval(startTime: TimeInterval, intervalSize: TimeInterval) -> CGFloat {
    return min(intervalSize, duration.seconds - startTime) / intervalSize
  }
  
  func makePortionsArray(nSeconds: TimeInterval) -> [CGFloat] {
    return stride(from: 0, to: duration.seconds, by: nSeconds).map { seconds in
      return widthPortionOfInterval(startTime: seconds, intervalSize: nSeconds)
    }
  }
  
  func makeThumbnails(every nSeconds: TimeInterval, size: CGSize, _ progress: @escaping ThumbnailProgress) {
    let composition = AVVideoComposition(propertiesOf: self)
    let generator = AVAssetImageGenerator(asset: self)
    generator.apertureMode = .cleanAperture
    generator.videoComposition = composition
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = size
    generator.requestedTimeToleranceBefore = .zero
    generator.requestedTimeToleranceAfter = .zero

    let portions = makePortionsArray(nSeconds: nSeconds)

    let times: [CMTime] = stride(from: 0, to: duration.seconds, by: nSeconds).map { seconds in
      // sample the middle of where the thumbnail would point to instead of its beginning
      let sample = min(seconds + nSeconds / 2, duration.seconds)
      return CMTime(seconds: sample, preferredTimescale: composition.frameDuration.timescale)
    }

    // undo offset by sampling the middle
    func indexFor(requestedTime: TimeInterval) -> Int {
      return Int(((requestedTime - nSeconds / 2) / nSeconds).rounded(.towardZero))
    }

    var counter = 0
    
    generator.generateCGImagesAsynchronously(forTimes: times.map{NSValue(time: $0)}) {
      requestedTime, cgImage, actualTime, result, error in
      defer { counter += 1 }
      guard let cgImage = cgImage else {
        if let e = error { print("thumbnail generator error: ", e.localizedDescription)}
        progress(nil, counter)
        return
      }
      let image = UIImage(cgImage: cgImage)
      let portion = portions[indexFor(requestedTime: requestedTime.seconds)]
      let thumb = Thumbnail(image, widthPortion: portion)
      progress(thumb, counter)
    }
  }
}
