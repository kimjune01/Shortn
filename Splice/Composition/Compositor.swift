//
//  Exporter.swift
//  Sequence
//
//  Created by June Kim on 9/25/21.
//

import AVFoundation
import UIKit

enum CompositorError: Error {
  case badVideoInput
  case badVideoAudio
  case badVoiceInput
  case badMusicInput
  case avFoundation
  case badVoiceoverInput
}

typealias CompositorCompletion = (URL?, Error?) -> ()

class Compositor {
  unowned var composition: SpliceComposition
  var spliceInstruction = AVMutableVideoCompositionInstruction()
  var spliceComposition = AVMutableVideoComposition()
  static var debugging = false
  init(composition: SpliceComposition) {
    self.composition = composition
  }
  // to be called only after concatAndSplice
  func export(_ asset: AVAsset, _ completion: @escaping CompositorCompletion) {
    let tempDirectory = FileManager.default.temporaryDirectory
    let url = tempDirectory.appendingPathComponent("tempExport\(composition.description.md5()).mp4")
    guard !FileManager.default.fileExists(atPath: url.path) else {
      print("export already saved")
      completion(url, nil)
      return
    }
    guard let exporter = AVAssetExportSession(
      asset: asset,
      presetName: VideoHelper.exportPreset(for: asset))
    else {
      completion(nil, CompositorError.avFoundation)
      return
    }
    
    exporter.outputURL = url
    exporter.shouldOptimizeForNetworkUse = true
    exporter.videoComposition = spliceComposition
    let group = DispatchGroup()
    group.enter()
    exporter.determineCompatibleFileTypes { types in
      if types.isEmpty {
        print("Compositor.export(): No supported file types found!")
      }
      if types.contains(.m4v) {
        exporter.outputFileType = .mp4
      } else {
        exporter.outputFileType = .mov
      }
      group.leave()
    }
    group.wait()
    
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
   Concatenates and splices, returns the composition for preview before exporting.
   mixComposition           AVMutableComposition
   | videoTrack             AVMutableCompositionTrack.video
   | audioTrack        AVMutableCompositionTrack.audio
   spliceComposition          AVMutableVideoComposition
   | spliceInstruction        AVMutableVideoCompositionInstruction
   | | layerInstruction        AVMutableVideoCompositionLayerInstruction
   */
  func concatAndSplice() -> AVAsset? {
    assert(composition.assets.count > 0, "empty clips cannot be exported")
    //    composition.cutToTheBeatIfNeeded()
    let videoAssets: [AVAsset] = composition.assets
    
    let mixComposition = AVMutableComposition()
    guard var videoTrack = mixComposition.addMutableTrack(
      withMediaType: .video,
      preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
    else {
      //      completion(nil, CompositionExporterError.avFoundation)
      return nil
    }
    guard var audioTrack = mixComposition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid)
    else {
      //      completion(nil, CompositionExporterError.avFoundation)
      return nil
    }
    
    guard let firstAsset = videoAssets.first,
          let firstClipVideoTrack = firstAsset.tracks(withMediaType: .video).first else {
      //      completion(nil, CompositionExporterError.badVideoInput)
      return nil
    }
    
    let maxLandscapeSize = VideoHelper.maxLandscapeSize(videoAssets)
    let maxPortraitSize = VideoHelper.maxPortraitSize(videoAssets)
    var isPortraitFrame = false
    let firstTransform = firstClipVideoTrack.preferredTransform
    let natural = firstClipVideoTrack.naturalSize
    if (firstTransform.a == 1.0 && firstTransform.d == 1.0 &&
        natural.width < natural.height) {
      isPortraitFrame = true
    } else if (firstTransform.b == 1.0 && firstTransform.c == -1.0 &&
               natural.width > natural.height && firstTransform.tx > 0) {
      isPortraitFrame = true
    }
    
    videoTrack.preferredTransform = .identity
    
    if isPortraitFrame {
      mixComposition.naturalSize = maxPortraitSize
    } else {
      mixComposition.naturalSize = maxLandscapeSize
    }
    // 1 instruction per layer!
    // use videoTrack instead of firstClipVideoTrack
    // https://www.ostack.cn/?qa=908888/
    var layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    let splices = composition.splices
    let (totalDuration, error) = fillTracks(from: videoAssets,
                                            splices: splices,
                                            isPortraitFrame: isPortraitFrame,
                                            renderSize: mixComposition.naturalSize,
                                            videoTrackOutput: &videoTrack,
                                            audioTrackOutput: &audioTrack,
                                            instructionOutput: &layerInstruction)
    if error != nil {
      return nil
      //      completion(nil, error)
    }
    
    // for when there is no audio, remove the audio track. For downloaded videos!
    if let audioTrack = mixComposition.tracks(withMediaType: .audio).first,
       audioTrack.segments.isEmpty {
      mixComposition.removeTrack(audioTrack)
    }
    
    spliceInstruction = AVMutableVideoCompositionInstruction()
    spliceInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: totalDuration)
    spliceInstruction.layerInstructions = [layerInstruction]
    
    spliceComposition = AVMutableVideoComposition()
    spliceComposition.renderSize = mixComposition.naturalSize
    spliceComposition.instructions = [spliceInstruction]
    spliceComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(firstClipVideoTrack.nominalFrameRate.rounded()))
    
    return mixComposition
  }
  
  /*
   Concatenates and splices, returns the composition for preview before exporting.
   mixComposition           AVMutableComposition
   | videoTrack             AVMutableCompositionTrack.video
   | audioTrack        AVMutableCompositionTrack.audio
   videoComposition          AVMutableVideoComposition
   */
  func add(voiceover segments: [AVAsset], to videoAsset: AVAsset, _ completion: @escaping CompositorCompletion) {
    assert(segments.count > 0, "Need voiceover segments!")
    let mixComposition = AVMutableComposition()
    // add video track and audio track to a composition
    guard let videoTrack = mixComposition.addMutableTrack(
      withMediaType: .video,
      preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
    else {
      completion(nil, CompositorError.avFoundation)
      return
    }
    guard let audioTrack = mixComposition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid)
    else {
      completion(nil, CompositorError.avFoundation)
      return
    }
    guard let videoAudioTrack = mixComposition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid)
    else {
      completion(nil, CompositorError.avFoundation)
      return
    }
    
    
    do {
      let wholeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
      guard let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
        throw CompositorError.badVideoInput
      }
      try videoTrack.insertTimeRange(wholeRange, of: videoAssetTrack, at: .zero)
      if composition.includeOriginalAudio {
        guard let videoAudioAssetTrack = videoAsset.tracks(withMediaType: .audio).first else {
          throw CompositorError.badVideoAudio
        }
        try videoAudioTrack.insertTimeRange(wholeRange, of: videoAudioAssetTrack, at: .zero)
      }
    } catch {
      assert(false)
      print(error)
    }
    
    var currentTime: TimeInterval = 0
    do {
      for eachSegment in segments {
        guard let voiceoverTrack = eachSegment.tracks(withMediaType: .audio).first else { // assume mono track
          completion(nil, CompositorError.badVoiceoverInput)
          return
        }
        let range = CMTimeRange(start: .zero, duration: eachSegment.duration)
        try audioTrack.insertTimeRange(range, of: voiceoverTrack, at: currentTime.cmTime)
        currentTime += eachSegment.duration.seconds
      }
    } catch {
      assert(false)
      print(error)
    }
    
    
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    
    let compositionInstruction = AVMutableVideoCompositionInstruction()
    compositionInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: videoAsset.duration)
    compositionInstruction.layerInstructions = [layerInstruction]
    
    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = videoTrack.naturalSize
    videoComposition.instructions = [compositionInstruction]
    videoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(videoTrack.nominalFrameRate.rounded()))
    
    
    // export with passthrough
    let tempDirectory = FileManager.default.temporaryDirectory
    let url = tempDirectory.appendingPathComponent("voiceoverExport\(composition.description.md5()).mp4")
    guard !FileManager.default.fileExists(atPath: url.path) else {
      print("voiceover export already saved")
      completion(url, nil)
      return
    }
    guard let exporter = AVAssetExportSession(
      asset: mixComposition,
      presetName: AVAssetExportPresetPassthrough)
    else {
      completion(nil, CompositorError.avFoundation)
      return
    }
    
    exporter.outputURL = url
    exporter.shouldOptimizeForNetworkUse = true
    exporter.videoComposition = videoComposition
    let group = DispatchGroup()
    group.enter()
    exporter.determineCompatibleFileTypes { types in
      if types.isEmpty {
        print("Voiceover export: No supported file types found!")
      }
      if types.contains(.m4v) {
        exporter.outputFileType = .mp4
      } else {
        exporter.outputFileType = .mov
      }
      group.leave()
    }
    group.wait()
    
    exporter.exportAsynchronously {
      DispatchQueue.main.async {
        switch exporter.status {
        case .completed:
          print("voiceover export success")
          completion(url, nil)
        case .failed:
          print("voiceover export failed \(exporter.error?.localizedDescription ?? "error nil")")
          completion(nil, exporter.error)
        case .cancelled:
          print("voiceover export cancelled \(exporter.error?.localizedDescription ?? "error nil")")
          completion(nil, exporter.error)
        default:
          print("voiceover export complete with error")
          completion(nil, exporter.error)
        }
      }
    }
  }
  
  func fillTracks(from sourceVideoAssets: [AVAsset],
                  splices: [Splice],
                  isPortraitFrame: Bool,
                  renderSize: CGSize,
                  videoTrackOutput: inout AVMutableCompositionTrack,
                  audioTrackOutput: inout AVMutableCompositionTrack,
                  instructionOutput: inout AVMutableVideoCompositionLayerInstruction)
  -> (CMTime, CompositorError?) {
    guard sourceVideoAssets.count > 0 else { return (.zero, .badVideoInput) }
    //    print("splices: ", splices)
    //    print("sum of splices: ", splices.reduce(0.0, { partialResult, sp in
    //      partialResult - sp.lowerBound + sp.upperBound
    //    }))
    
    func cuts(for sourceAsset: AVAsset, at index: Int) -> [CMTimeRange]{
      let assetStartTime: Double = sourceVideoAssets[0..<index].reduce(CMTime.zero) { partialResult, prefixAsset in
        return CMTimeAdd(partialResult, prefixAsset.duration)
      }.seconds
      let assetDuration = sourceAsset.duration.seconds
      let ranges = splices.map { eachSplice in
        return (eachSplice.lowerBound - assetStartTime)...(eachSplice.upperBound - assetStartTime)
      }.filter { eachSplice in
        return eachSplice.upperBound > 0 && eachSplice.lowerBound < assetDuration
      }.map { eachSplice -> Splice in
        if eachSplice.lowerBound < 0 {
          return 0...min(assetDuration, eachSplice.upperBound)
        } else if eachSplice.upperBound > assetDuration {
          return eachSplice.lowerBound...assetDuration
        } else {
          return eachSplice
        }
      }.map { eachSplice -> CMTimeRange in
        let startCMTime = eachSplice.lowerBound.cmTime
        let endCMTime = eachSplice.upperBound.cmTime
        return CMTimeRange(start: startCMTime, end: endCMTime)
      }
      debugPrint("for vid starting at \(assetStartTime.twoDecimals) with duration \(assetDuration.twoDecimals), \n  there are \(ranges.count) ranges")
      for r in ranges {
        debugPrint("__ start: \(r.start.seconds.twoDecimals), end: \(r.end.seconds.twoDecimals)")
      }
      return ranges
    }
    
    var currentDuration = 0.0.cmTime
    do {
      for i in 0..<sourceVideoAssets.count {
        let sourceAsset = sourceVideoAssets[i]
        
        for eachRange in cuts(for: sourceAsset, at: i) {
          if let sourceVideoTrack = sourceAsset.tracks(withMediaType: .video).first {
            try videoTrackOutput.insertTimeRange(eachRange, of: sourceVideoTrack, at: currentDuration)
            let transform = VideoHelper.scaleAspectFitTransform(for: sourceVideoTrack,
                                                                into: renderSize)
            instructionOutput.setTransform(transform, at: currentDuration)
          }
          if let sourceAudioTrack = sourceAsset.tracks(withMediaType: .audio).first {
            try audioTrackOutput.insertTimeRange(eachRange, of: sourceAudioTrack, at: currentDuration)
          }
          currentDuration = CMTimeAdd(currentDuration, eachRange.duration)
        }
      }
    } catch {
      return (.zero, .badVideoInput)
    }
    return (currentDuration, nil)
  }
  
  func debugPrint(_ str: String) {
    if Compositor.debugging {
      print(str)
    }
  }
  
}
