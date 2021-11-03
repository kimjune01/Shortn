//
//  Exporter.swift
//  Sequence
//
//  Created by June Kim on 9/25/21.
//

import AVFoundation

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
    
    let layerInstructions = [VideoHelper.videoCompositionInstruction(videoTrack, asset: videoAsset)]
    let mainInstruction = AVMutableVideoCompositionInstruction()
    mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: currentDuration)
    mainInstruction.layerInstructions = layerInstructions
    
    let firstVideoTrack = videoAsset.tracks(withMediaType: .video)[0]
    let mainComposition = AVMutableVideoComposition()
    mainComposition.instructions = [mainInstruction]
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
    
    guard let firstClipVideoTrack = videoAssets.first!.tracks(withMediaType: .video).first else {
      completion(nil, CompositionExporterError.badVideoInput)
      return
    }
    /*
     isPortrait_ = [self isVideoPortrait:asset];
     if(isPortrait_) {
     NSLog(@"video is portrait ");
     videoSize = CGSizeMake(videoSize.height, videoSize.width);
     */
    let naturalSize = firstClipVideoTrack.naturalSize.applying(firstClipVideoTrack.preferredTransform)
    let portraitSize = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
    mixComposition.naturalSize = portraitSize
    videoTrack.preferredTransform = firstClipVideoTrack.preferredTransform
    
    var currentDuration = CMTime.zero
    for eachAsset in videoAssets {
      assert(eachAsset.tracks(withMediaType: .video).count > 0, "No video data found in this video asset")
      do {
        try videoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: eachAsset.duration),
                                       of: eachAsset.tracks(withMediaType: .video)[0],
                                       at: currentDuration)
        
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
    
    let layerInstructions = videoAssets.map{ asset in
      return VideoHelper.videoCompositionInstruction(videoTrack, asset: asset)
    }
    let mainInstruction = AVMutableVideoCompositionInstruction()
    mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: totalDuration)
    mainInstruction.layerInstructions = layerInstructions
    
    let firstVideoTrack = videoAssets.first!.tracks(withMediaType: .video)[0]
    let mainComposition = AVMutableVideoComposition()
    mainComposition.instructions = [mainInstruction]
    //    print("videoTrack.nominalFrameRate: ", videoTrack.nominalFrameRate)
    mainComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(firstVideoTrack.nominalFrameRate.rounded()))
    mainComposition.renderSize = portraitSize
    
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
}
