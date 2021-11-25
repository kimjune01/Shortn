//
//  ThumbnailCollectionView.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import UIKit
import AVFoundation

protocol ThumbnailsViewControllerDelegate: AnyObject {
  func thumbnailsVCWillRefreshThumbnails(contentSize: CGSize)
  func thumbnailsVCDidRefreshAThumbnail()
  func thumbnailsVCDidScroll(_ thumbnailsVC: ThumbnailsViewController, to time: TimeInterval)
  func thumbnailsVCWillBeginDragging(_ thumbnailsVC: ThumbnailsViewController)
  func thumbnailsVCDidEndDragging(_ thumbnailsVC: ThumbnailsViewController)
}

// A horizontal thumbnail collection view with un-interactable cells.
// responsible for generating the thumbnails and reporting its scrollable position.
class ThumbnailsViewController: UIViewController {
  static let defaultHeight: CGFloat = 60
  weak var delegate: ThumbnailsViewControllerDelegate?
  var scrollView: UIScrollView!
  let imageViewsContainer = UIView()
  weak var scrollDelegate: UIScrollViewDelegate?
  unowned var composition: SpliceComposition
  var clipsThumbnails: [[Thumbnail]] = []
  var defaultThumbnailSize: CGSize {
    return CGSize(width: ThumbnailCell.defaultWidth,
                  height: ThumbnailsViewController.defaultHeight)
  }
  var estimatedWidth: CGFloat {
    let estimatedWindowWidth = UIScreen.main.bounds.width
    return estimatedWindowWidth - UIView.defaultEdgeMargin * 2
  }
  var totalScrollableWidth: CGFloat = 0
  var contentWidth: CGFloat {
    return scrollView.contentSize.width
  }
  let thumbnailQueue = DispatchQueue(label: "kim.june.thumbnailQueue", qos: .userInitiated)
  var generators = [AVAssetImageGenerator]()
  // manually prevent outdated work items to continue. Should really be using Operations instead.
  var currentWorkUUID: UUID?
  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addScrollView()
    placeholdImageViews()
    generateThumbnails()
  }
  
  func addScrollView() {
    scrollView = UIScrollView()
    scrollView.alwaysBounceVertical = false
    scrollView.alwaysBounceHorizontal = false
    scrollView.bounces = true
    scrollView.backgroundColor = .black.withAlphaComponent(0.3)
    scrollView.delegate = self
    scrollView.decelerationRate = .fast
    scrollView.showsHorizontalScrollIndicator = false
    view.addSubview(scrollView)
    scrollView.fillWidthOfParent()
    scrollView.pinBottomToParent()
    scrollView.centerXInParent()
    scrollView.set(height: ThumbnailsViewController.defaultHeight)
    scrollView.roundCorner(radius: 5, cornerCurve: .continuous)
    scrollView.contentInset = UIEdgeInsets(top: 0, left: estimatedWidth / 2,
                                           bottom: 0, right: estimatedWidth / 2)
    
    scrollView.addSubview(imageViewsContainer)
  }
  
  func placeholdImageViews() {
    for case let eachImageView as UIImageView in imageViewsContainer.subviews {
      eachImageView.removeFromSuperview()
    }
    var currentX: CGFloat = 0
    var tagCounter = 0
    for asset in composition.assets {
      let sampleInterval = TimelineScrollConfig.sampleInterval(thumbnailsPerSpan: thumbnailsPerSpan())
      let portions = asset.makePortionsArray(nSeconds: sampleInterval)
      for portion in portions {
        let width = ThumbnailCell.defaultWidth * portion
        let imageView = UIImageView(frame: CGRect(x: currentX, y: 0,
                                                  width: width,
                                                  height: ThumbnailsViewController.defaultHeight))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = nil
        imageView.tag = tagCounter
        imageView.isHidden = true
        imageViewsContainer.addSubview(imageView)
        currentX += width
        tagCounter += 1
      }
    }
    totalScrollableWidth = currentX
    scrollView.contentSize = CGSize(width: currentX, height: ThumbnailsViewController.defaultHeight)
    imageViewsContainer.frame = CGRect(origin: .zero, size: scrollView.contentSize)
    scrollView.contentOffset = CGPoint(x: -scrollView.contentInset.left, y: 0)
    scrollView.backgroundColor = .black.withAlphaComponent(0.4)
    // TODO: clip bounds should allow for glowing effect that spills over
    scrollView.alpha = 0
    UIView.animate(withDuration: 0.3) {
      self.scrollView.alpha = 1
    }
  }
  
  func pixelPosition(in scrollView: UIScrollView) -> CGFloat {
    return scrollView.contentOffset.x + scrollView.contentInset.left
  }
  
  func pixelWidth(for asset: AVAsset) -> CGFloat {
    return asset.duration.seconds / TimelineScrollConfig.secondsPerSpan * estimatedWidth
  }
  
  func numberOfCells(for asset: AVAsset) -> Int {
    let cellsCount = pixelWidth(for: asset) / ThumbnailCell.defaultWidth
    return Int(cellsCount.rounded(.up))
  }
  
  func thumbnailsPerSpan() -> CGFloat {
    return estimatedWidth / ThumbnailCell.defaultWidth
  }
  
  func indexFrom(clipIndex: Int, thumbIndex: Int) -> Int {
    var counter = 0
    for i in 0..<clipIndex {
      counter += numberOfCells(for: composition.assets[i])
    }
    return counter + thumbIndex
  }
  
  func fill(thumbnail: Thumbnail, at index: Int) {
    for case let eachImageView as UIImageView in imageViewsContainer.subviews {
      if eachImageView.tag == index {
        eachImageView.image = thumbnail.image
        eachImageView.transform = CGAffineTransform(scaleX: 0.8, y: 1).translatedBy(x: -4, y: 0)
        UIView.animate(withDuration: 0.3) {
          eachImageView.isHidden = false
          eachImageView.transform = .identity
        }
      }
    }
  }
  
  // There's a race condition in here somewhere...
  func generateThumbnails() {
    let workUUID = UUID()
    currentWorkUUID = workUUID
    generators = []
    delegate?.thumbnailsVCWillRefreshThumbnails(contentSize: scrollView.contentSize)
    func makeThumbnails(for asset: AVAsset, _ progress: @escaping ThumbnailProgress) {
      let sampleInterval = TimelineScrollConfig.sampleInterval(thumbnailsPerSpan: thumbnailsPerSpan())
      thumbnailQueue.async { [weak self] in
        guard let self = self else { return }
        guard self.currentWorkUUID == workUUID else { return }
        let generator = asset.makeThumbnails(every:sampleInterval, size: self.defaultThumbnailSize, progress)
        self.generators.append(generator)
      }
    }
    clipsThumbnails = Array<[Thumbnail]>(repeating: [], count: composition.assets.count)
    for (clipIndex, asset) in composition.assets.enumerated() {
      makeThumbnails(for: asset){ [weak self] thumb, thumbIndex in
        guard let self = self else { return }
        guard self.currentWorkUUID == workUUID else { return }
        guard let thumb = thumb else { return }
        self.clipsThumbnails[clipIndex].append(thumb)
        DispatchQueue.main.async {
          guard self.currentWorkUUID == workUUID else { return }
          self.fill(thumbnail: thumb, at: self.indexFrom(clipIndex: clipIndex, thumbIndex: thumbIndex))
          self.delegate?.thumbnailsVCDidRefreshAThumbnail()
        }
      }
    }
  }
  
  func renderFreshAssets() {
    placeholdImageViews()
    generateThumbnails()
  }
  
  func estimatedContentWidth() -> CGFloat {
    // seconds / (seconds / span) * (pixels/span)
    return CGFloat(composition.totalDuration) / TimelineScrollConfig.secondsPerSpan * estimatedWidth
  }
  
  func numberOfCells(for section: Int) -> Int {
    let asset = composition.assets[section]
    let sectionWidth = CGFloat(asset.duration.seconds / TimelineScrollConfig.secondsPerSpan * estimatedWidth)
    let cellsPerSection = sectionWidth / ThumbnailCell.defaultWidth
    return Int(cellsPerSection.rounded(.up))
  }
    
  func currentTimePosition(_ scrollView: UIScrollView) -> TimeInterval {
    let boundedTime = min( max(0, pixelPosition(in: scrollView)), scrollView.contentSize.width)
    return boundedTime / scrollView.contentSize.width * composition.totalDuration
  }
  
  func scrollTime(to time: TimeInterval, animated: Bool = false, showPopover: Bool = false) {
    let offsetToScrollTo = time / composition.totalDuration * scrollView.contentSize.width -  scrollView.contentInset.left
    // only scroll if different than before
    if abs(scrollView.contentOffset.x - offsetToScrollTo.rounded()) >= 1 {
      scrollView.setContentOffset(CGPoint(x: offsetToScrollTo, y: 0), animated: animated)
      if animated {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          self.delegate?.thumbnailsVCDidEndDragging(self)
        }
      }
    }
  }
}

extension ThumbnailsViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    delegate?.thumbnailsVCDidScroll(self, to: currentTimePosition(scrollView))
  }
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    delegate?.thumbnailsVCWillBeginDragging(self)
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    delegate?.thumbnailsVCDidEndDragging(self)
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      delegate?.thumbnailsVCDidEndDragging(self)
    } else {
      // scrollViewDidEndDecelerating will be called.
    }
  }
}

class ThumbnailCell: UICollectionViewCell {
  static let defaultWidth: CGFloat = 30
  private let imageView = UIImageView()
  var image: UIImage? {
    didSet {
      imageView.image = image
    }
  }
  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(imageView)
    imageView.fillParent()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    backgroundColor = .systemYellow
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
