//
//  SpliceComposition.swift
//  Splice
//
//  Created by June Kim on 10/29/21.
//

import Foundation
import AVFoundation
import Combine
import Photos

typealias Splice = ClosedRange<Double>
// source of truth for the assets, segments, and AV composition. Up to one perisstent composition per app (TODO)
class SpliceComposition {
  private var fetchResult: PHFetchResult<PHAsset>?
  var assetIdentifiers: [String] = []
  var assets: [AVAsset] = []
  var splices: [Splice] = []
  
  var assetTransformQueue = DispatchQueue(label: "june.kim.AlbumImportVC.assetRequestQueue", qos: .userInitiated)
  let group = DispatchGroup()
  static let transformDoneNotification = Notification.Name("june.kim.SpliceComposition.transformDoneNotification")

  let timeSubject = CurrentValueSubject<TimeInterval, Never>(0)
  var exporter: CompositionExporter?
  var previewAsset: AVURLAsset?
  
  var totalDuration: TimeInterval {
    return assets.reduce(0.0) { partialResult, asset in
      return partialResult + asset.duration.seconds
    }
  }
  
  var splicesDuration: TimeInterval {
    return splices.reduce(0) { partialResult, range in
      return partialResult + range.upperBound - range.lowerBound
    }
  }
  
  func cumulativeDuration(currentRange newSplice: ClosedRange<TimeInterval>) -> TimeInterval {
    var cumulativeSplices: [Splice] = Array(splices) + [newSplice]
    merge(intervals: &cumulativeSplices)
    return cumulativeSplices.reduce(0.0) { partialResult, splice in
      return partialResult + splice.upperBound - splice.lowerBound
    }
  }
  
  func merge(intervals: inout [ClosedRange<TimeInterval>]) {
    intervals.sort { left, right in
      return left.lowerBound < right.lowerBound
    }
    var i = 0
    // check for overlaps
    if intervals.count > 2 {
      var runningSplice = intervals.first!
      while i + 1 < intervals.count {
        runningSplice = intervals[i]
        let nextSplice = intervals[i+1]
        if almostOverlaps(runningSplice, nextSplice) {
          let lower = min(runningSplice.lowerBound, nextSplice.lowerBound)
          let upper = max(runningSplice.upperBound, nextSplice.upperBound)
          let bigSplice = lower...upper
          // remove the i'th splice
          intervals.remove(at: i)
          // replace with the big splice
          intervals[i] = bigSplice
        } else {
          i += 1
        }
      }
    }
  }
  
  func requestAVAssets(from fetchResult: PHFetchResult<PHAsset>, _ completion: @escaping Completion) {
    self.fetchResult = fetchResult
    var identifiersToIndex = [String: Int]()
    for i in 0..<assetIdentifiers.count {
      identifiersToIndex[assetIdentifiers[i]] = i
    }
    let fetchCount = assetIdentifiers.count
    var orderedAssets: [AVAsset?] = []
    let videoOptions = PHVideoRequestOptions()
    videoOptions.isNetworkAccessAllowed = true
    let livePhotoOptions = PHLivePhotoRequestOptions()
    livePhotoOptions.deliveryMode = .highQualityFormat
    livePhotoOptions.isNetworkAccessAllowed = true
    
    assetTransformQueue.async {
      orderedAssets = [AVAsset?](repeating: nil, count: fetchCount)
      for i in 0..<fetchCount {
        let eachPHAsset = fetchResult.object(at: i)
        self.group.enter()
        switch eachPHAsset.mediaType {
        case .video:
          PHImageManager.default().requestAVAsset(
            forVideo: eachPHAsset,
            options: videoOptions,
            resultHandler: { avAsset, audioMix, info in
              if let urlAsset = avAsset as? AVURLAsset,
                 let index = identifiersToIndex[eachPHAsset.localIdentifier] {
                orderedAssets[index] = urlAsset
              }
              self.group.leave()
            })
        case .image:
          PHImageManager.default().requestLivePhoto(for: eachPHAsset,
                                                       targetSize: PHImageManagerMaximumSize,
                                                       contentMode: .default,
                                                       options: livePhotoOptions) { livePhoto, info in
            guard let livePhoto = livePhoto else {
              print("no live photo")
              self.group.leave()
              return
            }
            var videoResource: PHAssetResource? = nil
            for eachResource in PHAssetResource.assetResources(for: livePhoto) {
              if eachResource.type == .pairedVideo {
                videoResource = eachResource
                break
              }
            }
            guard let video = videoResource else {
              print("no video for live photo")
              self.group.leave()
              return
            }
            let url = FileManager
              .default
              .temporaryDirectory
              .appendingPathComponent("\(UUID()).mov")
              .standardizedFileURL
            PHAssetResourceManager.default().writeData(for: video, toFile: url, options: nil) { error in
              guard error == nil else {
                print("error for video for live photo")
                self.group.leave()
                return
              }
              let videoAVAsset = AVURLAsset(url: url)
              guard let index = identifiersToIndex[eachPHAsset.localIdentifier] else {
                print("no index for video for live photo")
                self.group.leave()
                return
              }
              orderedAssets[index] = videoAVAsset
              self.group.leave()
            }
          }
        default:
          assert(false, "OOPS")
          self.group.leave()
        }
      }
      self.group.notify(queue: .main) {
        self.assets = orderedAssets.compactMap{$0}
        completion()
        NotificationCenter.default.post(name: SpliceComposition.transformDoneNotification, object: nil)
      }
    }
  }
  
  func exportForPreview(_ completion: @escaping BoolCompletion) {
    exporter = CompositionExporter(composition: self)
    exporter!.export { url, err in
      if let url = url {
        self.previewAsset = AVURLAsset(url: url)
        completion(true)
      } else {
        completion(false)
      }
    }
  }
  
  func makeTempDirectoryName(identifier: String) -> URL {
    let tempDirectory = FileManager.default.temporaryDirectory
    return tempDirectory.appendingPathComponent("\(UUID()).mp4")
  }
  
  func saveAssetsToTempDirectory() {
    guard let fetchResult = fetchResult else {
      return
    }

    var identifiersToIndex = [String: Int]()
    for i in 0..<assetIdentifiers.count {
      identifiersToIndex[assetIdentifiers[i]] = i
    }
    let fetchCount = assetIdentifiers.count
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    assetTransformQueue.async {
      for i in 0..<fetchCount {
        let eachVideoAsset = fetchResult.object(at: i)
        PHImageManager
          .default()
          .requestExportSession(forVideo: eachVideoAsset,
                                options: options,
                                exportPreset: AVAssetExportPresetPassthrough) { exportSession, info in
            guard let session = exportSession else { return }
            let tempDir = self.makeTempDirectoryName(identifier: self.assetIdentifiers[i])
            session.outputURL = tempDir
            session.outputFileType = AVFileType.mov
            session.shouldOptimizeForNetworkUse = true

            session.exportAsynchronously {
              switch session.status {
              case .completed:
                print("asset export completed!")
                self.assets[i] = AVURLAsset(url: tempDir)
              case .failed:
                print("export failed \(session.error?.localizedDescription ?? "error nil")")
              case .cancelled:
                print("export cancelled \(session.error?.localizedDescription ?? "error nil")")
              default:
                print("fail..")
              }
            }
          }
      }
      self.group.notify(queue: .main) {
      }
    }
  }
  
  func append(_ splice: Splice) {
    let lower = max(0, min(splice.lowerBound, splice.upperBound))
    let upper = max(0, max(splice.lowerBound, splice.upperBound))

    splices.append(lower...upper)
    merge(intervals: &splices)
  }
  
  func almostOverlaps(_ left: Splice, _ right: Splice) -> Bool {
    return left.overlaps(right) ||
    abs(left.upperBound - right.lowerBound) < 0.05 ||
    abs(right.upperBound - left.lowerBound) < 0.05
  }
  
  func removeSplice(at index: Int) {
    splices.remove(at: index)
  }
}

