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
  
  var assetTransformQueue = DispatchQueue(label: "june.kim.AlbumImportVC.assetRequestQueue", qos: .background)
  let group = DispatchGroup()

  let timeSubject = CurrentValueSubject<TimeInterval, Never>(0)
  
  var totalDuration: TimeInterval {
    return assets.reduce(0.0) { partialResult, asset in
      return partialResult + asset.duration.seconds
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
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    assetTransformQueue.async {
      orderedAssets = [AVAsset?](repeating: nil, count: fetchCount)
      for i in 0..<fetchCount {
        let eachVideoAsset = fetchResult.object(at: i)
        self.group.enter()
        PHImageManager.default().requestAVAsset(forVideo: eachVideoAsset,
                                                options: options,
                                                resultHandler: { avAsset, audioMix, info in
          if let urlAsset = avAsset as? AVURLAsset,
             let index = identifiersToIndex[eachVideoAsset.localIdentifier] {
            orderedAssets[index] = urlAsset
            FileManager.default.fileExists(atPath: urlAsset.url.path)
          }
          self.group.leave()
        })
      }
      self.group.notify(queue: .main) {
        self.assets = orderedAssets.compactMap{$0}
        completion()
        self.saveAssetsToTempDirectory()
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
    var joinableSplice = splice
    var joined = false
    for i in 0..<splices.count {
      let eachOldSplice = splices[i]
      if almostOverlaps(eachOldSplice, joinableSplice) {
        let lower = min(eachOldSplice.lowerBound, joinableSplice.lowerBound)
        let upper = max(eachOldSplice.upperBound, joinableSplice.upperBound)
        joinableSplice = lower...upper
        splices.append(joinableSplice)
        splices.remove(at: i)
        joined = true
      }
    }
    if !joined {
      splices.append(splice)
    }
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

