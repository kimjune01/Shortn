//
//  VideoAsset.swift
//   Sequence
//
//  Created by June Kim on 9/5/21.
//

import UIKit
import AVFoundation

fileprivate var thumbnailCache = NSCache<AnyObject, UIImage>()
typealias SequenceIdentifier = Date

struct VideoAsset: MediaAsset {
  var id: UUID = UUID()
  var sessionID: SequenceIdentifier
  var staticUrl: URL?
  var url: URL {
    if let staticUrl = staticUrl {
      return staticUrl
    }
    if let documentsUrl = try? FileManager.default.documentsDirectory(sessionID: sessionID, uuid: id, pathExtension: "mov") {
      return documentsUrl
    }
    print("no URL!!!")
    return URL(string: "")!
  }
  var duration: Duration? {
    return AVAsset.cacheAsset(for: url).duration.seconds
  }
  var muted: Bool? = true
  var timescale: CMTimeScale? {
    let asset: AVAsset = AVAsset(url: url) as AVAsset
    let composition = AVVideoComposition(propertiesOf: asset)
    return composition.frameDuration.timescale
  }
  
  static func mockClip(sessionID: SequenceIdentifier) -> VideoAsset {
    var mock = VideoAsset(sessionID: sessionID)
    mock.staticUrl = URL(string: "https://i.imgur.com/phrEVez.mp4")
    return mock
  }
  
  func firstThumbnailImage() -> UIImage? {
    let cacheKey = "first" + url.absoluteString
    if let cacheImage = thumbnailCache.object(forKey: cacheKey as AnyObject) {
      return cacheImage
    }
    let asset = AVAsset.cacheAsset(for: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    let composition = AVVideoComposition(propertiesOf: asset)
    let time = CMTime(seconds: 0, preferredTimescale: composition.frameDuration.timescale)
    guard let cgImage = try? imageGenerator.copyCGImage(at:time, actualTime: nil) else { return nil }
    let img = UIImage(cgImage: cgImage)
    thumbnailCache.setObject(img, forKey: cacheKey as AnyObject)
    return img
  }
  
  func thumbnailImage(at time: Duration) -> UIImage? {
    if time == 0 { return firstThumbnailImage() }
    let asset = AVAsset.cacheAsset(for: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    let composition = AVVideoComposition(propertiesOf: asset)
    let time = CMTime(seconds: time, preferredTimescale: composition.frameDuration.timescale)
    guard let cgImage = try? imageGenerator.copyCGImage(at:time, actualTime: nil) else { return nil }
    let img = UIImage(cgImage: cgImage)
    return img
  }
  
  func lastThumbnailImage() -> UIImage? {
    let cacheKey = "last" + url.absoluteString
    if let cacheImage = thumbnailCache.object(forKey: cacheKey as AnyObject) {
      return cacheImage
    }
    let asset = AVAsset.cacheAsset(for: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    let composition = AVVideoComposition(propertiesOf: asset)
    let time =  CMTime(seconds: asset.duration.seconds, preferredTimescale: composition.frameDuration.timescale)
    
    do {
      let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
      let img = UIImage(cgImage: cgImage)
      thumbnailCache.setObject(img, forKey: cacheKey as AnyObject)
      return img
    }
    catch let error as NSError {
      print("Image generation failed with error \(error)")
    }
    return nil
  }
  
  mutating func set(muted: Bool) {
    self.muted = muted
  }
  
  static func === (lhs: VideoAsset, rhs: VideoAsset) -> Bool { return lhs.id == rhs.id }
  
}
