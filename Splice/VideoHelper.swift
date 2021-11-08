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

  static func videoCompositionInstruction(
    _ track: AVCompositionTrack,
    asset: AVAsset,
    currentTime: CMTime,
    isPortraitFrame: Bool
  ) -> AVMutableVideoCompositionLayerInstruction {
    let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
    let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

    let transform = assetTrack.preferredTransform
    let assetInfo = orientationFromTransform(transform)

    if assetInfo.isPortrait {
      print("portrait transform: ", transform)
      instruction.setTransform(
        assetTrack.preferredTransform,
        at: currentTime)
      
    } else if isPortraitFrame {
      
      print("landscape transform in portrait frame: ", transform)
      print("landscape transform time: ", currentTime)
      return instruction
      instruction.setTransform(
        assetTrack.preferredTransform.rotated(by: CGFloat.pi),
        at: currentTime)
      instruction.setOpacity(0.5, at: currentTime)
    }
    return instruction
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
//  - (CGAffineTransform)transformBasedOnAsset:(AVAsset *)asset {
//    UIInterfaceOrientation orientation = [AVUtilities orientationForTrack:asset];
//    AVAssetTrack *assetTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
//    CGSize naturalSize = assetTrack.naturalSize;
//    CGAffineTransform finalTranform;
//    switch (orientation) {
//    case UIInterfaceOrientationLandscapeLeft:
//      finalTranform = CGAffineTransformMake(-1, 0, 0, -1, naturalSize.width, naturalSize.height);
//      break;
//    case UIInterfaceOrientationLandscapeRight:
//      finalTranform = CGAffineTransformMake(1, 0, 0, 1, 0, 0);
//      break;
//    case UIInterfaceOrientationPortrait:
//      finalTranform = CGAffineTransformMake(0, 1, -1, 0, naturalSize.height, 0);
//      break;
//    case UIInterfaceOrientationPortraitUpsideDown:
//      finalTranform = CGAffineTransformMake(0, -1, 1, 0, 0, naturalSize.width);
//      break;
//    default:
//      break;
//    }
//    return finalTranform;
//  }
  
}
