// raywenderlich

import AVFoundation
import MobileCoreServices
import UIKit

enum VideoHelper {
  static func exportPreset(for asset: AVAsset) -> String {
    let presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
    var preference: [String] = [
      AVAssetExportPresetHighestQuality,
      AVAssetExportPresetMediumQuality,
      AVAssetExportPresetLowQuality
    ]
#if targetEnvironment(simulator)
    // code to run if running on simulator
#else
    // code to run if not running on simulator
    preference = [AVAssetExportPresetHEVCHighestQuality] + preference
#endif
    for eachPref in preference {
      if presets.contains(eachPref) {
        return eachPref
      }
    }
    return AVAssetExportPresetPassthrough
  }
  
  // cropFactor 0 means it's scale aspect fit, everything fits inside with black bars.
  // cropFactor 1 means it's scale aspect fill, there's no black bars left.
  static func scaleAspectFitTransform(for assetTrack: AVAssetTrack, into renderSize: CGSize, cropFactor: CGFloat = 0.25) -> CGAffineTransform {
    guard renderSize.width > 0, renderSize.height > 0 else { return .identity }
    let naturalSize = assetTrack.naturalSize.applying(assetTrack.preferredTransform)
    let absoluteSize = CGSize(width: abs(naturalSize.width),
                              height: abs(naturalSize.height))
    
    let xFactor = renderSize.width / absoluteSize.width
    let yFactor = renderSize.height / absoluteSize.height
    
    let scaleFactor = min(xFactor, yFactor)
    
    var output = assetTrack.preferredTransform.scaledBy(x: scaleFactor, y: scaleFactor)
    output.tx = assetTrack.preferredTransform.tx * scaleFactor
    output.ty = assetTrack.preferredTransform.ty * scaleFactor
    
    let compressedSize = CGSize(width: absoluteSize.width * scaleFactor,
                                height: absoluteSize.height * scaleFactor)
    
    let widthDiff = renderSize.width - compressedSize.width
    let heightDiff = renderSize.height - compressedSize.height
    let plainTranslation = CGAffineTransform.identity.translatedBy(x: widthDiff / 2,
                                                                   y: heightDiff / 2)
    
    let widthBlackPortion = abs(renderSize.width - compressedSize.width) / renderSize.width
    let heightBlackPortion = abs(renderSize.height - compressedSize.height) / renderSize.height
    let blackBarPortion = max(widthBlackPortion, heightBlackPortion)
    let zoomFactor =  (1 - cropFactor) + cropFactor / (1 - blackBarPortion)
    
    var zoom = CGAffineTransform.identity
    zoom.tx = (1-zoomFactor) * renderSize.width / 2
    zoom.ty = (1-zoomFactor) * renderSize.height / 2
    zoom.a = zoomFactor
    zoom.d = zoomFactor
    
    return output.concatenating(plainTranslation).concatenating(zoom)
  }
  
  static func isMixedSize(_ assets: [AVAsset]) -> Bool {
    let sizes = assets.compactMap { asset -> CGSize? in
      guard let track = asset.tracks(withMediaType: .video).first else {
        return nil
      }
      return track.naturalSize
    }
    return Array(Set(sizes)).count > 1
  }
  
  static func sizes(from assets: [AVAsset]) -> [CGSize] {
    let sizes = assets.compactMap { asset -> CGSize? in
      guard let track = asset.tracks(withMediaType: .video).first else {
        return nil
      }
      let size = track.naturalSize.applying(track.preferredTransform)
      return CGSize(width: abs(size.width), height: abs(size.height))
    }
    return sizes
  }
  
  static func maxLandscapeSize(_ assets: [AVAsset]) -> CGSize {
    return sizes(from: assets).sorted { left, right in
      left.width > right.width
    }.first!
  }
  
  static func maxPortraitSize(_ assets: [AVAsset]) -> CGSize {
    return sizes(from: assets).sorted { left, right in
      left.height > right.height
    }.first!
  }
  
  static func normalizedTransforms(for assets: [AVAsset]) -> [CGAffineTransform] {
    return assets.compactMap { asset -> CGAffineTransform? in
      guard let track = asset.tracks(withMediaType: .video).first else {
        return nil
      }
      return normalizedTransform(for: track)
    }
  }
  
  static func normalizedTransform(for track: AVAssetTrack) -> CGAffineTransform {
    return track.preferredTransform
  }
  
}

extension CGSize: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.width)
    hasher.combine(self.height)
  }
  
  
}
