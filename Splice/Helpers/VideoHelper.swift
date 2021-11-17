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
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {
      return .portrait
    }
    if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {
      return .portraitUpsideDown
    }
    if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) {
      return .landscapeRight
    }
    if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {
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
  
  static func transform(basedOn assetTrack: AVAssetTrack) -> CGAffineTransform {
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
