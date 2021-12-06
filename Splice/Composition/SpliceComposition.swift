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
// source of truth for the assets, segments, and AV composition. Does not persist, lives in memory only (for now)
class SpliceComposition: CustomStringConvertible {
  private var fetchResult: PHFetchResult<PHAsset>?
  var assetIdentifiers: [String] = []
  var assets: [AVAsset] = []
  var splices: [Splice] = []
  var voiceSegments: [AVURLAsset] = []
  var bpm: Int?
  var includeOriginalAudio = true
  
  var assetTransformQueue = DispatchQueue(label: "june.kim.AlbumImportVC.assetRequestQueue", qos: .userInitiated)
  let group = DispatchGroup()
  static let transformDoneNotification = Notification.Name("june.kim.SpliceComposition.transformDoneNotification")

  let timeSubject = CurrentValueSubject<TimeInterval, Never>(0)
  var compositor: Compositor?

  var preVoiceoverPreviewAsset: AVURLAsset?
  var postVoiceoverPreviewAsset: AVURLAsset?
  var exportAsset: AVURLAsset? {
    return postVoiceoverPreviewAsset ?? preVoiceoverPreviewAsset
  }
  
  var totalDuration: TimeInterval {
    return assets.reduce(0.0) { partialResult, asset in
      return partialResult + asset.duration.seconds
    }
  }
  var voiceSegmentsDuration: TimeInterval {
    return voiceSegments.reduce(0.0) { partialResult, voice in
      return partialResult + voice.duration.seconds
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
    if intervals.count > 1 {
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
  
  func requestAVAssets(from fetchResult: PHFetchResult<PHAsset>, _ completion: @escaping BoolCompletion) {
    self.fetchResult = fetchResult
    var identifiersToIndex = [String: Int]()
    for i in 0..<assetIdentifiers.count {
      identifiersToIndex[assetIdentifiers[i]] = i
    }
    let fetchCount = fetchResult.count
    guard fetchCount == assetIdentifiers.count else {
      completion(false)
      return
    }
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
        completion(true)
        NotificationCenter.default.post(name: SpliceComposition.transformDoneNotification, object: nil)
      }
    }
  }
  
  func compositeForPreviewAndExport() -> AVAsset? {
    compositor = Compositor(composition: self)
    return compositor!.concatAndSplice()
  }
  
  func compositeWithVoiceover(_ completion: @escaping BoolCompletion) {
    if compositor == nil {
      compositor = Compositor(composition: self)
    }
    guard let preVoiceoverAsset = preVoiceoverPreviewAsset else { return }
    compositor!.add(voiceover: voiceSegments, to: preVoiceoverAsset) { (url, error) in
      if let url = url {
        self.postVoiceoverPreviewAsset = AVURLAsset(url: url)
      }
      completion(error == nil)
    }
  }

  func export(_ asset: AVAsset, _ completion: @escaping ErrorCompletion) {
    compositor!.export(asset) { url, err in
      if let url = url {
        self.preVoiceoverPreviewAsset = AVURLAsset(url: url)
        completion(nil)
      } else {
        completion(err)
      }
    }
  }
  
  func makeTempDirectoryName(identifier: String) -> URL {
    let tempDirectory = FileManager.default.temporaryDirectory
    let unslashed = identifier.replacingOccurrences(of: "/", with: "_")
    return tempDirectory.appendingPathComponent("\(unslashed).mp4")
  }
  
  func copy(phAsset: PHAsset, to directory: URL, _ completion: @escaping BoolCompletion) {
    PHImageManager
      .default()
      .requestAVAsset(forVideo: phAsset,
                      options: nil) { asset, mix, info in
        guard let urlAsset = asset as? AVURLAsset,
              let videoData = NSData(contentsOf: urlAsset.url) else {
                assert(false, "could not save to temp dir")
                self.group.leave()
                return
              }
        print("source URL: \(urlAsset.url)")
        print("destination URL: \(directory)")
        completion(videoData.write(to: directory, atomically: true))
      }
  }
  
  func saveAssetsToTempDirectory(from fetchResult: PHFetchResult<PHAsset>, _ completion: @escaping BoolCompletion) {
    var identifiersToIndex = [String: Int]()
    for i in 0..<assetIdentifiers.count {
      identifiersToIndex[assetIdentifiers[i]] = i
    }
    let fetchCount = assetIdentifiers.count
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    assetTransformQueue.async {
      var tempAssets: [AVAsset?] = Array(repeating: nil, count: fetchCount)
      for i in 0..<fetchCount {
        let eachVideoAsset = fetchResult.object(at: i)
        let identifier = eachVideoAsset.localIdentifier
        self.group.enter()
        let tempDir = self.makeTempDirectoryName(identifier: identifier)
        guard let pickedIndex = identifiersToIndex[identifier] else {
          // something went wrong!
          assert(false)
          return
        }
        guard !FileManager.default.fileExists(atPath: tempDir.path) else {
          // file exists, get it from file instead of exporting.
          print("\(pickedIndex): \(tempDir.lastPathComponent)")
          tempAssets[pickedIndex] = AVURLAsset(url: tempDir)
          self.group.leave()
          continue
        }
        self.copy(phAsset: eachVideoAsset, to:tempDir) { success in
          guard success else {
            self.group.leave()
            return
          }
          print("\(pickedIndex): \(tempDir.lastPathComponent)")
          tempAssets[pickedIndex] = AVURLAsset(url: tempDir)
          self.group.leave()
        }
      }
      self.group.notify(queue: .main) {
        self.assets = tempAssets.compactMap{$0}
        completion(self.assets.count == self.assetIdentifiers.count)
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
  
  func replaceSplice(at index: Int, with newSplice: Splice) {
    guard index < splices.count else { return }
    let lower = max(0, min(newSplice.lowerBound, newSplice.upperBound))
    let upper = max(0, max(newSplice.lowerBound, newSplice.upperBound))
    splices[index] = lower...upper
    merge(intervals: &splices)
  }
  
  func cutToTheBeatIfNeeded() {
    guard let bpm = bpm else { return }
    let unitTime: TimeInterval = 60.0 / Double(bpm)
    splices = splices.map({ splice in
      let duration = splice.upperBound - splice.lowerBound
      let numberOfBeats = max(1.0, (duration / unitTime).rounded())
      if splice.upperBound.rounded(.up) < totalDuration {
        let lower = splice.lowerBound
        let upper = lower + unitTime * numberOfBeats
        return lower...upper
      } else {
        let lower = splice.upperBound - unitTime * numberOfBeats
        let upper = splice.upperBound
        return lower...upper
      }
    })
    merge(intervals: &splices)
  }
  
  static func mockComposition() -> SpliceComposition {
    let comp = SpliceComposition()

    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("tempExport2a2b3ae273b5c1f9e18e17646790a01b.mp4")
//    let tempDir = comp.makeTempDirectoryName(identifier: "04106a49143d98af62ae7189c57441dd.mp4")
    if !FileManager.default.fileExists(atPath: tempDir.path) {
      assert(false, "need fresh assets in temp dir")
    }
    let localAsset = AVAsset(url: tempDir)
    comp.assets = [localAsset]
    comp.splices = [0...localAsset.duration.seconds]
    return comp
  }
  
  var description: String {
    return assetIdentifiers.description + splices.description + voiceSegments.description + (bpm?.description ?? "")
  }
}

