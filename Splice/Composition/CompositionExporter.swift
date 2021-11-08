//
//  Exporter.swift
//  Sequence
//
//  Created by June Kim on 9/25/21.
//

import AVFoundation
import UIKit

enum CompositionExporterError: Error {
  case badVideoInput
  case badVideoAudio
  case badVoiceInput
  case badMusicInput
  case avFoundation
}

typealias CompositionExportCompletion = (URL?, Error?) -> ()

class CompositionExporter {
  unowned var composition: SpliceComposition
  init(composition: SpliceComposition) {
    self.composition = composition
  }

  
  func export(_ completion: @escaping CompositionExportCompletion) {
    combine() { url, error in
      guard let url = url, error == nil else {
        completion(nil, error)
        return
      }
      completion(url, nil)
      return;
      self.splice(url, completion)
    }
  }
  
  func splice(_ url: URL, _ completion: @escaping CompositionExportCompletion) {
    let videoAsset = AVURLAsset(url: url)
    let mixComposition = AVMutableComposition()
    guard let videoTrack = mixComposition.addMutableTrack(
      withMediaType: .video,
      preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
    else {
      completion(nil, CompositionExporterError.avFoundation)
      return
    }
    guard let firstClipVideoTrack = videoAsset.tracks(withMediaType: .video).first else {
      completion(nil, CompositionExporterError.badVideoInput)
      return
    }
    var isPortraitFrame = false
    let firstTransform = firstClipVideoTrack.preferredTransform
    if (firstTransform.a == 0 && firstTransform.d == 0 &&
        (firstTransform.b == 1.0 || firstTransform.b == -1.0) &&
        (firstTransform.c == 1.0 || firstTransform.c == -1.0)) {
      isPortraitFrame = true
    }
    let naturalSize = firstClipVideoTrack.naturalSize.applying(firstClipVideoTrack.preferredTransform)
    let portraitSize = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
    mixComposition.naturalSize = portraitSize
    videoTrack.preferredTransform = firstClipVideoTrack.preferredTransform
    
    guard let clipsAudioTrack = mixComposition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid) else {
        completion(nil, CompositionExporterError.avFoundation)
        return
      }
    
    var currentDuration = CMTime.zero
    do {
      for eachSplice in composition.splices {
        let eachRange = CMTimeRangeMake(start: eachSplice.lowerBound.cmTime,
                                        duration: (eachSplice.upperBound - eachSplice.lowerBound).cmTime)
        try videoTrack.insertTimeRange(eachRange,
                                       of: videoAsset.tracks(withMediaType: .video)[0],
                                       at: currentDuration)
        if videoAsset.tracks(withMediaType: .audio).count > 0 {
          try clipsAudioTrack.insertTimeRange(eachRange,
                                              of: videoAsset.tracks(withMediaType: .audio)[0], // assume one channel
                                              at: currentDuration)
        }
        currentDuration = currentDuration + eachRange.duration
      }
    } catch {
      completion(nil, CompositionExporterError.badVideoAudio)
      return
    }
    
    let firstVideoTrack = videoAsset.tracks(withMediaType: .video)[0]
    let mainComposition = AVMutableVideoComposition()
    mainComposition.instructions = []
    //    print("videoTrack.nominalFrameRate: ", videoTrack.nominalFrameRate)
    mainComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(firstVideoTrack.nominalFrameRate.rounded()))
    mainComposition.renderSize = firstVideoTrack.naturalSize

    let tempDirectory = FileManager.default.temporaryDirectory
    let url = tempDirectory.appendingPathComponent("shortn-\(UUID().shortened()).mov")
    
    guard let exporter = AVAssetExportSession(
      asset: mixComposition,
      presetName: AVAssetExportPresetPassthrough)
    else { return }
    
    exporter.outputURL = url
    exporter.outputFileType = AVFileType.mov
    exporter.shouldOptimizeForNetworkUse = true
    exporter.videoComposition = mainComposition
    
    exporter.exportAsynchronously {
      DispatchQueue.main.async {
        switch exporter.status {
        case .completed:
          print("export success")
          completion(url, nil)
        case .failed:
          print("export failed \(exporter.error?.localizedDescription ?? "error nil")")
          completion(nil, exporter.error)
        case .cancelled:
          print("export cancelled \(exporter.error?.localizedDescription ?? "error nil")")
          completion(nil, exporter.error)
        default:
          print("export complete with error")
          completion(nil, exporter.error)
        }
      }
    }

    
    

  }

  /*
   exporter                   AVAssetExportSession
   | mixComposition           AVMutableComposition
   | | videoTrack             AVMutableCompositionTrack.video
   | | clipsAudioTrack        AVMutableCompositionTrack.audio
   | mainComposition          AVMutableVideoComposition
   | | mainInstruction        AVMutableVideoCompositionInstruction
   */
  func combine(_ completion: @escaping CompositionExportCompletion) {
    assert(composition.assets.count > 0, "empty clips cannot be exported")
    let videoAssets: [AVAsset] = composition.assets
    
    let mixComposition = AVMutableComposition()
    guard let videoTrack = mixComposition.addMutableTrack(
      withMediaType: .video,
      preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
    else {
      completion(nil, CompositionExporterError.avFoundation)
      return
    }
    
    guard let firstAsset = videoAssets.first,
          let firstClipVideoTrack = firstAsset.tracks(withMediaType: .video).first else {
      completion(nil, CompositionExporterError.badVideoInput)
      return
    }
    /*
     isPortrait_ = [self isVideoPortrait:asset];
     if(isPortrait_) {
     NSLog(@"video is portrait ");
     videoSize = CGSizeMake(videoSize.height, videoSize.width);
     */
    var isPortraitFrame = false
    let firstTransform = firstClipVideoTrack.preferredTransform
    if (firstTransform.a == 0 && firstTransform.d == 0 &&
        (firstTransform.b == 1.0 || firstTransform.b == -1.0) &&
        (firstTransform.c == 1.0 || firstTransform.c == -1.0)) {
      isPortraitFrame = true
    }
    let naturalSize = firstClipVideoTrack.naturalSize.applying(firstClipVideoTrack.preferredTransform)
    let absoluteSize = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
    mixComposition.naturalSize = absoluteSize
    
    // 1 instruction per layer!
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstClipVideoTrack)

    var currentDuration = CMTime.zero
    for eachAsset in videoAssets {
      assert(eachAsset.tracks(withMediaType: .video).count > 0, "No video data found in this video asset")
      do {
        guard let sourceTrack = eachAsset.tracks(withMediaType: .video).first else { break }
        try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: eachAsset.duration),
                                       of: sourceTrack,
                                       at: currentDuration)
        let transform = transform(for: sourceTrack,
                                     isPortraitFrame: isPortraitFrame,
                                     renderSize: mixComposition.naturalSize)
        layerInstruction.setTransform(transform, at: currentDuration)
        currentDuration = CMTimeAdd(currentDuration, eachAsset.duration)
      } catch {
        completion(nil, CompositionExporterError.badVideoInput)
        break
      }
    }
    let totalDuration = videoAssets.reduce(CMTime.zero) { sum, asset in
      return CMTimeAdd(sum, asset.duration)
    }
    assert(currentDuration.seconds == totalDuration.seconds)
    
    let mainInstruction = AVMutableVideoCompositionInstruction()
    mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: totalDuration)
    mainInstruction.layerInstructions = [layerInstruction]
    
    let mainComposition = AVMutableVideoComposition()
    mainComposition.instructions = [mainInstruction]
    mainComposition.frameDuration = CMTimeMake(value: 1,
                                               timescale: Int32(firstClipVideoTrack.nominalFrameRate.rounded()))
    mainComposition.renderSize = absoluteSize
    
    guard let clipsAudioTrack = mixComposition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid) else {
        completion(nil, CompositionExporterError.avFoundation)
        return
      }
    var currentClipAudioDuration = CMTime.zero
    for i in 0..<videoAssets.count {
      let eachVideoAsset = videoAssets[i]
      do {
        if eachVideoAsset.tracks(withMediaType: .audio).count > 0 {
          try clipsAudioTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero,duration: eachVideoAsset.duration),
                                              of: eachVideoAsset.tracks(withMediaType: .audio)[0], // assume one channel
                                              at: currentClipAudioDuration)
        }
        currentClipAudioDuration = CMTimeAdd(currentClipAudioDuration, eachVideoAsset.duration)
      } catch {
        completion(nil, CompositionExporterError.badVideoAudio)
        return
      }
    }
    
    let tempDirectory = FileManager.default.temporaryDirectory
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .short
    let url = tempDirectory.appendingPathComponent("temp\(UUID()).mov")
    
    guard let exporter = AVAssetExportSession(
      asset: mixComposition,
      presetName: exportPreset(for: videoAssets.first!))
    else { return }
    
    exporter.outputURL = url
    exporter.outputFileType = AVFileType.mov
    exporter.shouldOptimizeForNetworkUse = true
    exporter.videoComposition = mainComposition
    
    exporter.exportAsynchronously {
      DispatchQueue.main.async {
        switch exporter.status {
        case .completed:
          print("export success")
          completion(url, nil)
        case .failed:
          print("export failed \(exporter.error?.localizedDescription ?? "error nil")")
          completion(nil, exporter.error)
        case .cancelled:
          print("export cancelled \(exporter.error?.localizedDescription ?? "error nil")")
          completion(nil, exporter.error)
        default:
          print("export complete with error")
          completion(nil, exporter.error)
        }
      }
    }

  }
  
  func exportPreset(for asset: AVAsset) -> String {
    let presets = AVAssetExportSession.exportPresets(compatibleWith: asset)
    let preference = [
      AVAssetExportPresetHEVCHighestQuality,
      AVAssetExportPresetHighestQuality,
      AVAssetExportPresetMediumQuality,
      AVAssetExportPresetLowQuality
    ]
    for eachPref in preference {
      if presets.contains(eachPref) {
        return eachPref
      }
    }
    return AVAssetExportPresetPassthrough
  }
  
  func transform(for assetTrack: AVAssetTrack, isPortraitFrame: Bool, renderSize: CGSize) -> CGAffineTransform {
    let transform = VideoHelper.transform(basedOn: assetTrack)
    let naturalSize = assetTrack.naturalSize.applying(transform)
    let absoluteSize = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
    let isPortraitAsset = absoluteSize.width < absoluteSize.height
    
    let frameAspect = renderSize.width / renderSize.height
    let assetAspect = absoluteSize.width / absoluteSize.height
    // 4 cases total, potrait frame * asset orientation
    if isPortraitFrame {
      if isPortraitAsset {
        if absoluteSize == renderSize {
          return transform.translatedBy(x: 0, y: absoluteSize.height - absoluteSize.width)
        }
        if frameAspect >= assetAspect {
          let boxPortionX = (renderSize.width - absoluteSize.width) / renderSize.width
          return transform
            .translatedBy(x: 0, y: (absoluteSize.height - absoluteSize.width))
            .translatedBy(x: 0, y: -renderSize.width * boxPortionX / 2)
        } else {
          let boxPortionX = (renderSize.width - absoluteSize.width) / renderSize.width
          let boxPortionY = (renderSize.height - absoluteSize.height) / renderSize.height
          return transform
            .scaledBy(x: 1-boxPortionY, y: 1-boxPortionY)
            .translatedBy(x: 0, y: (absoluteSize.height - absoluteSize.width))
            .translatedBy(x: 0, y: -renderSize.width * boxPortionX)
            .translatedBy(x: boxPortionY * renderSize.height, y: 0)
        }
      } else {
        let scaleFactor = absoluteSize.height / renderSize.height
        let boxPortionY = (renderSize.height - absoluteSize.height * scaleFactor) / renderSize.height
        // HAX
        return transform.scaledBy(x: scaleFactor, y: scaleFactor)
          .translatedBy(x: 0, y: boxPortionY * renderSize.height * 0.72)
      }
    }
    if !isPortraitFrame {
      if isPortraitAsset {
        let scaleFactor = renderSize.height / absoluteSize.height
        let boxPortionX = (renderSize.width - absoluteSize.width * scaleFactor) / renderSize.width
        return transform
          .scaledBy(x: scaleFactor, y: scaleFactor)
          .translatedBy(x: 0, y: boxPortionX * renderSize.height * 1.5)
      } else {
        let scaleFactor = absoluteSize.width / renderSize.width
        let boxPortionX = (renderSize.width - absoluteSize.width) / renderSize.width
        let boxPortionY = (renderSize.height - absoluteSize.height) / renderSize.height
        if frameAspect >= assetAspect {
          return transform.scaledBy(x: scaleFactor, y: scaleFactor)
            .translatedBy(x: boxPortionX * renderSize.width, y: 0)
        } else {
          return transform.scaledBy(x: 1/scaleFactor, y: 1/scaleFactor)
            .translatedBy(x: 0, y: boxPortionY * renderSize.height * 0.72)
        }
      }
    }
    return .identity
  }

}
