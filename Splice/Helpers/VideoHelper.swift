// raywenderlich

import AVFoundation
import MobileCoreServices
import UIKit

enum VideoHelper {
  static func orientationFromTransform(
    _ transform: CGAffineTransform
  ) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
    var assetOrientation = UIImage.Orientation.up
    var isPortrait = false
    let tfA = transform.a
    let tfB = transform.b
    let tfC = transform.c
    let tfD = transform.d

    if tfA == 0 && tfB == 1.0 && tfC == -1.0 && tfD == 0 {
      assetOrientation = .right
      isPortrait = true
    } else if tfA == 0 && tfB == -1.0 && tfC == 1.0 && tfD == 0 {
      assetOrientation = .left
      isPortrait = true
    } else if tfA == 1.0 && tfB == 0 && tfC == 0 && tfD == 1.0 {
      assetOrientation = .up
    } else if tfA == -1.0 && tfB == 0 && tfC == 0 && tfD == -1.0 {
      assetOrientation = .down
    }
    return (assetOrientation, isPortrait)
  }

  static func orientation(for track: AVAssetTrack) -> UIInterfaceOrientation {
    let t = track.preferredTransform
    if (t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) {
      if track.naturalSize.width > track.naturalSize.height {
        return .landscapeRight
      } else {
        return .portrait
      }
    }
    if (t.a == 0 && t.b == 1 && t.c == -1 && t.d == 0 && t.tx > 0) {
      return .portrait
    }
    if (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {
      return .portraitUpsideDown
    }
    if (t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {
      return .landscapeLeft
    }
    return .unknown
  }
  
  static func rotation(basedOn assetTrack: AVAssetTrack) -> CGAffineTransform {
    print("assetTrack.preferredTransform: ", assetTrack.preferredTransform)
    return assetTrack.preferredTransform
    let transform = assetTrack.preferredTransform
    let orientation = orientation(for: assetTrack)
    let naturalSize = assetTrack.naturalSize.applying(transform)
    switch orientation {
    case .unknown:
      return transform
    case .portrait:
      return CGAffineTransform(a: 0,b: 1,c: -1,d: 0,tx: naturalSize.height,ty: 0);
    case .portraitUpsideDown:
      return CGAffineTransform(a: 0,b: -1,c: 1,d: 0,tx: 0,ty: naturalSize.width);
    case .landscapeLeft:
      return CGAffineTransform(a: -1,b: 0,c: 0,d: -1,tx: naturalSize.width,ty: naturalSize.height);
    case .landscapeRight:
      return CGAffineTransform(a: 1,b: 0,c: 0,d: 1,tx: 0,ty: 0);
    @unknown default:
      return transform
    }
  }
  
  // fit the asset track into a portrait frame
  static func transformPortrait(basedOn assetTrack: AVAssetTrack) -> CGAffineTransform {
    let transform = assetTrack.preferredTransform
    let orientation = orientation(for: assetTrack)
    let naturalSize = assetTrack.naturalSize.applying(transform)
    switch orientation {
    case .unknown:
      return transform
    case .portrait:
      return transform
    case .portraitUpsideDown:
      return CGAffineTransform(a: 0,b: -1,c: 1,d: 0,tx: 0,ty: naturalSize.width * 1.77)
    case .landscapeLeft:
      let horizontalPadding = abs(naturalSize.width - naturalSize.height) * 2
      let verticalPadding = -abs(naturalSize.width - naturalSize.height) * 0.3
      return CGAffineTransform(a: -1,b: 0,c: 0,d: -1,tx: -naturalSize.width,ty: -naturalSize.height)
        .scaledBy(x: 1/2, y: 1/2)
        .translatedBy(x: horizontalPadding, y: verticalPadding)
    case .landscapeRight:
      let verticalPadding = abs(naturalSize.width - naturalSize.height) * 1.77
      return CGAffineTransform(a: 1,b: 0,c: 0,d: 1,tx: 0,ty: 0)
        .scaledBy(x: 1/1.9, y: 1/1.9)
        .translatedBy(x: 0, y: verticalPadding)
    @unknown default:
      return transform
    }
  }
  
  // fit the asset track into a landscape frame
  static func transformLandscape(basedOn assetTrack: AVAssetTrack) -> CGAffineTransform {
    let transform = assetTrack.preferredTransform
    let orientation = orientation(for: assetTrack)
    let naturalSize = assetTrack.naturalSize.applying(transform)
    let aspect = abs(naturalSize.height / naturalSize.width)
    switch orientation {
    case .unknown:
      return transform
    case .portrait:
      let horizontalPadding = (naturalSize.width + naturalSize.height) / 2
      return transform.scaledBy(x: 1/aspect, y: 1/aspect).translatedBy(x: 0, y: -horizontalPadding)
    case .portraitUpsideDown:
      let horizontalPadding = (naturalSize.width + naturalSize.height) * 1.5
      let verticalPadding = (naturalSize.width + naturalSize.height) * 1.35
      return transform.scaledBy(x: 1/1.7, y: 1/1.7).translatedBy(x: -horizontalPadding, y: -verticalPadding)
    case .landscapeLeft:
      return transform
    case .landscapeRight:
      return transform
    @unknown default:
      return transform
    }
  }
  
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
  
}
