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
  
  // return the generator instance to keep it in memory
  func makeThumbnails(every nSeconds: TimeInterval, size: CGSize, _ progress: @escaping ThumbnailProgress) -> AVAssetImageGenerator {
    let composition = AVVideoComposition(propertiesOf: self)
    let generator = AVAssetImageGenerator(asset: self)
    generator.apertureMode = .cleanAperture
    generator.videoComposition = composition
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = size
    generator.requestedTimeToleranceBefore = .init(seconds: 0.5, preferredTimescale: 600)
    generator.requestedTimeToleranceAfter = .init(seconds: 0.1, preferredTimescale: 600)
    
    let portions = makePortionsArray(nSeconds: nSeconds)
    
    let times: [CMTime] = stride(from: 0, to: duration.seconds, by: nSeconds).map { seconds in
      // sample the middle of where the thumbnail would point to instead of its beginning
      let sample = min(seconds + nSeconds / 2, duration.seconds - nSeconds / 2)
      return CMTime(seconds: sample, preferredTimescale: duration.timescale)
    }
    
    // undo offset by sampling the middle
    func indexFor(requestedTime: TimeInterval) -> Int {
      return Int(((requestedTime - nSeconds / 2) / nSeconds).rounded(.towardZero))
    }
    
    var counter = 0
    
    times.forEach { time in
      do {
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        let image = UIImage(cgImage: cgImage)
        let portion = portions[indexFor(requestedTime: time.seconds)]
        let thumb = Thumbnail(image, widthPortion: portion)
        progress(thumb, counter)
        counter += 1
      } catch let error {
        progress(nil, counter)
        counter += 1
        print(error)
      }
    }
    return generator;
    
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
    return generator
  }
  
  func soloVideoOnlyComposition() -> AVComposition? {
    let mixComposition = AVMutableComposition()
    guard let videoTrack = mixComposition.addMutableTrack(
      withMediaType: .video,
      preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
    else {
      //      completion(nil, CompositionExporterError.avFoundation)
      return nil
    }
    guard let sourceVideoTrack = self.tracks(withMediaType: .video).first else {
      //      completion(nil, CompositionExporterError.badVideoInput)
      return nil
    }
    do {
      let range = CMTimeRange(start: .zero, duration: duration)
      try videoTrack.insertTimeRange(range, of: sourceVideoTrack, at: .zero)
    } catch {
      print("soloVideoOnlyCompositionerror: ", error)
    }
    
    let naturalSize = sourceVideoTrack.naturalSize.applying(sourceVideoTrack.preferredTransform)
    let absoluteSize = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
    mixComposition.naturalSize = absoluteSize

    return mixComposition
  }
  
}
